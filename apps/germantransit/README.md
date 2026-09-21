<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# German Transit

German Transit displays upcoming public transportation departures for the selected station. Modalities include U-Bahn, S-Bahn, Tram (Straßenbahn), Bus, Regional Train, and ICE Trains.  The data is sourced from Verkehrsverbund Rhein-Neckar (VRN), however the user can select any station in Germany (and even some neighboring cities, e.g. Strasbourg).

## Display

- Up to 8 upcoming departures, 2 at a time

## Configuration
- Select train station based on specified location
- If desired, select offset time to filter out departures within the selected number of minutes
- Toggle on/off specific modes of transportation

## Screenshot

![](german_transit.gif)