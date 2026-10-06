"""Offline NFL logo regression. Run with network denied: python3 tests/nfl_logo_assets.py /path/to/niblet."""
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
app = root / 'apps/nflscores'
runtime = str(Path(sys.argv[1]).resolve())
expected = {
    'colts.png': 'c59105ddaf13f73f07b5db09ddc3b542278a71f6a3a88024efa31241e27e6e4e',
    'lar.png': '5fd379a7bbc4958605f66e512af89b8819cea8b81f19e9b0408b17bca2d0ba6b',
}
for name, digest in expected.items():
    assert hashlib.sha256((app / 'images' / name).read_bytes()).hexdigest() == digest
source = (app / 'nfl_scores.star').read_text().replace('def main(config):', 'def scoreboard_main(config):', 1)
fixture = '''
def main(config):
    colts = get_logoType("IND", "https://unreachable.invalid/colts.png")
    rams = get_logoType("LAR", "https://unreachable.invalid/rams.png")
    if colts != COLTS_LOGO.readall() or rams != RAMS_LOGO.readall():
        fail("custom logo bytes changed")
    return render.Root(delay = 5000, child = render.Row(children = [
        render.Image(colts, width = 32, height = 32),
        render.Image(rams, width = 32, height = 32),
    ]))
'''
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    shutil.copytree(app / 'images', tmp / 'images')
    shutil.copy(app / 'logos.star', tmp / 'logos.star')
    for variant in ('bundled', 'original-bytes'):
        body = fixture
        if variant == 'original-bytes':
            body = body.replace('get_logoType("IND", "https://unreachable.invalid/colts.png")', 'COLTS_LOGO.readall()')
            body = body.replace('get_logoType("LAR", "https://unreachable.invalid/rams.png")', 'RAMS_LOGO.readall()')
        (tmp / 'test.star').write_text(source + body)
        for scale in (1, 2):
            subprocess.run([runtime, 'render', str(tmp / 'test.star'), '--magnify', str(scale),
                            '--output', str(tmp / f'{variant}-{scale}.webp'), '--silent'],
                           check=True, capture_output=True)
    for scale in (1, 2):
        assert (tmp / f'bundled-{scale}.webp').read_bytes() == (tmp / f'original-bytes-{scale}.webp').read_bytes()
print('NFL custom logo bytes and rendered output match at both resolutions without network access')
