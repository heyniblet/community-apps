#!/usr/bin/env python3
"""Verify bundled college logos are pixel-identical to the originals they replace.

    python3 tools/college_logos/verify.py --runtime /path/to/niblet --cache DIR [app ...]

DIR is the download cache written by build.py. For every bundled URL and size
this renders the original download resized by the runtime (exactly what the
app did before) and the bundled PNG, each over an opaque and a transparent
background, at 1x and 2x, and requires byte-identical lossless WebP output.
"""
import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path


def verify(runtime, app, store):
    sources = json.loads((app / "logos/sources.json").read_text())["logos"]
    pack = (app / "logos/logos.bin").read_bytes()
    index = {url: {int(size): tuple(span) for size, span in sizes.items()}
             for url, sizes in json.loads((app / "logos/index.json").read_text()).items()}
    assert set(index) == set(sources), "index and provenance disagree"

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        loads, frames = [], {"original": [], "bundled": []}
        count = 0
        for i, url in enumerate(sorted(index)):
            original = store / hashlib.sha256(url.encode()).hexdigest()
            assert hashlib.sha256(original.read_bytes()).hexdigest() == sources[url]["original_sha256"], url
            (tmp / ("o%d.bin" % i)).write_bytes(original.read_bytes())
            loads.append('load("o%d.bin", O%d = "file")' % (i, i))
            assert sorted(index[url]) == sorted(sources[url]["sizes"]), url
            for size, (start, end) in sorted(index[url].items()):
                png = pack[start:end]
                assert png[:8] == b"\x89PNG\r\n\x1a\n" and png[-8:-4] == b"IEND", (url, size)
                (tmp / ("b%d_%d.bin" % (i, size))).write_bytes(png)
                loads.append('load("b%d_%d.bin", B%d_%d = "file")' % (i, size, i, size))
                count += 1
                for name, src in (("original", "O%d.readall()" % i), ("bundled", "B%d_%d.readall()" % (i, size))):
                    frames[name].append(
                        "render.Row(children = [render.Box(width = 32, height = 32, color = \"#7f3fbf\", child = render.Image(%s, width = %d, height = %d)), "
                        "render.Box(width = 32, height = 32, child = render.Image(%s, width = %d, height = %d))])" % (src, size, size, src, size, size))
        assert sum(end - start for sizes in index.values() for start, end in sizes.values()) == len(pack), "pack has unindexed bytes"
        results = {}
        for name in ("original", "bundled"):
            star = tmp / ("%s.star" % name)
            star.write_text('load("render.star", "render")\n' + "\n".join(loads) + "\n\ndef main(config):\n    return render.Root(delay = 50, child = render.Animation(children = [\n        " +
                            ",\n        ".join(frames[name]) + ",\n    ]))\n")
            for scale in (1, 2):
                out = tmp / ("%s-%d.webp" % (name, scale))
                args = [runtime, "render", str(star), "-o", str(out), "-d", "2h", "--timeout", "600s", "--silent"]
                if scale == 2:
                    args.append("-2")
                subprocess.run(args, check=True, capture_output=True)
                results[(name, scale)] = out.read_bytes()
        for scale in (1, 2):
            same = results[("original", scale)] == results[("bundled", scale)]
            print("%s %dx: %d logos, %d bundled images, %s (%d bytes)" % (app.name, scale, len(index), count, "IDENTICAL" if same else "DIFFERENT", len(results[("original", scale)])))
            assert same


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime", required=True)
    parser.add_argument("--cache", default=str(Path(tempfile.gettempdir()) / "college-logos-cache"))
    parser.add_argument("apps", nargs="*", default=["ncaafscores", "ncaafstandings", "ncaamscores", "ncaamstandings",
                                                     "ncaawscores", "ncaawstandings", "ncaabscores"])
    args = parser.parse_args()
    for name in args.apps:
        verify(str(Path(args.runtime).resolve()), Path(__file__).resolve().parents[2] / "apps" / name, Path(args.cache))
