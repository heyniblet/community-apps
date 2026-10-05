# NWS Daily Forecast

This community-maintained version includes downstream changes to the Starlark source. Original author and license notices remain in the source and manifest. Maintenance credit does not replace original authorship. See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Niblet efficiency changes (October 2026)

- Location coordinates are rounded to three decimals (about 110 m) before the NWS `/points` request, so nearby installs send identical requests that the shared response cache can serve. NWS grid cells are about 2.5 km, so the forecast is unchanged except for a location right on a grid-cell boundary.
- The `/points` result (the forecast URL) is remembered in the app cache for 30 days and resolved again if the forecast endpoint returns 404.
- A transient NWS error (5xx, 429) no longer fails the render. The last good forecast (kept for 6 hours) is shown; with none available the render is skipped and the display keeps its previous image.
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: byte-identical output for 3 locations in Fahrenheit and Celsius plus the sample screen. The error, last-good and 404 re-resolution paths were exercised against a local Redis.
