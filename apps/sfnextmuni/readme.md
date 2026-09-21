<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# San Francisco NextBus Applet for Tidbyt

Displays predicted arrival times from the [NextBus](https://www.nextbus.com) API for [San Francisco Muni](https://www.sfmta.com/).

This app offers a number of options to customize the display:
* Show or hide the stop title
* Show or hide service messages by minimum priority
* Prediction text with destination, without destination, or minutes only.

Default display, without title or service messages, and with destination:

![Default display](default.gif)

With title and destination:

![With title and destination](withtitle.gif)

With title, destination and service messages:

![With title, destination and service messages](withmessages.gif)

Without destination:

![With title and service messages](nodestinations.gif)

Most compact predictions:

![Most compact predictions](compactpredictions.gif)