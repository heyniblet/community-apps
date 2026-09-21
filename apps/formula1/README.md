<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Forumla 1

Formula 1 displays current standings (driver & constructor) & next race info depending on your preference

Displayed:

- Next Race Info
  - Race Location
  - Visual of the track
  - Date & Time of the Race
  - Race Number

- Constructor Standings
  - Top 3 Constructors with Logo & Current Points

- Driver Standings
  - Top 3 Driver names with Points

## Configuration
- Display option (Next Race, Driver Standings, Constructor Standings)
- If displaying Next Race, you can select Date and Time Format 

## Screenshot

![](nextrace.jpg)
![](driver.jpg)
![](constructor.gif)
