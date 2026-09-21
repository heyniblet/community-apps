<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# DC (WMATA) Bus Arrival Times

This app utilizes an API provided by WMATA to display the next several bus arrival times for up to two user-specified DC Metro bus stops.

![render](./dc_bus_times.gif)

The desired bus stop(s) are specified using the 7-digit Bus ID Number displayed on the bus stop sign located at the bus stop (e.g. 1001155).  Bus ID #1 is required while Bus ID #2 is optional.  An online search of Bus ID numbers can also be made by visiting the following address:

https://gis.wmata.com/mbsi/default.htm#regID=1001011

Optional "Show Details" toggle allows detailed bus route information to be displayed as well as arrival time(s).


