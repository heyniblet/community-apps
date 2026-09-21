<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Surf Forecast App for Tidbyt

Displays the day's surf forecast using data provided by the Surfline API.

Data displayed includes:
  - Spot name
  - Current surf height, wind speed, and direction
  - Sunrise and sunset times (the lighted background of the app)
  - Surf forecast through the day over 8 intervals:
    - Overall surfline rating
    - Min surf height
    - Max surf height

![Screenshot of the Surf Forecast app for Tidbyt](screenshot.png)