<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

## Recurring events (October 2026)

The calendar is parsed entirely inside the app, with no external adapter. Recurring events (RRULE, RDATE, EXDATE, and moved or cancelled instances), TZID time zones, and VTIMEZONE definitions are supported. Adapted from tronbyt/apps eb488858 (#798). Only HTTPS URLs on Google, Outlook, and calendarlabs hosts are fetched, `webcal://` links are accepted, and feeds over 1 MiB are rejected. The `url`, `title`, and legacy `loc` settings keep their meaning; saved configurations continue to work.
