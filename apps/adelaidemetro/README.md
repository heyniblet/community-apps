<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

Inspired by all the other great transit apps out there, I made one for my home town. I'd be surprised if anyone actually uses it though :)

You can choose from train, tram or bus services and select the station for train or stop for trams. For the bus, you will need to enter the Stop ID which you can get from the Adelaide Metro website - http://www.adelaidemetro.com.au or should be written on the stop sign itself. For the train, you will need to select the direction you are heading with service to Adelaide being the default.

You have a choice of showing the next arrivals at the stop/station over a certain time period (default option), or showing services for all routes for the selected stop/station for the next 120 mins.

Examples

Train 

![](adelaide_metro_train.gif)

Tram

![](adelaide_metro_tram.gif)

Bus

![](adelaide_metro_bus2.gif)
