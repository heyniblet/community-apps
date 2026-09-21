<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# PUBG Stats
PUBG Stats displays a selected lifetime statistic for a PUBG player. It uses the official [PUBG Developer API](https://documentation.pubg.com/en/getting-started.html), which requires a key from [developer.pubg.com](https://developer.pubg.com/).

Stats displayed are totaled together from all game modes (solo/duo/squad/tpp/fpp) on the selected platform.

![GIF Preview of PUBG Stats App](https://user-images.githubusercontent.com/14130953/182990241-811f491e-05c0-4b28-b547-fc7f831d0010.gif)

## Displayable Stats
- Chicken Dinners (Wins)
- Kills
- Headshots
- Assists
- Enemies Knocked
- Damage Dealt
- Teammates Revived
- Teamkills
- Suicides
- Heals Used
- Boosts Used
- Weapons Picked Up
- Kills with Vehicles
- Vehicles Destroyed
- Distance in Vehicles
- Distance Swam
- Distance Walked
- Time Survive
- Days Played
- Rounds Played
- Top 10s
- Matches Lost
- Most Kills in a Match
- Max Kill Streak
- Furthest Kill Distance
- Longest Time Survived in a Match
- Past Day's Wins
- Past Day's Kills
- Past Week's Wins
- Past Week's Kills

## Troubleshooting
If the player can not be found please remember that the player name is case sensitive and specific to the gaming platform selected.
