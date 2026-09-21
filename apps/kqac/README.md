<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# KQAC (All Classical Portland)

Show what's currently playing on [All Classical Portland](https://allclassical.org) on your Tidbyt

## Settings

You can change the following settings:

- **Scroll direction**: Choose whether to scroll text horizontally or vertically
- **Scroll speed**: Slow down the scroll speed of the text
- **Show ensemble info**: Show the ensemble name, conductor, and/or soloist(s), if applicable
- **Use custom colors**: Choose your own text colors
  - **Color: Title**: Choose your own text color for the title of the current piece
  - **Color: Composer**: Choose your own text color for the composer of the current piece
  - **Color: Ensemble info**: Choose your own text color for the ensemble name/conductor/soloists

## Development

See more information in the main development repo at [expandrew/tidbyt](https://github.com/expandrew/tidbyt)
