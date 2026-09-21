<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Weather Clock With Date OG

A faithful recreation of the original Tidbyt "OG" weather clock, rebuilt from a reference photo of the original device and later cross-checked against the original app's source for exact font and layout details.

Shows the time (with a blinking colon separator), a weather icon, temperature, and humidity, with an optional day-of-week and date column. Includes a dimmed, clock-only night mode for a configurable overnight window.

## Data

Weather comes from either:

- **National Weather Service** (default) — US locations only, no API key required.
- **OpenWeather** — works globally, requires a free API key.

## Configuration

- Location, 12/24-hour clock, temperature units (imperial/metric)
- Time, temperature, and humidity colors
- Show/hide temperature unit suffix and day/date column
- Blinking colon toggle
- Night mode with configurable start/end time (HHmm)

## Notes

- Built-in `5x8`/`6x13` font digits for `0` and `9` render narrower than other digits at this size, so those two glyphs are hand-drawn replacements spliced in per-character; everything else uses the stock font.
- When OpenWeather is selected without an API key, the app shows a placeholder instead of blank/incorrect data, and the day/date column is hidden to avoid a cramped layout.
