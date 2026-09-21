<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# CTA 'L' Status

Display the status of the CTA 'L' along with any travel alerts

## Feeds

- [CTA Status API](http://www.transitchicago.com/api/1.0/routes.aspx)
- [CTA Alerts API](https://www.transitchicago.com/api/1.0/alerts.aspx)

## Configuration

|Option|Description|
|------|-----------|
|**Rail Line**|Choose one of the 'L' Lines to display the status of.|
|**Alert Display**|Choose whether to display the headline of the alerts or the full description.|
|**Scroll Speed**|Display how fast the scroll speed is.|
|**Display Active Alerts**|Default is `TRUE`. When `TRUE`, response yields events only where the start time is in the past and the end time is in the future or unknown.|
|**Display Accessibility Alerts**|Default is `FALSE`. If `TRUE`, response includes events that affect accessible paths in stations.|
|**Display Planned Alerts**|Default is `TRUE`. If `FALSE`, response excludes common planned alerts. Otherwise, result does include planned alerts.|
|**Display Recent Alerts**|Default is `TRUE`. When `TRUE`, response excludes alerts that started more than seven days ago.|
