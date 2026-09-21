<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Kiel Harbor Ferry Departure Times Applet for Tidbyt

Displays the next Kiel harbor ferry departure and wait time. Any ferry stop and direction from
the [Kiel harbor ferry system](https://www.sfk-kiel.de) may be configured.

Departures are retrieved from the Deutsche Bahn public API via the 
[DB REST wrapper](https://github.com/derhuerst/db-rest) hosted publicly
at https://v5.db.transport.rest/.

![Kiel Harbor Ferry Departure Times Applet for Tidbyt](kiel_ferry.gif)


