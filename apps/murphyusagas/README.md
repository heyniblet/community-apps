<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Murphy USA Gas Applet 

Displays current gas prices for a selected [Murphy USA](https://www.murphyusa.com) gas station.

## Features

* Using an entered address, choose from a list of the nearest 10 stations within 20 miles of the address (if no stations found - will show "No Station within 20 miles")
* The applet will display the prices (as availble at the station) for Regular (R), Premium (P), and Diesel (D)
* Choose the color scheme for gas prices: all white, red for gas and green for diesel, or green for gas and red for diesel
* Device will display OPEN or CLOSED (based on current device time) followed by the open and close times for today
* Open/Close hours will reference the station's local operating hours

## Thanks

Thanks a lot to @dja852 for [Costco Gas](../costcogas/) as it was the starting point for this app.

## Screenshot

![](murphygasclosed.jpg)
![](murphygasopen.jpg)
