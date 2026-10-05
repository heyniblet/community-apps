<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# Skylines

Displays famous skylines around the world. 
Displays in the style of the Frasier TV show intro
You can add your name or the city name in the style of the Frasier Show

![screenshot](Frasier.webp)

## Niblet downstream changes (2026-10-05)

- The city (when random) and star positions are picked by a small deterministic
  generator seeded from the current five-minute slot (the app's refresh
  interval) and the canvas size, instead of the clock's nanoseconds. Renders in
  the same slot are identical; the next slot gets a new city and stars.
- Finished columns of the skyline are painted as merged vertical runs instead
  of one widget per pixel. The drawing order, speed, hold, and text are
  unchanged; this only reduces render time (about 35 to 60 percent less CPU in
  local tests).

No settings keys or saved values changed.

Validation (Niblet CLI v0.55.1): with the original city and star picker, the
run painting produced byte-identical output for four different times (different
cities), with and without stars and text, at 20 ms and default speeds, and at
2x. Renders within one five-minute slot are byte-identical. Physical devices
were not tested with this change.
