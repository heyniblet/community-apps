<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Regional block fix (October 2026)

Downstream change in this community-maintained version; original authorship
retained. `culvers.com` and `www.culvers.com` now refuse requests from outside
the US and Canada with a 403, so the app showed "Culver's status code: 403"
whenever it was rendered from a server in another country. The app now calls
the same locator API on `web.culvers.com`, which returns the same data without
the regional block. Flavor image names now end in `.png` (for example
`img-Snicker-Swirl.png`), so `.` is allowed in them; `..` is still rejected.
Settings are unchanged.

Validated on 14 October 2026 with live renders from India, where
`culvers.com` returns 403: the previous source shows the 403 error, and this
version shows the flavor and its image for the default Sauk City restaurant
and a Chicago location at 1x and 2x. `web.culvers.com` also returned the
flavor from a server in Finland. `check`, `format` and `lint` pass. The
`web.culvers.com` host is not a documented API and may change.

## Search radius fix (October 2026)

The locator's `radius` parameter is in meters, not miles. The app sent
`radius=100`, so it only found a restaurant within 100 m of the chosen
location and showed "Restaurant not found" for a town or address a few
blocks away. The app now searches 25 miles (40,233 m) and returns the nearest
restaurant, and the empty result reads "No Culver's within 25 mi". Settings are
unchanged.
