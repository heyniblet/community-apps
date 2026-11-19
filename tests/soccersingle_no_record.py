"""Offline render of Soccer Single when ESPN omits a team's "record".

python3 tests/soccersingle_no_record.py pixlet

ESPN leaves "record" out of the team response for competitions without
standings (FIFA friendlies, cups). The pre-game card crashed on it.
"""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = sys.argv[1]
fixture = (root / "tests/soccersingle_no_record.json").read_text()
app = root / "apps/soccersingle"

overrides = '''
load("pixel.png", TEST_LOGO = "file")
def get_logoType(*args, **kwargs):
    return TEST_LOGO.readall()
def get_cachable_data(url, ttl_seconds = 60):
    return %s
''' % repr(fixture)

with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    shutil.copy(app / "logos.star", tmp / "logos.star")
    shutil.copytree(app / "images", tmp / "images")
    (tmp / "pixel.png").write_bytes((root / "apps/nhlnextgame/images/ana.png").read_bytes())
    source = (app / "soccer_single.star").read_text()
    source = source.replace("def get_cachable_data(", "def original_get_cachable_data(", 1)
    source = source.replace("def get_logoType(", "def original_get_logoType(", 1)
    (tmp / "app.star").write_text(source + overrides)
    for layout in ("colors", "black", "horizontal", "retro"):
        result = subprocess.run([runtime, "render", str(tmp / "app.star"), "teamid=660", "displayType=" + layout,
                                 "--output", str(tmp / "out.webp"), "--silent"],
                                capture_output=True, text=True)
        assert result.returncode == 0, (layout, result.stderr[-800:])
print("4 Soccer Single renders without a team record passed")
