"""Offline renders of Soccer Single when ESPN leaves fields out.

python3 tests/soccersingle_no_record.py pixlet

The recorded USA response (tests/soccersingle_no_record.json) has no "record",
as ESPN does for competitions without standings (FIFA friendlies, cups); the
pre-game card crashed on it. Variants drop the teams' crests (the placeholder
URL must not be fetched; Wikimedia answers it with 403) and "nextEvent" (ESPN
omits it when a team has no scheduled game; the app must skip, not fail).
"""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = sys.argv[1]
recorded = json.loads((root / "tests/soccersingle_no_record.json").read_text())
app = root / "apps/soccersingle"

no_logos = json.loads(json.dumps(recorded))
for competitor in no_logos["team"]["nextEvent"][0]["competitions"][0]["competitors"]:
    competitor["team"].pop("logos")
no_event = json.loads(json.dumps(recorded))
no_event["team"].pop("nextEvent")
CASES = [("no record", recorded, 1), ("no crests", no_logos, 1), ("no next event", no_event, 0)]

# Team responses come from the fixture and ESPN crests are a test pixel; any
# other request (the Wikimedia placeholder included) fails the render.
overrides = '''
load("pixel.png", TEST_LOGO = "file")
def get_cachable_data(url, ttl_seconds = 60):
    if url.startswith("https://site.api.espn.com/"):
        return FIXTURE
    if url.startswith("https://a.espncdn.com/"):
        return TEST_LOGO.readall()
    fail("unexpected request " + url)
'''

checked = 0
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    shutil.copy(app / "logos.star", tmp / "logos.star")
    shutil.copytree(app / "images", tmp / "images")
    (tmp / "pixel.png").write_bytes((root / "apps/nhlnextgame/images/ana.png").read_bytes())
    source = (app / "soccer_single.star").read_text()
    source = source.replace("def get_cachable_data(", "def original_get_cachable_data(", 1)
    for name, fixture, frames in CASES:
        (tmp / "app.star").write_text(source + overrides + "FIXTURE = %r\n" % json.dumps(fixture))
        for layout in ("colors", "black", "horizontal", "retro"):
            result = subprocess.run([runtime, "render", str(tmp / "app.star"), "teamid=660", "displayType=" + layout,
                                     "--output", str(tmp / "out.webp"), "--metadata-output", str(tmp / "meta.json"),
                                     "--silent"], capture_output=True, text=True)
            assert result.returncode == 0, (name, layout, result.stderr[-800:])
            count = json.loads((tmp / "meta.json").read_text())["frame_count"]
            assert (count > 0) == (frames > 0), (name, layout, count)
            checked += 1
print(f"{checked} Soccer Single renders without a record, crests or next event passed")
