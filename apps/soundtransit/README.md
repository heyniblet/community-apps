<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Sound Transit Applet for Tidbyt

Displays up to 2 different stations in the Sound Transit Link Light Rail network and their associated upcoming trains on your Tidbyt.

Data is provided by the Sound Transit's OneBusAway instance. Docs:
* http://developer.onebusaway.org/modules/onebusaway-application-modules/current/api/where/index.html
* https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd

![Sound Transit Applet for Tidbyt](sound_transit.gif)
