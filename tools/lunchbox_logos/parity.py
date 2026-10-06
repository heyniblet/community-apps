"""Byte-identical render check for the bundled LunchBox league logos.

Usage, from the repository root:

  python3 tools/lunchbox_logos/parity.py RUNTIME APP --snapshots DIR [--base REV] [--record]

Renders apps/APP at a base revision (default origin/main) and in the working
tree with `render --input-snapshot`, so both read the same recorded responses,
and requires identical WebP bytes for every configuration, time and scale in
the matrix. RUNTIME must support --input-snapshot, --metadata-output and --now.

--record builds DIR/APP/<scenario>/ (index.json plus bodies named by SHA-256):
the base version is rendered repeatedly and every request it makes that the
snapshot lacks is fetched once and added, until it is served entirely from the
snapshot. Scenarios (see SCENARIOS below) are "live" (today's feeds) and, for
scoreboard apps, feeds for other dates served at the app's default scoreboard
URL, chosen so that every team (and so every bundled logo) and pre-game, live
and final cards are drawn. Later runs replay offline; any request either
version makes outside the snapshot fails the check.

Prints, per app, the number of identical renders and the metadata deltas
(inputs, reads.time) between the two versions.
"""
import argparse
import concurrent.futures
import hashlib
import io
import itertools
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request

root = Path(__file__).resolve().parents[2]
CONFIG = json.loads((root / "tools/lunchbox_logos/apps.json").read_text())
NOWS = ["2026-10-06T18:00:00Z", "2026-10-11T16:30:00Z", "2026-10-07T03:59:30Z"]
TIMEZONES = ["", "America/New_York", "America/Los_Angeles"]

# Extra scoreboard bodies (merged ESPN daily feeds) served at the default URL.
SCENARIOS = {
    "nflscores": {"week1": ["20250904", "20250907", "20250908"], "upcoming": ["20261011"]},
    "nhlscores": {"allteams": ["20260301", "20260302", "20260303"], "upcoming": ["20261010"]},
    "mlbscores": {"allteams": ["20260801", "20260802"], "postseason": ["20261006"]},
    "nbascores": {"allteams": ["20260301", "20260302", "20260303", "20260304"], "upcoming": ["20261021"]},
    "wnbascores": {"allteams": ["20260701", "20260702", "20260703", "20260705"]},
    "cflscores": {"allteams": ["20220804", "20220805", "20220806", "20220812", "20220813"], "upcoming": ["20261010"]},
    "mlsscores": {"allteams": ["20260801", "20260802", "20260815", "20260816"], "upcoming": ["20261018"]},
    "uflscores": {"allteams": ["20260328", "20260329", "20260404", "20260405"]},
    "xflscores": {"allteams": ["20230218", "20230219", "20230225", "20230226"]},
    "wbcscores": {"allteams": ["20260305", "20260306", "20260307", "20260308", "20260309"]},
    "mhkyscores": {"allteams": ["20260109", "20260110", "20260116", "20260117"]},
}


def sha(body):
    return hashlib.sha256(body).hexdigest()


class Snapshot:
    def __init__(self, directory):
        self.dir = Path(directory)
        index = self.dir / "index.json"
        self.entries = {e["url"]: e for e in json.loads(index.read_text())["entries"]} if index.exists() else {}

    def add(self, url, status, body):
        self.dir.mkdir(parents=True, exist_ok=True)
        (self.dir / sha(body)).write_bytes(body)
        self.entries[url] = {"url": url, "method": "GET", "status": status, "sha256": sha(body)}
        (self.dir / "index.json").write_text(json.dumps({"schema": "niblet.input-snapshot.v1", "entries": list(self.entries.values())}, indent=1))


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Go-http-client/1.1"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def merged_feed(league, dates):
    events, seen = [], set()
    doc = None
    for day in dates:
        status, body = fetch(f"https://site.api.espn.com/apis/site/v2/sports/{league}/scoreboard?dates={day}")
        assert status == 200, (league, day, status)
        doc = json.loads(body)
        for event in doc.get("events", []):
            if event["id"] not in seen:
                seen.add(event["id"])
                events.append(event)
    doc["events"] = events
    return json.dumps(doc).encode()


def render(runtime, main, out, config, now, scale, snapshot, metadata):
    args = [runtime, "render", str(main), "-o", str(out), "--now", now, "--metadata-output", str(metadata),
            "--timeout", "60s", "--silent"]
    if snapshot:
        args += ["--input-snapshot", str(snapshot)]
    if scale == 2:
        args.append("-2")
    args += [f"{k}={v}" for k, v in config.items()]
    result = subprocess.run(args, capture_output=True, text=True, env={**os.environ, "PIXLET_IMAGE_CACHE_DIR": ""})
    if result.returncode != 0:
        return None, result.stderr[-2000:]
    return json.loads(Path(metadata).read_text()), None


def base_copy(revision, app, destination):
    archive = subprocess.check_output(["git", "archive", revision, "apps/" + app], cwd=root)
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        tar.extractall(destination, filter="data")
    return destination / "apps" / app / CONFIG[app]["source"]


def options(runtime, main, field_id):
    schema = json.loads(subprocess.check_output([runtime, "schema", str(main)], stderr=subprocess.DEVNULL))
    for field in schema["schema"]:
        if field["id"] == field_id:
            return [o["value"] for o in field.get("options", [])]
    return []


def matrix(runtime, main, app):
    display_types = options(runtime, main, "displayType")
    tops = options(runtime, main, "displayTop")
    pregame = options(runtime, main, "pregameDisplay")
    teams = options(runtime, main, "selectedTeam") or options(runtime, main, "teamsOptions")
    configs = []
    # Every layout with every header.
    for display_type, top in itertools.product(display_types or [None], tops or [None]):
        configs.append({"displayType": display_type, "displayTop": top})
    # Pre-game variants on logo layouts.
    for display_type, pre in itertools.product(display_types[:3] or [None], pregame):
        configs.append({"displayType": display_type, "pregameDisplay": pre})
    # Team focus (including local and magnified logos) and timezones.
    focus = [t for t in teams if t not in ("all", "")]
    for i, team in enumerate(focus[:: max(1, len(focus) // 6)] + [t for t in ("IND", "LAR", "CAR", "NYG") if t in focus]):
        configs.append({"selectedTeam": team, "displayType": (display_types or [None])[i % max(1, len(display_types))],
                        "timezone": TIMEZONES[i % 3], "rotationSpeed": str(3 + i % 5)})
    for i, tz in enumerate(TIMEZONES[1:]):
        configs.append({"timezone": tz, "displayTop": "time" if "time" in tops else None, "displayType": (display_types or [None])[i]})
    return [{k: v for k, v in c.items() if v is not None} for c in configs]


def record(runtime, base_main, app, directory, configs):
    cfg = CONFIG[app]
    scenarios = {"live": None}
    if cfg["feed"] == "scoreboard":
        scenarios.update(SCENARIOS.get(app, {}))
    for name, dates in scenarios.items():
        snap = Snapshot(directory / app / name)
        if dates and not snap.entries:
            # Learn the default scoreboard URL from a live render, then serve the merged body there.
            meta, err = render(runtime, base_main, directory / "probe.webp", {}, NOWS[0], 1, None, directory / "probe.json")
            assert meta, err
            feed = next(i["url"] for i in meta["inputs"] if "/scoreboard" in i["url"] and "dates=" not in i["url"])
            snap.add(feed, 200, merged_feed(cfg["league"], dates))
        for _ in range(6):
            missing = set()
            # Team focus requests calendar windows, so discover them at every pinned time.
            probes = [(c, NOWS[0]) for c in configs[:: max(1, len(configs) // 12)]]
            probes += [(c, now) for c in configs if "selectedTeam" in c for now in NOWS]
            for config, now in probes:
                meta, err = render(runtime, base_main, directory / "probe.webp", config, now, 1, snap.dir if snap.entries else None, directory / "probe.json")
                if meta is None:
                    print(f"{app}/{name}: record render failed {config}: {err}", file=sys.stderr)
                    continue
                missing |= {i["url"] for i in meta["inputs"] if i["url"] not in snap.entries}
            if not missing:
                break
            for url in sorted(missing):
                snap.add(url, *fetch(url))
        print(f"{app}/{name}: {len(snap.entries)} recorded responses")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("runtime")
    parser.add_argument("apps", nargs="+")
    parser.add_argument("--snapshots", required=True, type=Path)
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--record", action="store_true")
    parser.add_argument("--jobs", type=int, default=8)
    args = parser.parse_args()
    runtime = str(Path(args.runtime).resolve())
    failed = False
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for app in args.apps:
            cfg = CONFIG[app]
            base_main = base_copy(args.base, app, tmp / "base")
            new_main = root / "apps" / app / cfg["source"]
            configs = matrix(runtime, base_main, app)
            if args.record:
                record(runtime, base_main, app, args.snapshots, configs)
            scenarios = sorted(p.name for p in (args.snapshots / app).iterdir() if (p / "index.json").exists())
            jobs = [(s, c, now, scale) for s in scenarios for c in configs for now in NOWS for scale in cfg["scales"]]

            def run(job, index):
                scenario, config, now, scale = job
                snap = args.snapshots / app / scenario
                out = {}
                for label, main_path in (("base", base_main), ("new", new_main)):
                    webp, meta = tmp / f"{app}-{index}-{label}.webp", tmp / f"{app}-{index}-{label}.json"
                    m, err = render(runtime, main_path, webp, config, now, scale, snap, meta)
                    if m is None:
                        return job, None, f"{label} failed: {err}"
                    offline = [i["url"] for i in m["inputs"] if i.get("source") != "snapshot"]
                    if offline:
                        return job, None, f"{label} requested outside snapshot: {offline[:3]}"
                    out[label] = (webp.read_bytes(), m)
                same = out["base"][0] == out["new"][0]
                return job, (same, out["base"][1], out["new"][1], len(out["base"][0])), None

            identical, empty, deltas = 0, 0, {}
            with concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
                for job, result, err in pool.map(lambda p: run(*p), [(j, i) for i, j in enumerate(jobs)]):
                    if err:
                        print(f"{app}: FAIL {job}: {err}")
                        failed = True
                        continue
                    same, mb, mn, size = result
                    if not same:
                        print(f"{app}: DIFFERENT WebP {job}")
                        failed = True
                        continue
                    identical += 1
                    empty += mb["frame_count"] == 0
                    key = (len(mb["inputs"]), mb["reads"]["time"], len(mn["inputs"]), mn["reads"]["time"])
                    deltas[key] = deltas.get(key, 0) + 1
            print(f"{app}: {identical}/{len(jobs)} renders byte-identical ({empty} empty) across {len(scenarios)} scenarios {scenarios}, "
                  f"{len(configs)} configs, {len(NOWS)} times, scales {cfg['scales']}")
            for (bi, bt, ni, nt), count in sorted(deltas.items()):
                print(f"{app}:   inputs {bi} -> {ni}, reads.time {bt} -> {nt}: {count} renders")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
