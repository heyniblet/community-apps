// Command lunchbox_logos bundles pre-resized team logos into the LunchBox8484
// professional-league score and standings apps.
//
// Usage, from the repository root:
//
//	cd tools/lunchbox_logos && go run . [-app nflscores] [-check]
//
// For each app in apps.json it reads the league feed over the configured dates,
// derives every logo URL the app would request for the teams it saw (applying
// the app's own URL rewriting and ALT_LOGO overrides, parsed from its source),
// downloads those URLs, and writes images/logos/*.png plus logos.star. The module
// sits in the app root because the runtime's compiled-program cache cannot yet
// store modules from subdirectories.
//
// Pixel identity: render.Image decodes the source with image.Decode and resizes
// it with github.com/nfnt/resize NearestNeighbor; when the requested size equals
// the image size the resize returns its input unchanged. Each bundled file is
// therefore the runtime's own resize result, encoded so that decoding yields the
// same Go image type and the same pixel bytes. The generator decodes every file
// it writes and compares it with the in-memory resize; if they are not identical
// it bundles the original bytes instead, which the runtime resizes as before.
//
// -check regenerates into memory and fails if the committed files differ.
package main

import (
	"bufio"
	"bytes"
	"compress/zlib"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"hash/crc32"
	"image"
	_ "image/jpeg"
	"image/png"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/nfnt/resize"
)

const transparentURL = "https://i.ibb.co/5LMp8T1/transparent.png"

type appConfig struct {
	Source string `json:"source"`
	// "scoreboard" or "standings".
	Feed   string `json:"feed"`
	League string `json:"league"`
	// URL rewriting copied from the app's get_logoType; see candidates().
	Rule string `json:"rule"`
	// Inclusive YYYYMMDD ranges whose daily scoreboards list the league's teams.
	Dates [][2]string `json:"dates"`
	// Square sizes every team logo is drawn at, before scaling.
	LayoutSizes []int `json:"layout_sizes"`
	// Whether compact layouts draw get_logoSize(team) (MAGNIFY_LOGO, default 16).
	Compact bool  `json:"compact"`
	Scales  []int `json:"scales"`
	// Team logos the app already ships, keyed by team.
	Local map[string]string `json:"local"`
}

type logoUse struct {
	teams map[string]bool
	sizes map[int]bool
}

type bundled struct {
	key   string // URL or local path the app looks up
	name  string // file stem
	teams []string
	src   []byte
	files map[int]string // size -> path relative to app dir
}

var client = &http.Client{Timeout: 30 * time.Second}
var downloads = map[string]*download{}

type download struct {
	status int
	body   []byte
	err    error
}

func fetch(url string) *download {
	if d, ok := downloads[url]; ok {
		return d
	}
	d := &download{}
	for attempt := 0; attempt < 4; attempt++ {
		res, err := client.Get(url)
		if err != nil {
			d.err = err
			time.Sleep(time.Second)
			continue
		}
		d.body, d.err = io.ReadAll(res.Body)
		res.Body.Close()
		d.status = res.StatusCode
		if d.err == nil && d.status < 500 && d.status != http.StatusTooManyRequests {
			break
		}
		time.Sleep(time.Duration(attempt+1) * 2 * time.Second)
	}
	downloads[url] = d
	return d
}

func main() {
	only := flag.String("app", "", "generate only this app directory")
	check := flag.Bool("check", false, "verify committed files instead of writing them")
	flag.Parse()

	root, err := filepath.Abs("../..")
	must(err)
	raw, err := os.ReadFile("apps.json")
	must(err)
	var apps map[string]appConfig
	must(json.Unmarshal(raw, &apps))
	names := make([]string, 0, len(apps))
	for name := range apps {
		names = append(names, name)
	}
	sort.Strings(names)
	failed := false
	for _, name := range names {
		if *only != "" && name != *only {
			continue
		}
		if err := generate(root, name, apps[name], *check); err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", name, err)
			failed = true
		}
	}
	if failed {
		os.Exit(1)
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

// sourceTable reads a team-keyed table (JSON in a triple-quoted string, or a
// Starlark dict literal) assigned to name at the top level of the app source.
func sourceTable(source, name string) (map[string]any, error) {
	re := regexp.MustCompile(`(?ms)^` + name + ` = (?:"""(.*?)"""|(\{.*?^\}))`)
	m := re.FindStringSubmatch(source)
	if m == nil {
		return map[string]any{}, nil
	}
	body := m[1] + m[2]
	body = regexp.MustCompile(`,(\s*)\}`).ReplaceAllString(body, "$1}")
	out := map[string]any{}
	if err := json.Unmarshal([]byte(body), &out); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", name, err)
	}
	return out, nil
}

func combiner(url string) string {
	return strings.ReplaceAll(url, "https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=")
}

// candidates mirrors each app's get_logoType: the URLs it requests in order,
// and whether a non-200 response moves on to the next one.
func candidates(rule, alt, logo string) ([]string, bool) {
	switch rule {
	case "dark_scoreboard_fallback": // NFL Scores
		if alt != "" {
			return []string{alt, logo}, true
		}
		return []string{strings.ReplaceAll(logo, "500/scoreboard", "500-dark/scoreboard"), logo}, true
	case "combiner_fallback": // NHL, MLB, NBA Scores
		if alt != "" {
			return []string{alt, logo}, true
		}
		return []string{combiner(strings.ReplaceAll(logo, "500/scoreboard", "500-dark/scoreboard")) + "&h=50&w=50", logo}, true
	case "wnba_combiner_fallback": // WNBA Scores
		if alt != "" {
			return []string{alt, logo}, true
		}
		dark := strings.ReplaceAll(strings.ReplaceAll(logo, "500/scoreboard", "500"), "/500/", "/500-dark/")
		return []string{combiner(dark) + "&h=50&w=50", logo}, true
	case "combiner": // CFL, MLS, UFL, WBC Scores; standings
		if alt != "" {
			return []string{alt}, false
		}
		return []string{combiner(strings.ReplaceAll(logo, "500/scoreboard", "500-dark/scoreboard")) + "&h=50&w=50"}, false
	case "xfl_combiner": // XFL Scores
		if alt != "" {
			return []string{alt}, false
		}
		if logo == "" {
			return []string{transparentURL}, false
		}
		return []string{combiner(strings.ReplaceAll(logo, "500/scoreboard", "500-dark/scoreboard")) + "&h=50&w=50"}, false
	case "dark_500": // Men's College Hockey Scores
		if alt != "" {
			return []string{alt}, false
		}
		return []string{strings.ReplaceAll(logo, "500/", "500-dark/")}, false
	}
	panic("unknown rule " + rule)
}

// feedLogos returns team abbreviation -> logo URLs the app reads from its feed.
func feedLogos(cfg appConfig) (map[string]map[string]bool, error) {
	out := map[string]map[string]bool{}
	add := func(team, logo string) {
		if out[team] == nil {
			out[team] = map[string]bool{}
		}
		out[team][logo] = true
	}
	var urls []string
	if cfg.Feed == "standings" {
		urls = append(urls, "https://site.api.espn.com/apis/v2/sports/"+cfg.League+"/standings")
	} else {
		base := "https://site.api.espn.com/apis/site/v2/sports/" + cfg.League + "/scoreboard?limit=300"
		urls = append(urls, base)
		for _, span := range cfg.Dates {
			start, err := time.Parse("20060102", span[0])
			if err != nil {
				return nil, err
			}
			end, err := time.Parse("20060102", span[1])
			if err != nil {
				return nil, err
			}
			for day := start; !day.After(end); day = day.AddDate(0, 0, 1) {
				urls = append(urls, base+"&dates="+day.Format("20060102"))
			}
		}
	}
	for _, url := range urls {
		d := fetch(url)
		if d.err != nil || d.status != 200 {
			return nil, fmt.Errorf("feed %s: status %d %v", url, d.status, d.err)
		}
		var doc any
		if err := json.Unmarshal(d.body, &doc); err != nil {
			return nil, fmt.Errorf("feed %s: %w", url, err)
		}
		if cfg.Feed == "standings" {
			walkStandings(doc, add)
			continue
		}
		events, _ := doc.(map[string]any)["events"].([]any)
		for _, event := range events {
			comps, _ := event.(map[string]any)["competitions"].([]any)
			if len(comps) == 0 {
				continue
			}
			competitors, _ := comps[0].(map[string]any)["competitors"].([]any)
			for _, c := range competitors {
				team, _ := c.(map[string]any)["team"].(map[string]any)
				abbr, _ := team["abbreviation"].(string)
				logo, present := team["logo"].(string)
				switch {
				case !present:
					// Apps substitute the transparent placeholder for a missing logo.
					add(abbr, transparentURL)
				case logo == "" && cfg.Rule == "dark_500":
					add(abbr, transparentURL)
				case logo == "" && cfg.Rule == "xfl_combiner":
					add(abbr, "")
				case logo != "":
					add(abbr, logo)
				}
			}
		}
	}
	return out, nil
}

// walkStandings finds standings entries; the apps draw team.logos[1].href.
func walkStandings(node any, add func(string, string)) {
	switch v := node.(type) {
	case map[string]any:
		if entries, ok := v["entries"].([]any); ok {
			for _, entry := range entries {
				team, _ := entry.(map[string]any)["team"].(map[string]any)
				abbr, _ := team["abbreviation"].(string)
				logos, _ := team["logos"].([]any)
				if len(logos) > 1 {
					if href, ok := logos[1].(map[string]any)["href"].(string); ok {
						add(abbr, href)
					}
				}
			}
		}
		for _, child := range v {
			walkStandings(child, add)
		}
	case []any:
		for _, child := range v {
			walkStandings(child, add)
		}
	}
}

func teamSizes(cfg appConfig, magnify map[string]any, team string) []int {
	var sizes []int
	for _, scale := range cfg.Scales {
		for _, size := range cfg.LayoutSizes {
			sizes = append(sizes, size*scale)
		}
		if cfg.Compact {
			size := 16
			if value, ok := magnify[team].(float64); ok {
				size = int(value)
			}
			sizes = append(sizes, size*scale)
		}
	}
	return sizes
}

func generate(root, name string, cfg appConfig, check bool) error {
	dir := filepath.Join(root, "apps", name)
	sourceBytes, err := os.ReadFile(filepath.Join(dir, cfg.Source))
	if err != nil {
		return err
	}
	source := string(sourceBytes)
	alt, err := sourceTable(source, "ALT_LOGO")
	if err != nil {
		return err
	}
	magnify, err := sourceTable(source, "MAGNIFY_LOGO")
	if err != nil {
		return err
	}
	teams, err := feedLogos(cfg)
	if err != nil {
		return err
	}
	for team := range alt {
		if teams[team] == nil {
			teams[team] = map[string]bool{transparentURL: true}
		}
	}

	uses := map[string]*logoUse{}
	use := func(key, team string, sizes []int) {
		u := uses[key]
		if u == nil {
			u = &logoUse{teams: map[string]bool{}, sizes: map[int]bool{}}
			uses[key] = u
		}
		u.teams[team] = true
		for _, size := range sizes {
			u.sizes[size] = true
		}
	}
	// A team without a logo gets the transparent placeholder (or, for XFL, an
	// empty logo); "" stands for any team and is drawn at every size.
	all := map[int]bool{}
	for team := range teams {
		for _, size := range teamSizes(cfg, magnify, team) {
			all[size] = true
		}
	}
	if cfg.Feed == "scoreboard" {
		teams[""] = map[string]bool{transparentURL: true}
		if cfg.Rule == "xfl_combiner" {
			teams[""][""] = true
		}
	}
	var unbundled []string
	teamNames := sortedKeys(teams)
	for _, team := range teamNames {
		sizes := teamSizes(cfg, magnify, team)
		if team == "" {
			sizes = sortedKeys(all)
		}
		if local, ok := cfg.Local[team]; ok {
			use(local, team, sizes)
			continue
		}
		altURL, _ := alt[team].(string)
		for _, logo := range sortedKeys(teams[team]) {
			urls, fallback := candidates(cfg.Rule, altURL, logo)
			found := false
			for _, url := range urls {
				d := fetch(url)
				if d.err == nil && d.status == 200 {
					if _, _, err := image.DecodeConfig(bytes.NewReader(d.body)); err == nil {
						use(url, team, sizes)
						found = true
					}
					break
				}
				if !fallback {
					break
				}
			}
			if !found {
				unbundled = append(unbundled, team+" "+logo)
			}
		}
	}
	// Apps whose candidates all fail fall back to the placeholder itself.
	if cfg.Feed == "scoreboard" && strings.HasSuffix(cfg.Rule, "_fallback") {
		use(transparentURL, "", sortedKeys(all))
	}

	var logos []*bundled
	for _, key := range sortedKeys(uses) {
		u := uses[key]
		var src []byte
		if strings.HasPrefix(key, "https://") {
			src = fetch(key).body
		} else if src, err = os.ReadFile(filepath.Join(dir, key)); err != nil {
			return err
		}
		var teams []string
		for _, team := range sortedKeys(u.teams) {
			if team != "" {
				teams = append(teams, team)
			}
		}
		stem := strings.ToLower(strings.Join(teams, "-"))
		stem = regexp.MustCompile(`[^a-z0-9-]+`).ReplaceAllString(stem, "")
		if stem == "" || len(teams) > 3 {
			stem = "shared"
		}
		digest := sha256.Sum256([]byte(key))
		logos = append(logos, &bundled{key: key, name: stem + "-" + hex.EncodeToString(digest[:4]), teams: teams, src: src, files: map[int]string{}})
		_ = u
	}

	files := map[string][]byte{}
	exact, original := 0, 0
	for _, logo := range logos {
		img, format, err := image.Decode(bytes.NewReader(logo.src))
		if err != nil {
			return fmt.Errorf("%s: %w", logo.key, err)
		}
		for _, size := range sortedKeys(uses[logo.key].sizes) {
			encoded, ok := resized(img, format, size)
			if ok {
				path := fmt.Sprintf("images/logos/%s-%d.png", logo.name, size)
				files[path] = encoded
				logo.files[size] = path
				exact++
				continue
			}
			ext := ".png"
			if format == "jpeg" {
				ext = ".jpg"
			}
			path := "images/logos/" + logo.name + "-source" + ext
			files[path] = logo.src
			logo.files[size] = path
			original++
		}
	}
	files["logos.star"] = []byte(starlark(name, logos))
	files["images/logos/README.md"] = []byte(fmt.Sprintf(provenance, name))

	total := 0
	for _, body := range files {
		total += len(body)
	}
	fmt.Printf("%s: %d logo URLs, %d pre-resized files, %d sizes served from original bytes, %d bytes\n", name, len(logos), exact, original, total)
	for _, missing := range unbundled {
		fmt.Printf("%s: not bundled (network fallback): %s\n", name, missing)
	}
	return writeOrCheck(dir, files, check)
}

// resized returns the runtime's resize of img encoded as PNG, if decoding the
// PNG gives back exactly the same Go image type and pixel bytes.
func resized(img image.Image, format string, size int) ([]byte, bool) {
	if format != "png" && format != "jpeg" {
		return nil, false
	}
	want := resize.Resize(uint(size), uint(size), img, resize.NearestNeighbor)
	var candidates [][]byte
	var buf bytes.Buffer
	if err := (&png.Encoder{CompressionLevel: png.BestCompression}).Encode(&buf, want); err == nil {
		candidates = append(candidates, buf.Bytes())
	}
	if nrgba, ok := want.(*image.NRGBA); ok {
		// The standard encoder writes opaque NRGBA as RGB, which decodes as RGBA.
		candidates = append(candidates, encodeNRGBA(nrgba))
	}
	for _, encoded := range candidates {
		got, _, err := image.Decode(bytes.NewReader(encoded))
		if err != nil {
			continue
		}
		// render.Image resizes again; at the same size this returns got itself.
		got = resize.Resize(uint(size), uint(size), got, resize.NearestNeighbor)
		if identical(want, got) {
			return encoded, true
		}
	}
	return nil, false
}

func identical(a, b image.Image) bool {
	if fmt.Sprintf("%T", a) != fmt.Sprintf("%T", b) || a.Bounds() != b.Bounds() {
		return false
	}
	switch x := a.(type) {
	case *image.NRGBA:
		y := b.(*image.NRGBA)
		return x.Stride == y.Stride && bytes.Equal(x.Pix, y.Pix)
	case *image.RGBA:
		y := b.(*image.RGBA)
		return x.Stride == y.Stride && bytes.Equal(x.Pix, y.Pix)
	case *image.Gray:
		y := b.(*image.Gray)
		return x.Stride == y.Stride && bytes.Equal(x.Pix, y.Pix)
	}
	return false
}

// encodeNRGBA writes an 8-bit RGBA (color type 6) PNG, which Go decodes as NRGBA.
func encodeNRGBA(img *image.NRGBA) []byte {
	w, h := img.Bounds().Dx(), img.Bounds().Dy()
	var raw bytes.Buffer
	prev := make([]byte, w*4)
	for y := 0; y < h; y++ {
		row := img.Pix[y*img.Stride : y*img.Stride+w*4]
		best, bestScore := []byte(nil), -1
		for filter := byte(0); filter < 5; filter++ {
			line := filterRow(filter, row, prev)
			score := 0
			for _, value := range line[1:] {
				score += int(int8(value)) * sign(int8(value))
			}
			if bestScore < 0 || score < bestScore {
				best, bestScore = line, score
			}
		}
		raw.Write(best)
		prev = row
	}
	var compressed bytes.Buffer
	zw, _ := zlib.NewWriterLevel(&compressed, zlib.BestCompression)
	zw.Write(raw.Bytes())
	zw.Close()
	var out bytes.Buffer
	out.WriteString("\x89PNG\r\n\x1a\n")
	header := make([]byte, 13)
	binary.BigEndian.PutUint32(header[0:], uint32(w))
	binary.BigEndian.PutUint32(header[4:], uint32(h))
	header[8], header[9] = 8, 6
	chunk(&out, "IHDR", header)
	chunk(&out, "IDAT", compressed.Bytes())
	chunk(&out, "IEND", nil)
	return out.Bytes()
}

func sign(v int8) int {
	if v < 0 {
		return -1
	}
	return 1
}

func filterRow(filter byte, row, prev []byte) []byte {
	out := make([]byte, len(row)+1)
	out[0] = filter
	for i := range row {
		var a, b, c byte
		if i >= 4 {
			a, c = row[i-4], prev[i-4]
		}
		b = prev[i]
		var p byte
		switch filter {
		case 1:
			p = a
		case 2:
			p = b
		case 3:
			p = byte((int(a) + int(b)) / 2)
		case 4:
			p = paeth(a, b, c)
		}
		out[i+1] = row[i] - p
	}
	return out
}

func paeth(a, b, c byte) byte {
	p := int(a) + int(b) - int(c)
	pa, pb, pc := abs(p-int(a)), abs(p-int(b)), abs(p-int(c))
	if pa <= pb && pa <= pc {
		return a
	}
	if pb <= pc {
		return b
	}
	return c
}

func abs(v int) int {
	if v < 0 {
		return -v
	}
	return v
}

func chunk(w *bytes.Buffer, kind string, data []byte) {
	binary.Write(w, binary.BigEndian, uint32(len(data)))
	crc := crc32.NewIEEE()
	crc.Write([]byte(kind))
	crc.Write(data)
	w.WriteString(kind)
	w.Write(data)
	binary.Write(w, binary.BigEndian, crc.Sum32())
}

const provenance = `# Bundled team logos

Generated by ` + "`tools/lunchbox_logos`" + ` (` + "`cd tools/lunchbox_logos && go run . -app %s`" + `); do not edit.

Each file is a team logo this app already displayed, fetched from the URL listed
for it in ` + "`../../logos.star`" + ` (with the source's SHA-256) and resized by the same
nearest-neighbour resize the Niblet runtime applies when drawing it. Bundling
removes the per-render download and decode; the artwork is not changed. Files
named ` + "`*-source.*`" + ` are original bytes, kept where a pre-resized copy could not
reproduce the runtime's pixels exactly.

Team names and logos remain the property of their respective owners.
`

func starlark(app string, logos []*bundled) string {
	var b strings.Builder
	w := bufio.NewWriter(&b)
	fmt.Fprintf(w, `"""
Bundled team logos for %s. Generated by tools/lunchbox_logos; do not edit.

BUNDLED_LOGOS maps each URL (or bundled path) the app would read to files
already resized by the runtime's nearest-neighbour resize, keyed by drawn size.
Comments record each source's SHA-256. URLs and sizes not listed are fetched
from the network as before.
"""

`, app)
	type load struct{ path, symbol string }
	var loads []load
	symbols := map[string]string{}
	for _, logo := range logos {
		for _, size := range sortedKeys(logo.files) {
			path := logo.files[size]
			if _, ok := symbols[path]; ok {
				continue
			}
			stem := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
			symbol := "LOGO_" + strings.ToUpper(strings.ReplaceAll(stem, "-", "_"))
			symbols[path] = symbol
			loads = append(loads, load{path, symbol})
		}
	}
	sort.Slice(loads, func(i, j int) bool { return loads[i].path < loads[j].path })
	for _, l := range loads {
		fmt.Fprintf(w, "load(%q, %s = \"file\")\n", l.path, l.symbol)
	}
	fmt.Fprintf(w, "\nBUNDLED_LOGOS = {\n")
	for _, logo := range logos {
		digest := sha256.Sum256(logo.src)
		label := strings.Join(logo.teams, ", ")
		if label == "" {
			label = "placeholder"
		}
		fmt.Fprintf(w, "    # %s; source sha256 %s\n", label, hex.EncodeToString(digest[:]))
		fmt.Fprintf(w, "    %s: {\n", strconv.Quote(logo.key))
		for _, size := range sortedKeys(logo.files) {
			fmt.Fprintf(w, "        %d: %s,\n", size, symbols[logo.files[size]])
		}
		fmt.Fprintf(w, "    },\n")
	}
	fmt.Fprintf(w, "}\n")
	w.Flush()
	return b.String()
}

func writeOrCheck(dir string, files map[string][]byte, check bool) error {
	existing := map[string]bool{}
	entries, _ := os.ReadDir(filepath.Join(dir, "images/logos"))
	for _, entry := range entries {
		existing["images/logos/"+entry.Name()] = true
	}
	if check {
		var problems []string
		for path, body := range files {
			current, err := os.ReadFile(filepath.Join(dir, path))
			if err != nil || !bytes.Equal(current, body) {
				problems = append(problems, "differs: "+path)
			}
			delete(existing, path)
		}
		for path := range existing {
			problems = append(problems, "stale: "+path)
		}
		sort.Strings(problems)
		if len(problems) > 0 {
			return errors.New(strings.Join(problems, "\n"))
		}
		return nil
	}
	for path := range existing {
		if _, ok := files[path]; !ok {
			if err := os.Remove(filepath.Join(dir, path)); err != nil {
				return err
			}
		}
	}
	for path, body := range files {
		full := filepath.Join(dir, path)
		if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(full, body, 0o644); err != nil {
			return err
		}
	}
	return nil
}

func sortedKeys[K interface{ ~string | ~int }, V any](m map[K]V) []K {
	keys := make([]K, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool { return keys[i] < keys[j] })
	return keys
}
