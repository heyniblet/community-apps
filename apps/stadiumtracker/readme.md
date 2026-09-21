<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Stadium Tracker for Tidbyt

Stadium Tracker

This application will let you track which NFL stadiums and MLB parks you have visited, and also display the ones you have yet to visit.

Use it to plan your summer visits and see if there is a park near your destination to pick up for your bucket list!

The outline of the USA appears in green. It will display based on coordinates in a random pattern (top to bottom, or left to right, or top left to top right, or reverse)

Pick the league you are interested in, then mark the locations of all the stadiums you've been to. The USA outline will appear, then all locations in the selected league appear in dull yellow in a different order (By location, by team name, by team location etc.)

The locations you have visited as indicated in the settings will then appear in bright yellow, then blink. They'll blink once more before the display repeats.

![Stadium Tracker for Tidbyt](stadiumtracker.webp)
