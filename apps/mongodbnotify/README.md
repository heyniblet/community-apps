<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Webhook Notify

MongoDB Atlas Data API was retired on September 30, 2025. This version keeps
the notification use case without executing render widgets supplied by a
remote document.

Configure a public HTTPS endpoint. A `204` response or an empty `message`
hides the app. A notification response is a bounded JSON object:

```json
{
  "title": "Front door",
  "message": "The door has been open for five minutes.",
  "color": "#991b1b"
}
```

`title` and `color` are optional. If configured, the bearer token is stored as
a user-owned encrypted credential and sent as `Authorization: Bearer ...`.
