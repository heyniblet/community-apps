<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# CoinGecko Crypto Price Applet for Tidbyt

Display the price of any cryptocurrency supported by [CoinGecko](https://www.coingecko.com/) on your Tidbyt against up to two other currencies. Data provided by [CoinGecko](https://www.coingecko.com/en/api). Updated every 10 minutes. No API key required. 

Based on @saltedlolly's digibyteprice app.

![CoinGecko Crypto Price Applet for Tidbyt](screenshot.png)


