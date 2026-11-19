<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# Track single soccer team across all global tournaments / leagues they are playing in

Show upcoming / current / future game for a single soccer team across all leagues / tournaments they play in - one app tracks the team everywhere.  Handles all ESPN API leagues / tournaments.
Approx 3000 teams globally are in this app (2500 men's teams & 500 women's teams - including professional, international and college)

Displayed:

- Home / Away Teams & current record (if applicable for current league / tournament)
- Game's League / Tournament abbreviation
- If future game: Date & Time of upcoming game
- If inprogress game:  Score & Time
- If past game:  Final Score  (as per ESPN API - scores flip over to next game at 1AM US ET - future version coming to assist with this)

## Configuration
- Enter text to search team name (minimum 4 characters) - Women's teams are prefixed with a W & Men's with an M
- Which team to display first (home or away)
- Select display format type
- Select color for time (uses new schema.Color)
- 12 hour vs 24 hour time & US vs Intl date format

## Thanks

Tons of thanks to @whyamihere/@rs7q5 for the API assistance - couldn't have gotten here without you
Thanks to @dinotash/@dinosaursrarr for making me think deep thoughts about connected schema fields & @matslina for setting me straight.
Of course - the original author of a bunch of this display code is @Lunchbox8484
Thanks to @jesushairdo for the option to be able to show home or away team first.  Let's be more international :-)

## Screenshot

![screenshot](soccersingle-score-1.jpg)
![screenshot](soccersingle-score-2.jpg)

## Schema Search for Teams
![screenshot](soccersingle-schema-teamsearch-3.jpg)
![screenshot](soccersingle-schema-teamsearch-2.jpg)

### Bundled pre-resized team logos (October 2026)

Downstream change, original authorship retained. Soccer Single follows one team
in any competition, so it has no league list of its own. It bundles the club
crests and national flags of every team ESPN lists for the league and
tournament options of Mens Soccer and Womens Soccer (69 competitions as of
12 October 2026, plus their current scoreboards) and five further crests
production renders requested, 1219 URLs in all. They are in `images/logos/` at
each size the layouts draw them (16, 30 and 32 pixels), produced by the
runtime's own nearest-neighbour resize from the same source URLs, and stored in
about 128 KB `pack-NN.bin` shards; `logos.star` records each source URL, its
SHA-256 and the byte range of each size. This covers all 50 logo URLs
production renders requested from 9 to 12 October 2026. Regenerate or verify
with `cd tools/lunchbox_logos && go run . -app soccersingle [-check]`.

Retro, which draws no logos, no longer downloads a bundled one. Any other team,
URL or size is still fetched as before. The Wikimedia placeholder used for a
missing logo returns 403 to the runtime's HTTP client and is not bundled, and
one crest ESPN serves as a GIF (`soccer/500/635.png`) is left to the network.
Team colour lookups are unchanged. Settings, timing and artwork are unchanged;
a logo ESPN later redraws at the same URL stays at the bundled version until
the bundle is regenerated.

Validation: `tools/lunchbox_logos/parity.py` rendered the previous and new
source from the same recorded responses for the 34 club team IDs whose crests
production requested, in every layout with both team orders, at three pinned
times: 420 of 420 WebP outputs were byte-identical, with no request outside the
recording. `tools/lunchbox_logos/verify.py` rendered all 3657 bundled URL and
size pairs identically to the freshly downloaded originals. `niblet check`,
format and lint also pass. Physical-screen playback is not covered by these
checks.

### Games without a league record (November 2026)

Downstream change, original authorship retained. ESPN omits `record` from the
team response for competitions without standings, such as FIFA friendlies and
domestic cups. The pre-game and postponed cards read
`team["record"]["items"]` and failed with `key "record" not in dict`, so a
team whose next game was in such a competition stopped updating (reported for
USA, team 660, before its 13 December 2026 friendly). The record line is now
left blank in that case, as it already was when `items` was missing.

Validation: `python3 tests/soccersingle_no_record.py pixlet` renders a
recorded USA team response in all four layouts; it fails on the previous
source with the production error. Physical-screen playback is not covered.

### No scheduled game, or no crest (November 2026)

Downstream change, original authorship retained. ESPN omits `nextEvent` when
a team has no scheduled game (national teams between windows, clubs in the
off-season); the app failed with `key "nextEvent" not in dict` instead of
skipping. It now skips the render, as it already did for an empty list. A team
without crests now draws an embedded transparent placeholder instead of
fetching a Wikimedia image that returns 403, and an empty `logos` list is
treated as missing. `tests/soccersingle_no_record.py` now also renders
without crests (any request outside ESPN fails it) and without `nextEvent`
(expects zero frames); the previous source fails the crest case. Production
team IDs 476, 205, 21422 and 19995 now skip instead of failing.
