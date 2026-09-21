<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Tekken Frames

Tekken 8 frame data study tool for [Tidbyt](https://tidbyt.com). Displays random moves with color-coded frame data, filterable by character and move type.

## Display

```
DEVIL JIN              <- character (green)
u/f+4        m         <- command | hit level (color-coded)
F i15~16     B -13     <- frames (startup) | block (color-coded)
H +5s        CH+5s     <- hit | counter hit
15           Balcony…  <- damage | properties (color-coded marquee)
```

### Color Coding

**Hit levels:** red = high, yellow = mid, blue = low, teal = throw

**Block values:** red = -10 or worse, orange = -9 to -1, yellow = 0, green = +1 or better

**Properties:** each tag has a unique color (e.g. Power Crush = purple, Heat Engager = orange, Homing = cyan)

## Settings

- **Quiz Mode** — hides frame data for the first half of the display cycle
- **Characters** — All / None / Custom (individual toggles)
- **Move Filters** — Off / All / Custom (launchers, plus on block, power crush, heat engager, homing, tornado, balcony break, lows, throws)

## Data Source

[TekkenDocs API](https://tekkendocs.com) — frame data for all 40 Tekken 8 characters, cached for 6 hours.
