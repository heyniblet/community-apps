<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

![Coin Price Applet for Tidbyt](screenshot.gif)

## Motivation

Display one exchange rate against another of your choice on your Tidbyt. Data provided by [AwesomeAPI](https://docs.awesomeapi.com.br/). As the Brazilian community grows, this Applet support BRL currency so you can check it against USD or EUR.

### Available Options

With the dynamic schema fields you can:

| Name              | Description                                              | Default |
| ----------------- | -------------------------------------------------------- | ------- |
| `From`            | Change origin coin                                       | `BRL`   |
| `To`              | Change target coin                                       | `USD`   |
| `Precision`       | Choose your desired number of decimal points for prices  | 2       |
| `Exchange spread` | Change between your desired Exchange spread (bid or ask) | `Bid`   |

### Applet Anatomy

![Coin Price Applet for Tidbyt](coinpricedocs.png)
