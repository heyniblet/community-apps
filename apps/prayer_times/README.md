<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Islamic Prayer Times

This app displays the prayer times for today's date based on the user location and the method of prayer time calculation. The location, timezone and prayer time calculation method are configurable in Tidbyt app based on the user input.

![](prayer_times.gif)

## Color Scheme

The day's prayer times are shown in the lower half of the screen and colored in white. The current prayer name is highlighted in yellow in the lower half of the screen. The upper half of the screen shows the remaining time till the next prayer and its colored in green.

## Day Icon

The Sun/Moon icon in the top left is indicating the current time of the day either Day or Night.

## Configuration

The Tidbyt app lets you set the location that prayer times will calculated based on it. Also you can set the method of the prayer times calculation, you can pick it from dropdown list.

## Disclaimer

This app shows the prayer times based on [Adhan API's](https://aladhan.com/).

It was written as a fun exercise because I often need to check prayer times.

## Contact
[![Mail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:eslammoh.ce@gmail.com)