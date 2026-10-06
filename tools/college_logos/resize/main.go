// Pre-resizes logos exactly as niblet render.Image does (image.Decode +
// nfnt/resize NearestNeighbor) and stores them as PNGs whose decoded pixels
// are verified equal to the in-memory resized frame.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	_ "image/jpeg"
	"image/png"
	"os"

	"github.com/gabriel-vasile/mimetype"
	"github.com/nfnt/resize"
)

type job struct {
	Src  string `json:"src"`
	Size int    `json:"size"`
	Out  string `json:"out"`
}

type result struct {
	job
	OK      bool   `json:"ok"`
	Reason  string `json:"reason,omitempty"`
	Bytes   int    `json:"bytes"`
	InType  string `json:"in_type"`
	Type    string `json:"type"`
	OutType string `json:"out_type"`
}

func encode(img image.Image) ([]byte, image.Image, error) {
	var buf bytes.Buffer
	enc := png.Encoder{CompressionLevel: png.BestCompression}
	if err := enc.Encode(&buf, img); err != nil {
		return nil, nil, err
	}
	back, _, err := image.Decode(bytes.NewReader(buf.Bytes()))
	return buf.Bytes(), back, err
}

func samePixels(a, b image.Image) bool {
	ab, bb := a.Bounds(), b.Bounds()
	if ab.Dx() != bb.Dx() || ab.Dy() != bb.Dy() {
		return false
	}
	for y := 0; y < ab.Dy(); y++ {
		for x := 0; x < ab.Dx(); x++ {
			r1, g1, b1, a1 := a.At(ab.Min.X+x, ab.Min.Y+y).RGBA()
			r2, g2, b2, a2 := b.At(bb.Min.X+x, bb.Min.Y+y).RGBA()
			if r1 != r2 || g1 != g2 || b1 != b2 || a1 != a2 {
				return false
			}
		}
	}
	return true
}

// unpremultiply returns n with n*a/0xffff == c; one exists for every c <= a.
func unpremultiply(c, a uint32) uint16 {
	if a == 0 {
		return 0
	}
	n := c * 0xffff / a
	for n > 0 && n*a/0xffff > c {
		n--
	}
	for n < 0xffff && n*a/0xffff < c {
		n++
	}
	return uint16(n)
}

func exactNRGBA64(img image.Image) *image.NRGBA64 {
	b := img.Bounds()
	out := image.NewNRGBA64(image.Rect(0, 0, b.Dx(), b.Dy()))
	for y := 0; y < b.Dy(); y++ {
		for x := 0; x < b.Dx(); x++ {
			r, g, bl, a := img.At(b.Min.X+x, b.Min.Y+y).RGBA()
			out.SetNRGBA64(x, y, color.NRGBA64{unpremultiply(r, a), unpremultiply(g, a), unpremultiply(bl, a), uint16(a)})
		}
	}
	return out
}

func run(j job) result {
	r := result{job: j}
	data, err := os.ReadFile(j.Src)
	if err != nil {
		r.Reason = err.Error()
		return r
	}
	mime := mimetype.Detect(data)
	if mime.Is("image/webp") || mime.Is("image/gif") || mime.Is("image/svg+xml") {
		r.Reason = "unsupported " + mime.String()
		return r
	}
	src, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		r.Reason = err.Error()
		return r
	}
	r.InType = fmt.Sprintf("%T", src)
	img := resize.Resize(uint(j.Size), uint(j.Size), src, resize.NearestNeighbor)
	r.Type = fmt.Sprintf("%T", img)
	if img.Bounds().Dx() != j.Size || img.Bounds().Dy() != j.Size {
		r.Reason = "size mismatch"
		return r
	}
	// 8-bit PNGs round-trip NRGBA/RGBA results exactly. Premultiplied 16-bit
	// results (from paletted or gray sources) are stored as 16-bit NRGBA with
	// channel values chosen so the decoded premultiplied colour is identical.
	data, back, err := encode(img)
	if err == nil && !samePixels(img, back) {
		data, back, err = encode(exactNRGBA64(img))
	}
	if err != nil {
		r.Reason = err.Error()
		return r
	}
	if !samePixels(img, back) {
		r.Reason = "pixel mismatch"
		return r
	}
	r.OutType = fmt.Sprintf("%T", back)
	buf := bytes.NewBuffer(data)
	if err := os.WriteFile(j.Out, buf.Bytes(), 0o644); err != nil {
		r.Reason = err.Error()
		return r
	}
	r.OK, r.Bytes = true, buf.Len()
	return r
}

func main() {
	var jobs []job
	if err := json.NewDecoder(os.Stdin).Decode(&jobs); err != nil {
		panic(err)
	}
	out := make([]result, 0, len(jobs))
	for _, j := range jobs {
		out = append(out, run(j))
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", " ")
	_ = enc.Encode(out)
}
