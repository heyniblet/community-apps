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

def chunks(path):
    data = path.read_bytes()
    offset = 12
    found = set()
    while offset + 8 <= len(data):
        found.add(data[offset:offset+4])
        size = int.from_bytes(data[offset+4:offset+8], 'little')
        offset += 8 + size + size % 2
    return found

fixture = '''
load("pixel.png", TEST_LOGO = "file")
FIXTURE = json.decode(%s)
def get_logoType(team, logo = None):
    return TEST_LOGO.readall()
def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    if "/scoreboard" not in url:
        return TEST_LOGO.readall()
    games = []
    for i in range(GAME_COUNT):
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
    for app, count in (
        ("nflscores", 16), ("ncaafscores", 300),
        *((name, 16) for name in (
            "mlbscores", "nbascores", "wnbascores", "nhlscores",
            "ncaamscores", "ncaawscores", "ncaabscores", "mlsscores",
            "eplscores", "cflscores", "mhkyscores", "wbcscores",
            "uflscores", "xflscores", "soccermens", "soccerwomens",
        )),
    ):
        source = next((root / 'apps' / app).glob('*.star')).read_text()
        source = source.replace('def get_cachable_data(', 'def original_get_cachable_data(')
        source = source.replace('def get_logoType(', 'def original_get_logoType(')
        if app in ("soccermens", "soccerwomens"):
            # Competition labels are external metadata, not part of playback.
            source = source.replace('json.decode(http.get(url = ABBR_URL, ttl_seconds = COMPS_TTL).body())',
                                    '{DEFAULT_LEAGUE: "TEST"}')
            source = source.replace('def get_schema(', 'def original_get_schema(')
        source += "\nGAME_COUNT = " + str(count) + "\n" + fixture
        (tmp/'scores.star').write_text(source)
        cases = ((5, "colors"), (15, "colors"), (15, "retro"), (15, "stadium"))
        if app in ("soccermens", "soccerwomens"):
            cases = ((1, "colors"), (3, "colors"))
        for speed, style in cases:
            started = time.monotonic()
            subprocess.run([runtime, 'render', str(tmp/'scores.star'), f'rotationSpeed={speed}', f'displaySpeed={speed * 1000}', f'displayType={style}',
                            '--output', str(tmp/'scores.webp'), '--metadata-output', str(tmp/'metadata.json'),
                            '--timeout', '20s', '--silent'], check=True)
            metadata = json.loads((tmp/'metadata.json').read_text())
            assert metadata['show_full_animation']
            assert metadata['frame_count'] == count, metadata
            assert metadata['animation_duration_millis'] == count * speed * 1000, metadata
            assert (b"NBFC" in chunks(tmp/"scores.webp")) == ("frame_keys =" in source), app
            size = (tmp/'scores.webp').stat().st_size
            assert size <= 2 * 1024 * 1024, size
            print(f'{app}: {count} games x {speed}s ({style}): {size} bytes, {time.monotonic()-started:.2f}s render; complete')

        if "frame_keys =" in source:
            subprocess.run([runtime, 'render', str(tmp/'scores.star'), 'displayTop=time',
                            '--output', str(tmp/'scores.webp'), '--metadata-output', str(tmp/'metadata.json'),
                            '--timeout', '20s', '--silent'], check=True, capture_output=True)
            metadata = json.loads((tmp/'metadata.json').read_text())
            assert metadata['frame_count'] == count and metadata['show_full_animation'], app
            assert b"NBFC" not in chunks(tmp/'scores.webp'), app

        # ESPN can omit optional fields or return null list entries.
        for state, odds in (("pre", None), ("pre", []), ("pre", [None]),
                            ("pre", [{"homeTeamOdds": {}, "awayTeamOdds": {}}]),
                            ("post", None)):
            incomplete = json.loads(json.dumps(event))
            incomplete["status"]["type"].update(state=state, name="STATUS_FINAL" if state == "post" else "STATUS_SCHEDULED", shortDetail="Final" if state == "post" else "Scheduled")
            competition = incomplete["competitions"][0]
            competition.update(odds=odds, notes=None, series={"title": "Playoffs"} if state == "post" else None)
            broken_source = source.replace(repr(json.dumps(event)), repr(json.dumps(incomplete)))
            (tmp/'scores.star').write_text(broken_source)
            subprocess.run([runtime, 'render', str(tmp/'scores.star'), 'pregameDisplay=odds',
                            '--output', str(tmp/'scores.webp'), '--metadata-output', str(tmp/'metadata.json'),
                            '--timeout', '20s', '--silent'], check=True, capture_output=True)
            metadata = json.loads((tmp/'metadata.json').read_text())
            assert metadata['frame_count'] == count, (app, state, odds, metadata)
        print(f'{app}: null/empty odds, absent money lines, and missing series notes rendered')
