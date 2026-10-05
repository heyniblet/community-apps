<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet efficiency changes (October 2026)

- NWS requests use coordinates rounded to three decimals (previously four), so nearby installs send identical requests. NWS grid cells are about 2.5 km; the grid point and station are unchanged except right on a cell boundary.
- The NWS observation station is remembered in the app cache for 30 days. This only takes effect when the runtime provides a shared cache.
- NWS errors (HTTP failures or malformed grid/station responses) no longer fail the render; the clock is shown with `?` for temperature and humidity and no weather icon.
- API keys are read only when OpenWeather or Ambient Weather is selected, so the NWS path never reads a secret setting.
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: byte-identical output for 15 combinations (3 NWS locations with unit/24-hour/blink variations, the sample screen and night mode, each at 3 times).
