"""Offline regression: python3 apps/espnnews/test_render.py /path/to/niblet."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile


source = Path(__file__).with_name("espn_news.star").read_text()
start = source.index("    rep = http.get(")
end = source.index("    title = normalized_headlines(payload)", start)

with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    app = directory / "espn_news.star"
    metadata = directory / "render.json"
    for payload in [None, {"headlines": [{"headline": "A short sports headline"}]}]:
        # Replace only the network fetch; exercise the real parser and layout.
        app.write_text(source[:start] + "    payload = " + repr(payload) + "\n" + source[end:])
        for sport in ["All", "NCAAF"]:
            for vertical in ["false", "true"]:
                subprocess.run([
                    sys.argv[1], "render", str(app), "sport=" + sport,
                    "scroll_vertical=" + vertical,
                    "-o", str(directory / "render.webp"),
                    "--metadata-output", str(metadata),
                ], check=True, capture_output=True, text=True)
                result = json.loads(metadata.read_text())
                if payload is not None and vertical == "true":
                    assert result["frame_count"] == 1, result  # Short text fits without scrolling.
                else:
                    assert result["frame_count"] > 1, (payload, sport, vertical, result)
                assert not result.get("http_requests"), result
    print("PASS: missing headlines scroll; short vertical headlines fit; both label widths checked")
