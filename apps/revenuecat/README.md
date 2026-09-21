<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# RevenueCat

Shows subscription metrics for one RevenueCat project: 28-day revenue as the
headline number, a cumulative sparkline across that window, the change against
the previous 28 days, plus MRR and active subscriptions.

## Setup

1. In the RevenueCat dashboard, create a **v2 secret API key** (`sk_...`) under
   Project Settings → API keys.
2. Give it read access to **Charts & Metrics** and **Projects**. Nothing else is
   needed, so do not use a full-access key.
3. Paste the key into the app's API Key field.

The project list populates from the key. Accounts with a single project need no
selection. Editing the API Key field refreshes the list.

## Notes

- Data is fetched twice a day, at local noon and midnight, well inside the
  25 requests per minute limit on RevenueCat's metrics endpoints.
- The current day is excluded from the sparkline and the comparison. RevenueCat
  flags it as incomplete while it is still accumulating, so counting it would
  understate the window until the day closes.
- The percentage compares the 28-day window against the 28 days before it.
  Shorter windows are too noisy for low-volume apps, where a single purchase
  landing either side of the boundary flips the result. When there is no prior
  revenue to divide by, the app shows `NEW` rather than inventing a number.
- Without an API key the app renders sample data, labelled `DEMO`.
