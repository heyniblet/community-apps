<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet downstream changes (2026-10-05)

- Random choices (the animation when **Animation** is Random, the speed when
  **Speed** is Random, and each Pac-Man or Centipede pass) now come from a small
  deterministic generator seeded from the current five-minute slot (the app's
  refresh interval) and the settings, instead of the random module. Renders in
  the same slot are identical; the next slot gets a new variation. Space
  Invaders at a fixed speed does not read the clock at all.
- Frames past the 15 second animation limit are no longer built (the runtime
  already dropped them).

No settings keys or saved values changed.

Validation (Niblet CLI v0.55.1): with the random module pinned (`--seed`), the
frame limit alone produced byte-identical output for Pac-Man, Space Invaders,
Centipede, and Random at several speeds. Space Invaders at a fixed speed is
byte-identical to the previous version. Renders within one five-minute slot are
byte-identical and render metadata reports `reads.random=false`. Physical
devices were not tested with this change.
