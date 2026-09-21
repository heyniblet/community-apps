<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Live cricket scores on your Tidbyt
- The app lets you select a team and display score of a live cricket game for your selected team.
- If no game in progress, it will automatically display a scorecard of recently completed match.
- If there was no recently completed game in the day range selected by user, it will display fixutre of an upcoming game for your team.

### Example: Scorecard of a recently completed game
![](past_result.gif)

### Example: Scorecard of a game in progress
![](live_match.gif)

### Example: Schedule of an upcoming game
![](next_match.gif)
