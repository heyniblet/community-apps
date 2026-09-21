<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# VBB Berlin — Tidbyt app

Live departures from any stop in the VBB (Berlin/Brandenburg) public-transport
network on a [Tidbyt](https://tidbyt.com) display.

Each row shows the line (color-coded by mode), the direction (scrolling if it
overflows), and the ETA in minutes. The ETA itself is color-coded:

- red — `now` or ≤ 2 min (run!)
- yellow — 3 to 10 min
- green — more than 10 min

Data is fetched from the public
[v6.vbb.transport.rest](https://v6.vbb.transport.rest/api.html) API. No API key
required.

## Configuration

| Field | Description |
|-------|-------------|
| `stop_id` | VBB stop ID. In the schema UI, type a station name and pick from the autocomplete. When pushing manually, pass the raw ID (e.g. `900135001`). |
| `mode` | One of `all`, `suburban` (S-Bahn), `subway` (U-Bahn), `tram`, `bus`, `regional` (incl. express), `ferry`. Defaults to `all`. |

Find stop IDs with the locations endpoint:

```bash
curl -s "https://v6.vbb.transport.rest/locations?query=alexanderplatz&results=5&poi=false&addresses=false" \
  | jq '.[] | {id, name}'
```
