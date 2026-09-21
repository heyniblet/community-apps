<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NEOTrack - Near Earth Object Tracker

Shows the closest upcoming object passing Earth within the next day according to NASA/JPL's documented [Close-Approach Data API](https://ssd-api.jpl.nasa.gov/doc/cad.html) and [Small-Body Database API](https://ssd-api.jpl.nasa.gov/doc/sbdb.html). The legacy API-key setting is retained so existing installations keep their configuration, but it is no longer sent anywhere.

![Screenshot](neotrack.gif)

Shows the following information:

In the lefthand pane:

- The known diameter in kilometres or metres, or absolute magnitude (`H`) when JPL has no measured diameter
- A green border denotes the object is safe, an orange border means it's potentially dangerous[^1]

Righthand pane:

- The official name of the asteroid
- `V`: The relative velocity in Kilometres per Second
- `D`: The closest approach distance in [Lunar Units (LU)](https://en.wikipedia.org/wiki/Lunar_distance_(astronomy))
- `O`: The asteroid's orbiting body

[^1]: A potentially hazardous object (PHO) is a near-Earth object whose orbit brings it within 4.7 million miles (7.5 million km) of Earth’s orbit, and is greater than 500 feet (140 meters) in size.
