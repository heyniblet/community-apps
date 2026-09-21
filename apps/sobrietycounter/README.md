<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Sobriety Counter

Celebrate your sobriety by counting how many days since your sober date! You can choose to specify the substance or behavior your are abstaining from (or enter your own), or leave it blank.

#### With substance/behavior

![](sobriety_counter_with_addiction.gif)

#### Without substance/behavior

![](sobriety_counter_without_addiction.gif)

## TODO / Possible enhancements

- [ ] Change the date/time picker to just a date picker, if one ever becomes available
- [ ] Make it look prettier (add fireworks, colored text, etc.)
- [ ] Show counter in something other than days (months, years)?
