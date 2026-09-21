<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# USGS Earthquakes Applet for Tidbyt

Displays up to three earthquakes that have occurred during the past 24 hours, based on a configurable location. Supports settings for what radius to check and what minimum magnitude to consider. Data is provided by the [USGS GeoJSON Summary Feed ](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php). Updated every five minutes.

![USGS Earthquakes Applet for Tidbyt](screenshot.gif)
