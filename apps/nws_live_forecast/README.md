<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet efficiency changes (October 2026)

- Location coordinates are rounded to three decimals (about 110 m) before the NWS `/points` request, so nearby installs send identical requests that the shared response cache can serve. NWS grid cells are about 2.5 km, so the forecast is unchanged except for a location right on a grid-cell boundary.
- The `/points` result (the hourly forecast URL) is remembered in the app cache for 30 days and resolved again if the forecast endpoint returns 404.
- A transient NWS error (5xx, 429) no longer fails the render. The last good forecast (kept for 6 hours) is shown; with none available the render is skipped and the display keeps its previous image.
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: byte-identical output for 9 location/unit/time combinations. The error, last-good and cached-`/points` paths were exercised against a local Redis.
