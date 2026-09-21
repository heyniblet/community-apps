<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Buienradar Applet for Tidbyt

Shows the buienradar of Belgium or The Netherlands.

Note: temperatures are in Celcius and cannot be changed.

Data provided by [Buienradar](https://buienradar.nl).
Buienradar is a brand of RTL Nederland.


## Radar
Radar shows Belgium or Netherlands map with on top the rain radar.

## Today
Shows the current weather conditions in detail of the provided location.
The high and low temperatures are displayed, as well as the wind speed in Beaufort and wind direction.
A weather ticker is displayed on the bottom.

## Forecast
Shows the forecast of the provided location.

## Rain graph
Shows the rain forecast in a graph. The grid shows on the x-axes the time and y-axes the amount of rain. The top bar is for heavy rain and the bottom means no rain. The bar in the middle is for "normal" rain.
