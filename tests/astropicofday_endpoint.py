"""Offline renders of Astro Pic of Day against NASA's science.nasa.gov entries.

python3 tests/astropicofday_endpoint.py pixlet

api.nasa.gov/planetary/apod stopped serving pictures when NASA moved APOD, so
the app reads science.nasa.gov/wp-json/wp/v2/apod-basic. Each case is an entry
shape seen there in November 2026, with the one image request the app may make
for it; any other request fails the render. An empty list or an entry without a
picture must fail, so Cloud keeps the last good frame.
"""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = sys.argv[1]
app = root / "apps/astropicofday"
ASSETS = "https://assets.science.nasa.gov/"
SMALL = "?w=512&h=64&fit=clip"


def entry(media_type, hdurl):
    return {"date": "2026-11-21", "title": "Voyager's Neptune", "media_type": media_type, "hdurl": hdurl}


CASES = [
    ("image", [entry("image", ASSETS + "dynamicimage/assets/science/cds/apod/apod/2026/november/Neptune_2327x1670.jpg?w=2327&h=1670&fit=clip")],
     ASSETS + "dynamicimage/assets/science/cds/apod/apod/2026/november/Neptune_2327x1670.jpg" + SMALL),
    ("video still", [entry("video", ASSETS + "dynamicimage/assets/science/cds/apod/apod/2026/october/occultation.jpeg?w=1600&h=1000&fit=clip")],
     ASSETS + "dynamicimage/assets/science/cds/apod/apod/2026/october/occultation.jpeg" + SMALL),
    ("48 pixel rendition", [entry("image", ASSETS + "content/dam/science/cds/apod/apod/2026/november/meteor_1200.jpg/jcr:content/renditions/cq5dam.thumbnail.48.48.png")],
     ASSETS + "dynamicimage/assets/science/cds/apod/apod/2026/november/meteor_1200.jpg" + SMALL),
    ("mission image with a space", [entry("image", ASSETS + "dynamicimage/assets/science/missions/hubble/galaxies/irregular/NGC%204449.jpg?w=2048&h=1320&fit=clip")],
     ASSETS + "dynamicimage/assets/science/missions/hubble/galaxies/irregular/NGC%204449.jpg" + SMALL),
    ("other host", [entry("image", "https://example.invalid/picture.jpg")], "https://example.invalid/picture.jpg"),
    ("no entries", [], None),
    ("error object", {"code": 500, "msg": "Internal Service Error"}, None),
    ("no image", [entry("image", "")], None),
    ("no title", [{"date": "2026-11-21", "media_type": "image", "hdurl": ASSETS + "dynamicimage/a.jpg"}], None),
]

overrides = '''
load("pixel.png", TEST_PICTURE = "file")
def get_entries(url, ttl_seconds):
    if url != "https://science.nasa.gov/wp-json/wp/v2/apod-basic":
        fail("unexpected request " + url)
    return json.decode(FIXTURE)
def get_image_src(url, ttl_seconds):
    if url != EXPECTED_IMAGE:
        fail("unexpected request " + url)
    return TEST_PICTURE.readall()
'''

checked = 0
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    shutil.copytree(app / "images", tmp / "images")
    (tmp / "pixel.png").write_bytes((root / "apps/nhlnextgame/images/ana.png").read_bytes())
    source = (app / "astro_pic_of_day.star").read_text()
    source = source.replace("def get_entries(", "def original_get_entries(", 1)
    source = source.replace("def get_image_src(", "def original_get_image_src(", 1)
    source = 'load("encoding/json.star", "json")\n' + source
    for name, fixture, image in CASES:
        (tmp / "app.star").write_text(
            source + overrides + "FIXTURE = %r\nEXPECTED_IMAGE = %r\n" % (json.dumps(fixture), image or ""))
        for info in ("true", "false"):
            result = subprocess.run([runtime, "render", str(tmp / "app.star"), "display_info=" + info,
                                     "--output", str(tmp / "out.webp"), "--metadata-output", str(tmp / "meta.json"),
                                     "--silent"], capture_output=True, text=True)
            if image is None:
                assert result.returncode != 0, (name, info, "rendered without a picture")
                assert "NASA APOD response did not include" in result.stderr, (name, info, result.stderr[-800:])
            else:
                assert result.returncode == 0, (name, info, result.stderr[-800:])
                assert json.loads((tmp / "meta.json").read_text())["frame_count"] > 0, (name, info)
            checked += 1
print(f"{checked} Astro Pic of Day renders against science.nasa.gov entries passed")
