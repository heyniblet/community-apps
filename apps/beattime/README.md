<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Beat Time

Display the time in _.beats_, a decimal time format also known as [Swatch Internet Time](https://en.wikipedia.org/wiki/Swatch_Internet_Time)

## Configuration
- Toggle whether or not to display centibeats (fractions of a .beat) (Default: `True`)

## About Swatch Internet Time

Swatch Internet Time is a decimal time format where the day is divided into 1000 _.beats_. Each .beat lasts 86.4 seconds.

Midnight is defined as UTC+1, and there are no timezones, because there are no timezones on the Internet. 

The current time uses the notation `@XXX.yy`. 
- `XXX` is the current number of beats since midnight in UTC+1
- `yy` is the current number of _centibeats_ since the current .beat

Centibeats are not part of the original standard, but are included to provide something a little more animated.

## Screenshot
![](beat_time-1.png)
