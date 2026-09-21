<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# PulseChain for Tidbyt

Made by: [bretep](https://github.com/bretep)  
Twitter: [@bretep](https://twitter.com/bretep)  
Telegram: [bretep](https://t.me/+1YjcyTCG4sJhY2U5)  


### Displays the USD price of PulseChain PLS, PulseX PLSX, and optionally HEX

- Current mainnet prices use the keyless CoinGecko API.
- Existing custom GraphQL mainnet and testnet endpoints remain supported.

The former default Graph-hosted testnet endpoint has been retired. Testnet mode therefore needs a custom GraphQL endpoint; without one, PLS and PLSX display as unavailable rather than showing incorrect mainnet prices.

Please reach out to me on [Telegram](https://t.me/+1YjcyTCG4sJhY2U5) if you have a feature request or find a bug.


![Preview](pulsechain.png)
