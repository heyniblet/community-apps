<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NASCAR Next Race

NASCAR Next Race displays next race details, current standings details or playoff details for the series you select

Displayed:

- Next Race
  - Series Title w/corresponding background
  - Race Name
  - Track Name
  - Date / Time (localized)
  - US TV channel showing the race

- Standings (Driver / Owner / Manufacturer)
  - Series Title w/corresponding background
  - Top 9 drivers/owners/mfgs in 3 scrolling rows
  - includes position, name, points and wins
  - Owner Standings adds the car # in front of owner's name

- Playoffs (Driver Only)
  - Series Title w/corresponding background
  - Top 9 drivers
  - includes position, name, PLAYOFF points and CURRENT PLAYOFF ROUND wins

## Configuration
- Select series to display (cup series is default)
- Select Display Type (next race or standings)
- Select Text Color
- For Next Race select display option to fade or slide and date/time format

## Thanks

Thanks a lot to @AMillionAir as a lot of the original version of this applet was based on the work he did on the [Forumla 1 applet](../formula1/).

## Screenshot

![](nascarnextrace-nri.gif) ![](nascarnextrace-ply.gif)
![](nascarnextrace-drv.gif) ![](nascarnextrace-own.gif)
![](nascarnextrace-mfg.gif)
