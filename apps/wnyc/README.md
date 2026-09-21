<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# WNYC

Show what's currently playing on [WNYC](https://wnyc.org) on Tidbyt

## Settings

You can change the following settings:

- **Stream**: Choose which stream to display info for (93.9 FM or AM 820)
- **Layout**: Choose which layout to use for the info
  - **Name and Image**: The show's title, and the show's image. Title scrolls horizontally next to the image.
  - **Name and Description**: The show's title, and the "description" of the show. Scrolls vertically, but slower. (For some shows, the "description" is used for information about the particular episode; for other shows, it's just generic information about the show)
  - **Name only**: Just the show's title, no other info. Wraps and scrolls vertically if it gets too long.
- **Use custom colors**: Choose your own text colors
  - **Color: Show Title**: Choose your own color for the show's title
  - **Color: Description**: Choose your own color for the description of the show

## Development

See more information in the main development repo at [expandrew/tidbyt](https://github.com/expandrew/tidbyt)
