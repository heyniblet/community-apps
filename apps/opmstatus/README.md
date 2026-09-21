<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# OPM Status for Tidbyt

Displays the current [OPM Status](https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/current-status/), e.g. the Office of Personnel Management status, which is used by federal employees to know if the normal working conditions have been changed by inclement weather, health hazards, or other alerts. Updates every 5 minutes. No API key required.

Uses the OPM Status JSON feed at [https://www.opm.gov/json/operatingstatus.json](https://www.opm.gov/json/operatingstatus.json) for updates.

![OPM Status for Tidbyt](screenshot.gif)
