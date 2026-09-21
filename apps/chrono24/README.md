<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Chrono24

![Chrono24](screenshot.png)

This Chrono24 app shows two different views.

- Overall market performance
- Top 10 watches in the index

These data points are on a configurable time frame:

- 1 month
- 3 months
- 6 months
- 1 year
- 3 years
- Max

## Configuration

| Title     | Description                                           | Required | Default             |
| --------- | ----------------------------------------------------- | -------- | ------------------- |
| Timeframe | Timeframe the data fetches                            | No       | 1 month             |
| View type | Show either the market view or individual watch index | No       | Overall market view |
