<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Plex Recently Added

Shows recently added media from a Plex server. Because the app runs in the cloud, its Plex endpoint must be reachable through HTTPS. Keep Plex `Secure Connections` enabled.

![](./plex_recently_added.gif)

## Config

`serverIP` Public HTTPS URL for Plex or an HTTPS reverse proxy. A bare hostname can also be used with `serverPort`.

`serverPort` Port used with a bare hostname. Plex commonly uses 32400.

`plexToken` Follow [this article](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) on how to find this value.

## Optional proxy setup

The included Node proxy is retained for compatibility. Put it behind an HTTPS reverse proxy, restrict public access, set its `API_KEY`, and enter the same value in the app. A plain HTTP or LAN-only endpoint cannot be reached by the cloud renderer.
