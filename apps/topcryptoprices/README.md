<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Top Crypto Prices

This app shows the latest prices and 24hr price changes for the top cryptocurrencies.

Prices can be displayed in many currencies, and certain coins can be excluded.

It is a very simple app, but does exactly what I needed for myself, and why I bought the Tidbyt in the first place. Since there was no app that could do what I had hoped for, I wrote one myself.

Prices are updated through the free [CoinGecko](https://www.coingecko.com/) API at a maximum rate of once per minute. This fits well within their [Free API Plan](https://www.coingecko.com/en/api/pricing). No API key required.

![Top Crypto Prices Applet for Tidbyt](top_crypto_prices.jpg)

The gif animation shows a full animation loop, but looks kind of ugly compared to the PNG image above, which shows what the fonts look like on the Tidbyt.

![Top Crypto Prices Applet for Tidbyt gif animation](top_crypto_prices.gif)

More than 20 fiat currencies to display prices in. All ticker symbols are colored after the coin logo colors. Stable coins and wrapped coins are excluded by default, but can be switched on. Further options to control rotation speed, number of coins, and manual excludes.

![Top Crypto Prices Applet for Tidbyt gif animation](topcryptoprises-config.jpg)

Enjoy,  
Jeroen Playak  
2022-11-09
