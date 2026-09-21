<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# SailGP Next Race and Standings

SailGP displays next race details and current standings details.

Displayed:

- Next Race
  - Series Title w/corresponding background
  - Next Race Name
  - Next Race Location
  - Dates of races (2 days of racing)
  - Scrolling list of standings w/Points

- Large Format Standings w/Flags
  - Scroll through standings showing country flag, position & current points

## Configuration
- Select Display Type (next race or standings)
- Select Standings Color
- Select Next Race Color (if next race display)
- Select date/time format (if next race display)

## Screenshot

![](sailgp.webp)

## Data source

Standings, schedule and flags are produced by
[tidbyt-data-scripts](https://github.com/jvivona/tidbyt-data-scripts) and read
from the public [tidbyt-data](https://github.com/jvivona/tidbyt-data) repo
(`sailgp/standings.json`, `sailgp/nri.json`, `sailgp/flags.json`), so the device
never hits SailGP directly. The standings count is not hard-coded — the display
pages through however many teams are racing.
