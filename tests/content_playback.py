"""Offline content sequence checks: python3 tests/content_playback.py PATH_TO_NIBLET."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())

# Exercise production sequence assembly with synthetic inputs; no credentials or network.
cases = {
    "mlbstatsleaders": ("""
def fetch_leaders(stat):
    return [stat]
def render_stat_slide(stat, leaders):
    return render.Text(stat)
""", ["stat1=HR", "stat2=ERA", "stat3=H", "stat4=R", "speed=5"], 20000),
    "nbastats": ("""
def fetch_player_data(url, index):
    return render.Text(str(index))
""", [], 15000),
    "sportsrankings": ("""
def get_cachable_data(url):
    return json.encode({"rankings": [{"ranks": [{"team": {"abbreviation": "T" + str(i), "color": "ffffff"}, "recordSummary": "1-0"} for i in range(25)]}]})
""", [], 15000),
    "menscricket": ("""
def main(config):
    teams = team_settings_by_id.values()
    return render_next_match({"matchHeader": {
        "matchStartTimestamp": (time.now().unix + 864000) * 1000,
        "team1": {"id": teams[0].id, "name": teams[0].name},
        "team2": {"id": teams[1].id, "name": teams[1].name},
        "matchDescription": "Test match", "state": "upcoming",
        "venue": {"city": "London", "country": "England"}}}, "UTC")
""", [], 16000),
    "ha_calendar": ("""
def main(config):
    return render_calendar([("12:00pm", "Event " + str(i)) for i in range(6)], "#800080", time.now(), 2 if canvas.is2x() else 1)
""", [], 30000),
    "topcryptoprices": ("""
def test_get(*args, **kwargs):
    return struct(status_code = 200, body = test_body)
def test_body():
    return json.encode([{"symbol": "coin" + str(i), "market_cap_rank": i + 1, "current_price": 10 + i, "price_change_percentage_24h": 1} for i in range(10)])
""", ["numcoins=10", "delay=2000"], 20000),
    "bgghotness": ("""
def test_cache_get(key):
    return json.encode({"timestamp": time.now().unix, "list": [{"name": "Game " + str(i)} for i in range(COUNT)]})
""", ["bgg_api_key=offline-test"], None),
    "usgsearthquakes": ("""
def fetch_earthquakes(*args):
    return [{"properties": {"mag": i + 3, "place": "A sufficiently long earthquake location " + str(i), "time": time.now().unix * 1000}} for i in range(3)]
""", [], None),
    "universalical": ("""
def main(config):
    return render_calendar_base_object([], get_calendar_bottom({"hasEvent": True, "summary": "An event title that requires a complete scrolling pass", "copy": "Tomorrow afternoon", "textColor": "#ffffff", "shouldAnimateText": True}))
""", [], None),
    "ouraring": ("", [], 6000),
    "solaredgesummary": ("", [], 15000),
    "enphasesummary": ("", [], 15000),
    "footballtable": ("""
def test_get(*args, **kwargs):
    return struct(status_code = 200, body = test_body)
def test_body():
    return json.encode({"standings": [{"table": [{"team": {"tla": "T" + str(i)}, "points": 50 - i} for i in range(24)]}]})
""", ["api_key=offline-test", "league=ELC"], 18000),
    "outlookcalendar": ("""
def test_get(*args, **kwargs):
    return struct(status_code = 200, body = test_body)
def test_body():
    return "offline calendar"
def parse_events(body, timezone, now):
    return [{"title": "Meeting " + str(i), "start": now, "end": now + time.parse_duration("1h")} for i in range(8)]
""", ["full_day=true"], 24000),
    "ynab": ("""
def test_get(url, **kwargs):
    return struct(body = settings_body if url.endswith("settings") else categories_body)
def settings_body():
    return json.encode({"data": {"settings": {"currency_format": {}}}})
def categories_body():
    return json.encode({"data": {"month": {"categories": [{"name": "Category " + str(i), "activity": -1000, "balance": -1000, "budgeted": 10000} for i in range(24)]}}})
def currency_string(amount, currency):
    return str(amount)
""", ["access_token=offline-test", "display_mode=category"], 36000),
}

with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    for name, (overrides, config, duration) in cases.items():
        app = tmp / name
        shutil.copytree(root / "apps" / name, app)
        path = next(app.glob("*.star"))
        source = path.read_text()
        for function in re.findall(r"^def (\w+)\(", overrides, re.M):
            source = source.replace("def " + function + "(", "def original_" + function + "(")
        source = source.replace('load("http.star", "http")', 'load("http.star", unused_http = "http")')
        source += '\ndef blocked_get(*args, **kwargs):\n    fail("unexpected network request")\n'
        source += overrides
        source += '\nhttp = struct(get = ' + ('test_get' if 'def test_get(' in overrides else 'blocked_get') + ')\n'
        if name == "bgghotness":
            source = source.replace('load("cache.star", "cache")', 'load("cache.star", unused_cache = "cache")')
            source += '\ncache = struct(get = test_cache_get)\n'
        path.write_text(source)
        for scale in (1, 2) if name == "ha_calendar" else (1,):
            subprocess.run([runtime, "render", str(path), *config, *(["-2"] if scale == 2 else []),
                            "--max-duration", "5s", "--output", str(tmp / "out.webp"),
                            "--metadata-output", str(tmp / "metadata.json"), "--silent"], check=True,
                           stdout=subprocess.DEVNULL)
            metadata = json.loads((tmp / "metadata.json").read_text())
            assert metadata["show_full_animation"], (name, metadata)
            assert 1 < metadata["frame_count"] <= 2000, (name, metadata)
            assert 5000 < metadata["animation_duration_millis"] <= 7200000, (name, metadata)
            if duration is not None:
                assert metadata["animation_duration_millis"] == duration, (name, metadata)
            assert (tmp / "out.webp").stat().st_size <= 2 * 1024 * 1024
        print(name + ": complete bounded content sequence")
