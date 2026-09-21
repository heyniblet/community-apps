"""Run: python3 tests/ncaaf_score_dates.py /path/to/niblet (no network)."""
from datetime import date, timedelta
from pathlib import Path
import json
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())


def event(identity, state, team="TEST"):
    return {"id": identity, "status": {"type": {"state": state}}, "competitions": [
        {"competitors": [{"team": {"id": team}}, {"team": {"id": "OTHER"}}]}
    ]}


with tempfile.TemporaryDirectory() as temporary:
    for league in ("ncaaf",):
        source = (root / f"apps/{league}scores/{league}_scores.star").read_text()
        source = source.replace("def main(config):", "def app_main(config):", 1)
        source = source.replace("def get_cachable_data(", "def original_get_cachable_data(", 1)
        # Replace only HTTP access; execute the actual app's date and selection logic.
        source += '''\ndef get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    query = url.split("?", 1)[1]
    if query not in FIXTURES:
        fail("unexpected scoreboard query: " + query)
    return json.encode({"events": FIXTURES[query]})
'''
        # Year rollover and both US DST transitions, near local midnight.
        for day, instant in (
            (date(2026, 1, 1), "2026-01-01T05:30:00Z"),
            (date(2026, 3, 9), "2026-03-09T04:30:00Z"),
            (date(2026, 11, 2), "2026-11-02T05:30:00Z"),
        ):
            fixtures = {"limit=300&groups=80": [event("all-a", "pre"), event("all-b", "pre", "ELSE")]}
            for offset in range(-1, 7):
                events = [event(str(offset), "post", "HISTORY")]
                if offset == -1:
                    events += [event("previous", "post"), event("old-live", "post", "LIVE")]
                if offset == 0:
                    events += [event("next", "pre"), event("live", "in", "LIVE")]
                if offset == 6:
                    events += [event("later", "pre"), event("late", "pre", "LATE")]
                for item in events:
                    item["date"] = (day + timedelta(days=offset)).isoformat() + "T12:00:00Z"
                fixtures["limit=300&groups=80&dates=" + (day + timedelta(days=offset)).strftime("%Y%m%d")] = events
            expected = ["previous", "next"]
            history = [str(n) for n in range(-1, 7)]
            checks = f'''
FIXTURES = json.decode({json.dumps(json.dumps(fixtures))})
def main(config):
    now = time.parse_time("{instant}").in_location("America/New_York")
    for team, expected in [
        ("all", ["all-a", "all-b"]), ("", ["all-a", "all-b"]),
        ("TEST", {json.dumps(expected)}), ("HISTORY", {json.dumps(history)}),
        ("LIVE", ["live"]), ("LATE", ["late"]), ("MISSING", []),
    ]:
        actual = [score["id"] for score in get_scores(API + "?limit=300&groups=80", now, team)]
        if actual != expected:
            fail("%s: expected %s, got %s" % (team, expected, actual))
    return [render.Root(child = render.Text("OK"))]
'''
            path = Path(temporary) / f"{league}.star"
            path.write_text(source + checks)
            subprocess.run([runtime, "render", str(path), "--output", str(Path(temporary) / "test.webp"), "--silent"], check=True)
print("NCAAF: daily queries, team selection, empty results, year rollover and DST passed")
