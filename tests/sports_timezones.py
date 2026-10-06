"""Offline timezone/schema regression: python3 tests/sports_timezones.py /path/to/niblet."""
from pathlib import Path
import json
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())
apps = ("nflscores", "mlbscores", "nhlscores", "ncaafscores", "nbascores", "ncaabscores", "ncaamscores", "ncaawscores", "wnbascores", "cflscores", "mlsscores", "eplscores")
cases = [
    ({"$tz": "America/Chicago"}, "America/Chicago"),
    ({}, "UTC"),
    ({"timezone": "Europe/London", "$tz": "America/Chicago"}, "Europe/London"),
    ({"timezone": "  Asia/Kolkata  "}, "Asia/Kolkata"),
    ({"location": json.dumps({"timezone": "America/New_York", "lat": "", "lng": ""}), "$tz": "Europe/London"}, "America/New_York"),
    ({"timezone": "", "location": json.dumps({"timezone": "America/New_York"}), "$tz": "Europe/London"}, "Europe/London"),
]
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    for app in apps:
        path = next((root / "apps" / app).glob("*.star"))
        schema = json.loads(subprocess.check_output([runtime, "schema", str(path)]))
        fields = {f["id"]: f for f in schema["schema"]}
        assert "location" not in fields and fields["timezone"]["type"] == "text", app
        source = path.read_text().replace("def main(config):", "def scoreboard_main(config):", 1)
        assets = path.parent / 'images'
        if assets.exists():
            shutil.copytree(assets, tmp / 'images', dirs_exist_ok=True)
        # Bundled college team logos are loaded at module level.
        logos = path.parent / 'logos'
        if logos.exists():
            shutil.copytree(logos, tmp / 'logos', dirs_exist_ok=True)
        source += '\nTEST_CASES = json.decode(' + repr(json.dumps(cases)) + ')\n'
        source += '''
def main(config):
    for case in TEST_CASES:
        actual = scoreboard_timezone(case[0])
        if actual != case[1]:
            fail("timezone mismatch: " + actual + " != " + case[1])
    # Exercise the actual runtime config object as well as legacy dictionaries.
    if scoreboard_timezone(config) != "Europe/London":
        fail("runtime timezone override was not applied")
    return render.Root(child = render.Text(content = "TZ OK", font = "5x8"))
'''
        test = tmp / "timezone.star"
        test.write_text(source)
        subprocess.run([runtime, "render", str(test), "timezone=Europe/London", "--output", str(tmp / "out.webp"), "--silent"], check=True, capture_output=True)
        invalid = subprocess.run([runtime, "render", str(test), "timezone=Invalid/Timezone", "--output", str(tmp / "out.webp"), "--silent"], capture_output=True, text=True)
        assert invalid.returncode != 0 and "valid timezone" in invalid.stderr, app
        print(app + ": timezone defaults, overrides, legacy choices and schema passed")
