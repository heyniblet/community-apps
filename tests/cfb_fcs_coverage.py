"""Replay Division I football lookups without ESPN or a shared cache.

python3 tests/cfb_fcs_coverage.py ../niblet-cli/niblet
"""

import json
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "apps/cfbplaybyplay/cfb_play_by_play.star"
RUNTIME = Path(sys.argv[1]).resolve()
API = "https://site.api.espn.com/apis/site/v2/sports/football/college-football"
SCOREBOARD = API + "/scoreboard"
FBS = SCOREBOARD + "?groups=80"
FCS = SCOREBOARD + "?groups=81&limit=1000"
RANKINGS = API + "/rankings"
DIRECTORY = API + "/teams?limit=1000"
CCSU = {"id": "2115", "abbreviation": "CCSU"}
DUQ = {"id": "2184", "abbreviation": "DUQ"}
OSU = {"id": "194", "abbreviation": "OSU"}
MICH = {"id": "130", "abbreviation": "MICH"}
EMPTY = {"events": []}


def live_game(home, away):
    return {"events": [{
        "status": {"type": {"state": "in", "name": "STATUS_IN_PROGRESS"}},
        "competitions": [{"competitors": [
            {"team": home, "homeAway": "home", "score": "14"},
            {"team": away, "homeAway": "away", "score": "10"},
        ]}],
    }]}


def check(name, config, responses, size=(64, 32), known_team=False, hidden=False):
    with tempfile.TemporaryDirectory() as directory:
        tmp = Path(directory)
        source = APP.read_text()
        for function in ("try_fetch_json", "get_logo"):
            source = source.replace(f"def {function}(", f"def original_{function}(", 1)
        source += f"""
RESPONSES = json.decode({json.dumps(json.dumps(responses))})
def try_fetch_json(url, ttl):
    if url not in RESPONSES:
        fail("unexpected request " + url)
    print("request " + url)
    return RESPONSES[url]
def get_logo(url, abbr, kp):
    print("logo " + abbr)
    return None
"""
        app = tmp / APP.name
        app.write_text(source)
        (tmp / "config.json").write_text(json.dumps(config))
        result = subprocess.run([
            str(RUNTIME), "render", str(app), "--config", str(tmp / "config.json"),
            "--width", str(size[0]), "--height", str(size[1]),
            "--now", "2026-11-21T17:30:00Z",
            "--output", str(tmp / "render.webp"), "--metadata-output", str(tmp / "render.json"),
        ], capture_output=True, text=True, timeout=20)
        assert result.returncode == 0, (name, result.stderr)
        messages = [line.partition("] ")[2] for line in result.stdout.splitlines()]
        requests = [line.removeprefix("request ") for line in messages if line.startswith("request ")]
        assert requests == list(responses), (name, requests)
        assert ("logo " + config["team"].strip().upper() in messages) == known_team, (name, messages)
        frames = json.loads((tmp / "render.json").read_text())["frame_count"]
        assert (frames == 0) == hidden, (name, frames)
        print(f"{name} passed")


off_day = {SCOREBOARD: EMPTY, FBS: EMPTY, FCS: EMPTY}
directory = {"sports": [{"leagues": [{"teams": [
    {"team": CCSU},
    {"team": OSU},
    {"team": {"id": "195", "abbreviation": "OSU"}},
    {"team": {"id": "888", "abbreviation": "D2"}},
]}]}]}
team_details = {"team": {
    **CCSU,
    "groups": {"parent": {"id": "81"}},
    "record": {"items": [{"type": "total", "summary": "6-4"}]},
    "nextEvent": [{"date": "2026-11-28T17:00Z", "shortName": "DUQ @ CCSU"}],
}}
lookup = {**off_day, RANKINGS: {"rankings": []}, DIRECTORY: directory}

check("FCS live on a wide panel", {"team": " ccsu "},
      {SCOREBOARD: EMPTY, FBS: EMPTY, FCS: live_game(CCSU, DUQ)}, known_team=True)
check("FCS live on a square panel", {"team": "CCSU"},
      {SCOREBOARD: EMPTY, FBS: EMPTY, FCS: live_game(CCSU, DUQ)}, size=(64, 64), known_team=True)
check("FCS idle with an empty cache", {"team": "CCSU"},
      {**lookup, API + "/teams/2115": team_details}, known_team=True)
check("Unknown abbreviation", {"team": "ZZZZ"}, lookup)
check("Ambiguous directory entry", {"team": "OSU"}, lookup)
check("Team outside Division I", {"team": "D2"},
      {**lookup, API + "/teams/888": {"team": {"groups": {"parent": {"id": "35"}}}}})
check("Game day only hides off days", {"team": "CCSU", "gameday_only": True}, off_day, hidden=True)
check("FBS fast path", {"team": "OSU"}, {SCOREBOARD: live_game(OSU, MICH)}, known_team=True)
