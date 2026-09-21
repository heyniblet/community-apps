<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# OverwatchMetaByt

A Tidbyt application that visualizes Overwatch 2 Meta statistics.

## App Configuration

### App Statistics

The app can display the following hero statistics in Overwatch 2:

- **Win Rate** (default): the rate that Overwatch 2 players win with these heroes.
- **Pick Rate**: the rate that Overwatch 2 players pick these heroes.

### Filters

The app can display the hero statistics using the following filters:

#### Platform

- **PC** (default): filter by PC players.
- **Console**: filter by console players.

#### Game Mode

- **Quickplay** (default): filter by data retrieved from quickplay games.
- **Competitive**: filter by data retrieved from competitive games.

#### Role

- **All** (default): include all the player roles.
- **Damage**: filter by damage players.
- **Tank**: filter by tank players.
- **Support**: filter by support players.

#### Skill Tier

- **All** (default): include all the player skill tiers.
- **Bronze**: filter by bronze players.
- **Silver**: filter by silver players.
- **Gold**: filter by gold players.
- **Platinum**: filter by platinum players.
- **Diamond**: filter by diamond players.
- **Master**: filter by master players.
- **Grandmaster**: filter by grandmaster players.

#### Time Window

- **All Time** (default): include data from all time windows.
- **This Week**: filter by statistics recorded this week.
- **This Month**: filter by statistics recorded this month.
- **Last 3 Months**: filter by statistics received within the last three months.
- **Last 6 Months**: filter by statistics received within the last six months.
- **Last Year**: filter by statistics received within the last year.

## Win Rate Example

![Win Rate](overwatch_meta_win_rate.webp)

## Pick Rate Example

![Pick Rate](overwatch_meta_pick_rate.webp)