<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Indycar Next Race and Standings

Indycar displays next race details and current standings details for NTT Indycar or Indy NXT Series

Track images are by @samhi113

Displayed:

- Next Race
  - Series Title w/corresponding background
  - Race Name
  - Track Name
  - Date / Time (localized)
  - US TV channel showing the race
  - Image of the track

- Driver Standings
  - Series Title w/corresponding background
  - Top 12 drivers in 3 panels
  - includes position, name and points

## Configuration
- Select series to display (NTT Indycar series is default)
- Select Display Type (next race or standings)
- Select Text Color
- For Next Race select date/time format

## Thanks
- Thanks a lot to @AMillionAir as the original maker of the [Forumla 1 applet](../formula1/).
- Track images are provided by @samhi113

## Screenshot

![](indycar-nextrace.gif) ![](indynxt-standings.gif)
