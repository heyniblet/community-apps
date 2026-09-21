<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# On [The] Air for Tidbyt

Displays an old time radio station "On Air" sign. This variation can handle miultiple variations on the text. 

You are able to turn the sign "on" or "off," as well as hide it through the options. Same as the "On Air" sign. But there is also an alternative version where the sign says "On The Air." And even the ability to add custom text. Including aligning that text. If the text gets a little long it will wrap, so a full sentence is possible. There _are_ limits so try to keep it short. 

A spin off of Robert Ison's "On Air" app.

![On [The] Air for Tidbyt](on_the_air.webp)

## Home Assistant

The primary catalyst for this spin off was to use [TronbytAssistant](https://github.com/tronbyt/TronbytAssistant) to automatically update the app. Manually flipping options is not an option for me. Testing of this connection is still ongoing. 
