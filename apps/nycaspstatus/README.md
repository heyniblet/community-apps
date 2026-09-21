<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NYC ASP Status
This app displays the current status of New York City alternate side parking (street cleaning) rules, which may be suspended due to inclement weather (such as snow removal operations) or because of observed legal or religious holidays.

![screenshot](screenshot.jpg)

- The street cleaning logo on the left is red when ASP rules are in effect, and turns green when rules are suspended or not in effect.
- The following day's status is shown after 3PM EST/DST.
- The app can be configured to only be shown when alternate side parking rules are suspended or not in effect.

Data is sourced from the NYC 311 API (https://api-portal.nyc.gov/)
