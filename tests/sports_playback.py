"""Offline complete-sequence regression/benchmark: python3 tests/sports_playback.py ../niblet-cli/niblet."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())
event = json.loads((root / 'tests/ncaaf_event.json').read_text())
source = (root / 'apps/ncaafscores/ncaaf_scores.star').read_text()
source = source.replace('def get_cachable_data(', 'def original_get_cachable_data(')
source += '''
load("pixel.png", TEST_LOGO = "file")
FIXTURE = json.decode(%s)
def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    if "/scoreboard" not in url:
        return TEST_LOGO.readall()
    games = []
    for i in range(300):
        game = dict(FIXTURE)
        game["id"] = str(1000 + i)
        competition = dict(game["competitions"][0])
        competitors = [dict(c) for c in competition["competitors"]]
        competitors[0]["score"] = str(i)
        competition["competitors"] = competitors
        game["competitions"] = [competition]
        games.append(game)
    return json.encode({"events": games})
''' % repr(json.dumps(event))
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    (tmp/'pixel.png').write_bytes((root/'apps/nhlnextgame/images/ana.png').read_bytes())
    (tmp/'scores.star').write_text(source)
    for speed, style in ((5, "colors"), (15, "colors"), (15, "retro"), (15, "stadium")):
        started = time.monotonic()
        subprocess.run([runtime, 'render', str(tmp/'scores.star'), f'rotationSpeed={speed}', f'displayType={style}',
                        '--output', str(tmp/'scores.webp'), '--metadata-output', str(tmp/'metadata.json'),
                        '--timeout', '20s', '--silent'], check=True)
        metadata = json.loads((tmp/'metadata.json').read_text())
        assert metadata['show_full_animation']
        assert metadata['frame_count'] == 300, metadata
        assert metadata['animation_duration_millis'] == 300 * speed * 1000, metadata
        size = (tmp/'scores.webp').stat().st_size
        assert size <= 2 * 1024 * 1024, size
        print(f'300 games x {speed}s ({style}): {size} bytes, {time.monotonic()-started:.2f}s render; complete')
