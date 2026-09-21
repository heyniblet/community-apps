<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

Welcome to the YNAB Tidbyt App!

This app uses the YNAB API (https://api.youneedabudget.com/v1#/) to display your categories in your last used budget that are negative or partially spent for the current month or to display your most recent transactions. These two configurations are displayed separately. 

You will need to supply an access token associated with your YNAB account in order to enable the Tidbyt app's connection to YNAB. The directions for retrieving the token are here (https://api.youneedabudget.com/).

Recent Enhancements:
* Display recent transactions
* Color differentiation if spending is outpacing monthly budget
* Added Net Worth mode

Possible Enhancements:
* "Pin" categories to always display, regardless of current balance

Categories:
![](YNAB.webp)

Transactions:
![](YNAB-Transactions.webp)
