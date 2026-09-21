<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# San Francisco Bay Ferry Applet for Tidbyt

Displays next ferry departure times for [San Francisco Bay
Ferry](https://sanfranciscobayferry.com/) routes.

This app lets users select a route and direction and displays the next few
departure times. If there are no more departures today, it shows the times for
tomorrow (or the next day with service) instead.

This applet uses the [GTFS](https://gtfs.org/) data [published by San Francisco
Bay Ferry](https://sanfranciscobayferry.com/developers) for schedule
information. This data is only available as a ZIP file, so the current copy is
baked into the code.
