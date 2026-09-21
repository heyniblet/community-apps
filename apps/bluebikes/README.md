<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Boston Bluebikes
Displays how many classic bikes, e-bikes, and docks are available at a Bluebikes stations. Data is from Bluebikes' [GBFS feed](https://bluebikes.com/system-data)

Enter the station ID from the public `station_information` GBFS feed. Existing
saved typeahead selections continue to work.

Based on the [Chicago Divvy App](https://github.com/tronbyt/apps/tree/main/apps/chicagodivvy) by @wilcot

![Alt text](bluebikes.webp? "Screenshot of Bluebikes App showing 7 classic bikes, 1 e-bike, and 7 docks")
