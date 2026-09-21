<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# PurpleAir for Tidbyt

PurpleAir displays an estimate of the air quality index (AQI) using the specified [PurpleAir](https://www.purpleair.com) sensor. The US EPA method is used to calculate the index. It is updated every 30 minutes. The estimate should be very close or exactly match the index shown for the sensor on the [PurpleAir map](https://map.purpleair.com/1/mAQI/a0/p604800/cC5?select=33997#15.38/37.828489/-122.42342). Obtain a sensor ID for a sensor near you using the PurpleAir map.

An API key is required to fetch sensor data from the PurpleAir API. Please get your API key from the [PurpleAir develop site](https://develop.purpleair.com/sign-in?redirectURL=%2Fkeys).

![PurpleAir for Tidbyt](screenshot.png)