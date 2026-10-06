<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# NBA Standings for Tidbyt

Displays live NBA standings by division.

![NBA Standings for Tidbyt](screenshot.png)


## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

### Bundled pre-resized team logos (October 2026)

Downstream change, original authorship retained. Every team logo the app
already drew from ESPN is packaged in `images/logos/` at the 10-pixel size the
rows draw it, produced by the runtime's own nearest-neighbour resize from the
same source URLs; `logos.star` lists each source URL and its SHA-256.
Regenerate or verify with `cd tools/lunchbox_logos && go run . -app nbastandings
[-check]`. Renders no longer request a logo per team row, and the clock is read
only for the Current Time header. Team colour lookups (one request per team shown) are now cached for ten hours, like logos, instead of five minutes; their content is static. A logo URL missing from the bundle is
still fetched from ESPN as before. Settings, ordering, timing and artwork are
unchanged; a logo ESPN later redraws at the same URL stays at the bundled
version until the bundle is regenerated.

Validation: `tools/lunchbox_logos/parity.py` rendered the previous and new
source from the same recorded standings responses across every division
option, row count and header at three pinned times: 33 of 33 WebP outputs
were byte-identical, with no request outside the recording. Physical-screen
playback is not covered by these checks.
