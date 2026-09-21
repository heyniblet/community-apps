<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NFL Scores for Tidbyt

Displays NFL scores and gambling odds for upcoming games. No API key required.

Plays every game returned by ESPN in feed order, matching the original Lunchbox app. Team selection filters that same feed. Each card lasts 3–15 seconds (default 5); full-animation playback finishes the sequence before rotating to another app.

Scoreboard responses are cached for 60 seconds. The hosting scheduler controls refresh frequency independently of card speed and total playback duration. Content expiry allows enough time to finish the sequence.

![NFL Scores for Tidbyt](screenshot.png)
