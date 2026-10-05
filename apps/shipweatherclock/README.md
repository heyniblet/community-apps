# ShipWeatherClock

This community-maintained version includes downstream changes to the Starlark source. Original author and license notices remain in the source and manifest. Maintenance credit does not replace original authorship. See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Niblet efficiency changes (October 2026)

- Location coordinates are rounded to two decimals (about 1 km) before the Open-Meteo request, so nearby installs send identical requests that the shared response cache can serve. Open-Meteo interpolates elevation for the exact coordinates and its finest grids are about 2 km, so temperatures can differ by a few tenths of a degree from the unrounded request, and a location near a grid-cell edge can get the neighboring cell.
- An Open-Meteo error no longer fails the render. The scene is drawn with a clear sky, 06:00 sunrise and 18:00 sunset, and `--` for temperatures.
- The response is decoded once instead of once per field.
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: with identical response bodies, output is byte-identical for 18 location/unit/time/seed combinations.
