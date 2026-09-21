<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# WNBA Scores for Tidbyt

Displays live WNBA scores and gambling odds for upcoming games. Updated every 2 minutes. No API key required.

![WNBA Scores for Tidbyt](screenshot.png)



### September 21 score-data resilience

Edwin adapted the missing-odds and series-summary fixes from [Luke Solomon’s upstream change](https://github.com/tronbyt/apps/commit/edf5e1f5cb7ff319e8d805ae6a6f7325b1a51cf2) across the score apps. Missing optional odds, series summaries, or notes no longer abort playback. Unavailable odds stay blank; scores and final status remain visible. Existing settings, game ordering, and card timing are preserved. Offline missing-field and full-sequence renders are covered by `tests/sports_playback.py`; this does not certify provider availability or physical display playback.
