<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Tidbyt Zmanim App

Display Jewish prayer times (zmanim) on your Tidbyt device. Shows important daily prayer times based on your location.

## Features
- Shows all important daily zmanim (prayer times)
- Customizable by ZIP code
- Clear display with yellow time highlights
- Automatic vertical scrolling
- Includes:
  - Dawn (Alot)
  - Misheyakir
  - Sunrise
  - Last Shema
  - Last Shacharit
  - Midday
  - Mincha Gedolah
  - Mincha Ketanah
  - Plag Hamincha
  - Sunset
  - Nightfall
  - Midnight

## Configuration
- ZIP Code: Enter your local ZIP code for accurate times
- Scroll Speed: Adjust how fast the times scroll

## Installation
1. Find "Zmanim" in the Tidbyt app store
2. Click Install
3. Enter your ZIP code
4. Push to your device

## Data Source
Times provided by Chabad.org's Zmanim API.

## Credits
Author: Shimon Savitsky
Data: Chabad.org
