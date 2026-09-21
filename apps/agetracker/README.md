<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Age Tracker

A memento-mori "life in months" calendar for the Tidbyt (64×32).

Every month from your birth to age **82** is one cell — **984** months packed to
fill the whole panel. Cells are **2px wide × 1px tall**, **32 per row**, so the
grid spans the full **64px width** and 31 of the 32px height. Months you have
already lived are filled with your chosen color; months still ahead are white.

The screen is **animated**: the lived months fill in left-to-right, row by row,
over ~5 seconds, then the finished grid holds for ~3 seconds before looping.

## Settings

| Field         | Type | Default   | Description                          |
|---------------|------|-----------|--------------------------------------|
| `birthdate`   | Date | 1990-01-01| Your birthdate.                      |
| `livingColor` | Color| `#3b82f6` | Color for the months already lived.  |

Months lived are computed from `birthdate` to the current date (whole completed
months), clamped to `[0, 984]`.
