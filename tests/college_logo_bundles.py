"""Offline checks for the bundled college team logos: python3 tests/college_logo_bundles.py /path/to/niblet [app ...].

Checks each app's logos/index.json, logos.bin and sources.json agree, every PNG
has the drawn size, and the app's own get_logo_source/get_logo_image serve
common teams from the bundle with HTTP replaced by a failure. Pixel parity
with the original downloads is verified by tools/college_logos/verify.py.
"""
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())
ESPN = "https://a.espncdn.com/i/teamlogos/ncaa/500/%s.png"
# Georgia (magnified), Purdue (plain ESPN logo) and Duke (alternate logo URL).
COMMON = [["UGA", ESPN % "61"], ["PUR", ESPN % "2509"], ["DUKE", ESPN % "150"]]
APPS = {
    "ncaafscores": "scores", "ncaamscores": "scores", "ncaawscores": "scores", "ncaabscores": "scores",
    "ncaafstandings": "standings", "ncaamstandings": "standings", "ncaawstandings": "standings",
}

for app in sys.argv[2:] or APPS:
    kind = APPS[app]
    folder = root / "apps" / app / "logos"
    index = json.loads((folder / "index.json").read_text())
    sources = json.loads((folder / "sources.json").read_text())["logos"]
    pack = (folder / "logos.bin").read_bytes()
    assert set(index) == set(sources), app
    spans = sorted((start, end, url, int(size)) for url, sizes in index.items() for size, (start, end) in sizes.items())
    offset = 0
    for start, end, url, size in spans:
        assert start == offset and end > start, (app, url, size)
        png = pack[start:end]
        assert png[:8] == b"\x89PNG\r\n\x1a\n" and png[12:16] == b"IHDR", (app, url)
        assert struct.unpack(">II", png[16:24]) == (size, size), (app, url, size)
        assert size in sources[url]["sizes"], (app, url, size)
        offset = end
    assert offset == len(pack), app
    assert (folder / "README.md").exists(), app
    source = next((root / "apps" / app).glob("*.star")).read_text()
    source = source.replace("def main(config):", "def app_main(config):", 1)
    source = source.replace("def get_cachable_data(", "def original_get_cachable_data(", 1)
    common = COMMON[2:] if app == "ncaabscores" else COMMON
    sizes = "[get_logoSize(team), 30, 32]" if kind == "scores" else "[10]"
    source += """
def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    fail("unexpected request for " + url)

def main(config):
    images = []
    for url in LOGO_INDEX:
        for size in LOGO_INDEX[url]:
            images.append(render.Image(get_logo_image((url, 0), int(size)), width = int(size), height = int(size)))
    for team, logo in json.decode(%r):
        source = get_logo_source(team, logo)
        for size in %s:
            span = LOGO_INDEX[source[0]][str(size)]
            if get_logo_image(source, size) != LOGO_PACK[span[0]:span[1]]:
                fail("bundled bytes differ for " + team)
    return render.Root(child = render.Stack(children = images))
""" % (json.dumps(common), sizes)
    with tempfile.TemporaryDirectory() as directory:
        tmp = Path(directory)
        shutil.copytree(folder, tmp / "logos")
        (tmp / "app.star").write_text(source)
        subprocess.run([runtime, "render", str(tmp / "app.star"), "--output", str(tmp / "app.webp"), "--silent"], check=True, capture_output=True)
    print("%s: %d logos, %d bundled images, %d bytes; served offline through the app's lookup" % (app, len(index), len(spans), len(pack)))
