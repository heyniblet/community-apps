<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

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
