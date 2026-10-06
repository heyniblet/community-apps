<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# MLB Scores for Tidbyt

Displays live MLB scores and gambling odds for upcoming games. No API key required.

Team focus shows the latest completed game plus the next scheduled game in the yesterday-through-next-six-days window, or the live game while one is in progress. All-teams mode plays the complete scoreboard. Card duration is independent of the hosting scheduler’s refresh interval; scoreboard responses are cached for 60 seconds.

![MLB Scores for Tidbyt](screenshot.png)



### September 21 score-data resilience

Edwin adapted the missing-odds and series-summary fixes from [Luke Solomon’s upstream change](https://github.com/tronbyt/apps/commit/edf5e1f5cb7ff319e8d805ae6a6f7325b1a51cf2) across the score apps. Missing optional odds, series summaries, or notes no longer abort playback. Unavailable odds stay blank; scores and final status remain visible. Existing settings, game ordering, and card timing are preserved. Offline missing-field and full-sequence renders are covered by `tests/sports_playback.py`; this does not certify provider availability or physical display playback.

Live score replacement between cards is enabled with League Name or Game Info headers. Current Time headers keep complete snapshot playback: their predicted per-card clocks must not be rebased midway through a sequence. Refresh scheduling remains independent of playback in all modes.

### Timezone setup (local change)

The Location prompt is replaced by an optional **Timezone** field. Leave it
blank to follow the device timezone, or enter an IANA name such as
`America/New_York` or `Europe/London`. A host that supplies no device timezone
uses UTC. Coordinates and city lookup are no longer needed.

Cloud's reviewed upgrade copies the old location timezone into the new field,
preserving saved choices and the previous New York default when no location was
saved. Clear the migrated field to follow the device instead. The app also
accepts a legacy location in direct render configurations when the new field
is absent. Teams, styling, ordering, card timing and refresh behavior are unchanged.
This requires a new catalog release and configuration migration; it is not live.

Validation: all 12 timezone/schema cases and the existing full sports playback
regression passed with the card-capable Niblet runtime, with network access
denied. Formatter and lint passed. Live provider and physical-screen checks
were not repeated for this setup-only change.

## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

### Bundled pre-resized team logos (October 2026)

Downstream change, original authorship retained. Every team logo the app
already drew from ESPN (and the transparent placeholder) is packaged in
`images/logos/` at each size the layouts draw it (16 and the magnified sizes, 30 and 32 pixels), produced by
the runtime's own nearest-neighbour resize from the same source URLs;
`logos.star` lists each source URL and its SHA-256. Regenerate or verify with
`cd tools/lunchbox_logos && go run . -app mlbscores [-check]`. An all-teams render
now makes one request (the scoreboard, cached 60 seconds) instead of up to
31. Team focus still requests each day of its calendar window (cached 60 seconds), because ESPN does not return complete results for a date range. Retro and Stadium no longer download logos they never
draw, and the clock is read only for team focus, the Current Time header, or
when a pre-game card compares its kickoff date with today. A logo URL or size
missing from the bundle is still fetched from ESPN as before. Settings,
ordering, timing and artwork are unchanged; a logo ESPN later redraws at the
same URL stays at the bundled version until the bundle is regenerated.

Validation: `tools/lunchbox_logos/parity.py` rendered the previous and new
source from the same recorded responses (live postseason feed, all teams from two August dates, and an October date) across every layout,
header, pre-game mode, team focus sample and timezone at three pinned times:
315 of 315 WebP outputs were byte-identical, with no request outside the
recording. The sports playback, timezone and sequence tests also pass.
Physical-screen playback is not covered by these checks.
