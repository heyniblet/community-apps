<!-- community-maintenance:start -->
## Community maintenance

Imported from [Tronbyt apps](https://github.com/tronbyt/apps/tree/32af8b9a/apps/cfbplaybyplay) on October 6, 2026. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime.
<!-- community-maintenance:end -->

## FCS teams

Enter the team's ESPN abbreviation, such as `CCSU` for Central Connecticut.
The app checks the FCS scoreboard after the existing scoreboard searches miss.
Between games it can find an unranked team through ESPN's team directory and show
its record and next game. When multiple schools share an abbreviation, the app
requires a scoreboard or ranking match before choosing a school.

Existing installations keep their team and **Game day only** settings. Run
`python3 tests/cfb_fcs_coverage.py ../niblet-cli/niblet` from the repository root
to replay eight cases, including a live FCS game on both layouts, an empty-cache
idle card, and the FBS lookup. A live ESPN render showed the Duquesne at Central
Connecticut pregame card on November 21, 2026. Physical playback was not tested.
