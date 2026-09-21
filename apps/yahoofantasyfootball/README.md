<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Yahoo Fantasy Football App

Shows information from a Yahoo Fantasy Football league. The app can be modified to either scroll through the current standings or show the current matchup for the logged in user.

## Setup

1. Login with your Yahoo credentials to grant the application permission to access your Fantasy Football data (app is read only)
2. Choose your league from the drop down list.
3. Choose whether scores or standings should be display

## Screenshot

![](https://github.com/tidbyt/community/blob/main/apps/yahoofantasyfootball/yahoofantasynfl.gif)
