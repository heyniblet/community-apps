<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# Women's soccer tournament / league

Women's soccer displays upcoming / current / completed games for tourname / league you have selected

Displayed:

- Home / Away Teams & current record
- If future game: Date & Time of upcoming game
- If inprogress game:  Score & Time
- If past game:  Final Score

## Configuration
- Select League / Tournament to display.  Current Leagues / Tournament options are:
    * Australian A-League Women  ** Cavaet see below
    * CONCACAF W Championship
    * English Women's Champions League
    * English Women's FA Cup
    * English Women's Super League
    * She Believes Cup
    * United States NWSL
    * Women's International Friendly
    * Women's Olympics Tournament
    * Women's World Cup

- Which team to display first (home or away)
- Select display format type
- Select color for time
- Select time to display each score (this eliminates the mult-instance thing we've traditionally done)
- 12 hour vs 24 hour time & US vs Intl date format
- Select if you want to show a range of days forward / back instead of just the default API results & specify how many days forward and back.

## Caveat
For some reason, if you select Australian Women's A-Legaue, the API returns no data by default (vs all the other leagues).  If you do NOT select the option to filter by date range,  the app automatically looks 6 days ahead from today.

## Thanks

Thanks a lot to a bunch of folks who have worked on these various sports apps.  @LunchBox8484 is the original author of many of them.
Thanks to @jesushairdo for the new option to be able to show home or away team first.  Let's be more international :-)

## Screenshot

![screenshot](soccerwomens.gif)
![screenshot](soccerwomens2.gif)


### September 21 score-data resilience

Edwin adapted the missing-odds and series-summary fixes from [Luke Solomon’s upstream change](https://github.com/tronbyt/apps/commit/edf5e1f5cb7ff319e8d805ae6a6f7325b1a51cf2) across the score apps. Missing optional odds, series summaries, or notes no longer abort playback. Unavailable odds stay blank; scores and final status remain visible. Existing settings, game ordering, and card timing are preserved. Offline missing-field and full-sequence renders are covered by `tests/sports_playback.py`; this does not certify provider availability or physical display playback.

### Bundled pre-resized team logos (October 2026)

Downstream change, original authorship retained. The club crests and national
flags of every team ESPN lists for the 22 league and tournament options (the
`comps.json` list as of 12 October 2026, plus each competition's current
scoreboard), 557 URLs in all, are packaged in `images/logos/` at each size the
layouts draw them (16 for Team Colors and Black, 30, 32 for Horizontal, 16 for
Wide 3 and 9 for Wide 4), produced by the runtime's own nearest-neighbour
resize from the same source URLs. The files are stored in about 128 KB
`pack-NN.bin` shards; `logos.star` records each source URL, its SHA-256 and the
byte range of each size, so a render reads only the shards it draws from. This
covers all 4 logo URLs production renders requested from 9 to 12 October 2026.
Regenerate or verify with `cd tools/lunchbox_logos && go run . -app soccerwomens [-check]`.

Retro, which draws no logos, no longer downloads a bundled one. A logo URL or
size missing from the bundle is still fetched as before. The Wikimedia
placeholder used for an empty ESPN logo (`1x1.png?src=soccerwomens`) returns
403 to the runtime's HTTP client and ESPN's `ncaa_football` placeholder returns
404, so neither is bundled and those renders behave exactly as before. Settings,
ordering, timing and artwork are unchanged; a logo ESPN later redraws at the
same URL stays at the bundled version until the bundle is regenerated.

Validation: `tools/lunchbox_logos/parity.py` rendered the previous and new
source from the same recorded responses (the live scoreboards of every option)
for every league with every layout, plus calendar windows, team order, date
formats and team-colour samples, at three pinned times and at 1x and 2x:
804 of 804 successful WebP outputs were byte-identical, with no request outside
the recording. The other 132 of the 936 renders failed identically in both
versions: 108 on the Wikimedia 403 above and 24 on Wide 3/4 penalty-shootout
finals (`string + int`); neither is changed here.
`tools/lunchbox_logos/verify.py` rendered all 2228 bundled URL and size pairs
identically to the freshly downloaded originals. The sports playback and
sequence tests, `niblet check`, format and lint also pass. Physical-screen
playback is not covered by these checks.

### Penalty shootouts and teams without a record (October 2026)

Downstream change, original authorship retained. Wide 3 and Wide 4 failed on
every penalty-shootout final (`unknown binary op: string + int`). The feed
gives a non-zero shootout tally as a number; the status now converts both
tallies to strings. In NCAA soccer an opponent from outside Division I can
have no `records` while the home team has one (Central Baptist at
Arkansas-Pine Bluff, 1 September 2026). Before kickoff such a match failed
every render of the other layouts with `key "records" not in dict`, and a
postponed match read records unchecked. A team without a record now shows no
record (blank, as when the home team has none). Nothing else changes.

Validation: `tools/lunchbox_logos/parity.py`-style renders of the previous and
new source from the same recorded responses (every league option and layout,
calendar windows, team order and date formats, three pinned times, 1x and 2x),
for two recordings of 12 October 2026. All 1608 successful renders of the
previous source were byte-identical. 48 that failed before on shootout finals
now render, none empty. The remaining 216 fail identically in both versions on
the Wikimedia 403 placeholder, unchanged here. No request fell outside the
recording. `tests/scoreboard_missing_records.py` renders the Central Baptist
match, rewritten to pre-game, and a recorded shootout final in every layout;
both crashed the previous version. Physical-screen playback is not covered by
these checks.

### Teams without a crest (November 2026)

Downstream change, original authorship retained. A team ESPN lists without a
logo was drawn from a Wikimedia 1x1 placeholder, which Wikimedia now answers
with 403 ("Please set a user-agent"), so the render failed (eng.fa and
afc.champions in production). The placeholder is now an embedded transparent
1x1 PNG and is never fetched. Validation: production eng.fa and
afc.champions settings render in every layout (wide layouts at 2x); the
previous source failed with the 403. Physical playback is not covered.
