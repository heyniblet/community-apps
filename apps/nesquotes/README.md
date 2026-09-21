<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NES Quotes Applet for TidByt

Displays randomized quotes from Nintendo Entertainment System games alongside game sprites, with the option to turn off quotes from specific games. The quotes are drawn from a pinned revision of the author's [nes-quotes.csv Gist](https://gist.github.com/markmcintyre/b39cf560d7e66bc0b987f809ca4a568f) and cached weekly.

Schema version 2 gives every game a unique setting ID. The renderer still reads the accidental one-character version 1 IDs when an existing configuration is supplied, so a Cloud migration can preserve the two formerly coupled game pairs without guessing user intent.

![NES Quotes Applet for Tidbyt](nes_quotes.gif)
