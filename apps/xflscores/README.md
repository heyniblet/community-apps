<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# XFL Scores for Tidbyt

Displays live XFL scores and gambling odds for upcoming games. Updated every 2 minutes. No API key required.

![XFL Scores for Tidbyt](screenshot.png)



### September 21 score-data resilience

Edwin adapted the missing-odds and series-summary fixes from [Luke Solomon’s upstream change](https://github.com/tronbyt/apps/commit/edf5e1f5cb7ff319e8d805ae6a6f7325b1a51cf2) across the score apps. Missing optional odds, series summaries, or notes no longer abort playback. Unavailable odds stay blank; scores and final status remain visible. Existing settings, game ordering, and card timing are preserved. Offline missing-field and full-sequence renders are covered by `tests/sports_playback.py`; this does not certify provider availability or physical display playback.

Live score replacement between cards is enabled with League Name or Game Info headers. Current Time headers keep complete snapshot playback: their predicted per-card clocks must not be rebased midway through a sequence. Refresh scheduling remains independent of playback in all modes.

## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

### Bundled pre-resized team logos (October 2026)

Downstream change, original authorship retained. Every team logo the app
already drew from ESPN (and the transparent placeholder) is packaged in
`images/logos/` at each size the layouts draw it (compact sizes, 30 and 32 pixels), produced by
the runtime's own nearest-neighbour resize from the same source URLs;
`logos.star` lists each source URL and its SHA-256. Regenerate or verify with
`cd tools/lunchbox_logos && go run . -app xflscores [-check]`. An all-teams render
now makes one request (the scoreboard, cached 60 seconds) instead of up to
9. Team focus still requests each day of its calendar window separately (cached 60 seconds), as before, so its results stay complete. Retro and Stadium no longer download logos they never
draw, and the clock is read only for team focus, the Current Time header, or
when a pre-game card compares its kickoff date with today. A logo URL or size
missing from the bundle is still fetched from ESPN as before. Settings,
ordering, timing and artwork are unchanged; a logo ESPN later redraws at the
same URL stays at the bundled version until the bundle is regenerated.

Validation: `tools/lunchbox_logos/parity.py` rendered the previous and new
source from the same recorded responses (live feed and all teams from four 2023 dates) across every layout,
header, pre-game mode, team focus sample and timezone at three pinned times:
222 of 222 WebP outputs were byte-identical, with no request outside the
recording. The sports playback, timezone and sequence tests also pass.
Physical-screen playback is not covered by these checks.
