<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, Python helpers, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

### Off-season sports (November 2026)

Downstream change, original authorship retained. When ESPN's news feed is
valid but has no stories for the chosen sport (WNBA in November), the app
skips the render instead of failing with "ESPN headlines unavailable"; a
non-200 or malformed response still fails so the last good frame is kept.
Validation: WNBA renders zero frames, NBA renders its headlines.
