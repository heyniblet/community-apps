"""Offline regression: python3 apps/espnnews/test_render.py /path/to/niblet."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

source = Path(__file__).with_name("espn_news.star").read_text()
start = source.index("    rep = http.get(")
end = source.index("    title = normalized_headlines(payload, sport)", start)

def article(title, league, description=""):
    return {"headline": title, "categories": [{"type": "league", "sportId": league, "description": description}]}

payload = {"headlines": [None, {"headline": 12}, article("Basketball", 46),
    article("Football", 28), article("College", 23, "NCAA Football"),
    article("Women", 59), article("Formula One", 2030), article("Stock cars", 2020)]}
cases = [("NFL", ["Football"]), ("NBA", ["Basketball"]), ("NCAAF", ["College"]),
    ("College Sports", ["College"]), ("WNBA", ["Women"]), ("F1", ["Formula One"]),
    ("NASCAR", ["Stock cars"]), ("All", ["Basketball", "Football", "College"])]
with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    app = directory / "espn_news.star"
    for sport, expected in cases + [("NHL", [])]:
        injected = "    payload = json.decode(" + repr(json.dumps(payload)) + ")\n"
        injected += "    if normalized_headlines(payload, sport) != " + repr(expected) + ":\n        fail(\"wrong league headlines\")\n"
        app.write_text((source[:start] + injected + source[end:]).replace("str(rep.status_code)", '"200"'))
        for scale in [1, 2]:
            for vertical in ["false", "true"]:
                args = [sys.argv[1], "render", str(app), "sport=" + sport,
                    "scroll_vertical=" + vertical, "--width", str(64 * scale),
                    "--height", str(32 * scale), "-o", str(directory / "render.webp")]
                result = subprocess.run(args, capture_output=True, text=True)
                if not expected:
                    assert result.returncode != 0 and "ESPN headlines unavailable" in result.stderr, result.stderr
                else:
                    assert result.returncode == 0, result.stderr
    # Bad or blocked upstream responses must fail, preserving the last good frame.
    for bad in [None, {}, {"headlines": "invalid"}, {"headlines": [{"headline": " "}]}]:
        injected = "    payload = json.decode(" + repr(json.dumps(bad)) + ")\n"
        app.write_text((source[:start] + injected + source[end:]).replace("str(rep.status_code)", '"403"'))
        result = subprocess.run([sys.argv[1], "render", str(app)], capture_output=True, text=True)
        assert result.returncode != 0 and "ESPN headlines unavailable" in result.stderr, result.stderr
print("PASS: league filtering, malformed feeds, both scroll directions and display sizes")
