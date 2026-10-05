<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet downstream changes (2026-10-05)

The app no longer caches the selected user's id under a key made from the
league id alone. `cache.*` entries are shared by every display running the
app, so with a shared cache two members of one league would have seen the
same member's matchup. The id is now read from the cached league users on each
render, which needs no request. Output is unchanged without a shared cache: on
2026-10-05, 15 renders (standings, scores for two members, ties, three teams
per view, demo data) were byte-identical before and after. With a shared
cache, the second member now sees their own matchup. No settings changed.
