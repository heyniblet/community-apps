<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Bambu Printer Status for Tidbyt

Bambu Printer Status shows live information from your Bambu printer’s status.json endpoint on your Tidbyt. It displays the printer name, current state, and a combined job line including job name, plate name, and job objects, plus a small timestamp or job footer. If you have not configured a status URL yet, the app shows simple on-device setup instructions instead of failing. Setup details for creating and hosting the JSON status URL are available in bambu_printer_status_json_setup_instructions.pdf.

Niblet Cloud requires the status URL to use public HTTPS. Do not put credentials in the URL or JSON; Cloud signs only the configured public origin and keeps rendered printer status tenant-scoped.

![Bambu Printer Status for Tidbyt](bambuprinterstatus.webp)
