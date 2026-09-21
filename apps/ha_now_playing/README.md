<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Home Assistant Now Playing

Based on the applet built by drudge: [ha_now_playing](https://github.com/drudge/smart-matrix-server/tree/main/applets/ha_now_playing)

| Size   | Preview                       |
|--------|-------------------------------|
| **1x** | ![1x](ha_now_playing.webp)    |
| **2x** | ![2x](ha_now_playing@2x.webp) |

The applet pulls information from Home Assistant and requires:

- **Home Assistant Server URL:** The full http(s) address of your Home Assistant instance.
- **Entity ID:** The media player entity ID you want to display.
- **Token:** A long-lived token to allow using the Home Assistant API.
