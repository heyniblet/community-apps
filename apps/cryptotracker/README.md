<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Crypto Tracker for Tidbyt

Displays one of 5 24-hour cryptocurrency price charts in USD on your Tidbyt. Includes Bitcoin, Ethereum, Binance Coin, Cardano and Solana. Clockwise from symbol is 24-hour price change, 24-hour percentage, and current price. Below this is a 24-hour price graph. Data is provided by [AlphaVantage](https://www.alphavantage.co/documentation/#crypto-intraday) and updated every 15 minutes. No API key required currently.

![Crypto Tracker for Tidbyt](screenshot.png)

## Feature Ideas

- Add cryptocurrencies to list and add formatting for changes that are less than a cent for cryptos worth less than 10 cents.
- Find API for commodity tracking and add support.

Thanks to [AlphaVantage](https://www.alphavantage.co/) for API access!
