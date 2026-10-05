<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet downstream changes (2026-10-05)

- The clock animation spans a minute, but Niblet encodes at most 15 seconds of
  it. The app now builds the first 20 seconds of frames (20 at the default
  1 second step, 80 with the dial second hand) instead of 61 or 241. The dial
  second hand still sweeps at the one-minute rate. On hosts that play longer
  animations, the animation now loops after 20 seconds.

No settings keys or saved values changed.

Validation (Niblet CLI v0.55.1, 15 second limit as used by Niblet Cloud): the
original and changed source produced byte-identical WebP output for the default
settings, all overlays on, the dial second hand (including a render crossing
midnight), and a southern-hemisphere location. Weather was not tested because
it needs a weatherstack key. Physical devices were not tested with this change.
