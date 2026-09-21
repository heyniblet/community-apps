<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Average US Mortgage Rates Tracker

<img src="./screenshot.png" width="450" border="10">

## Configuration

Generate your own personal API key from [https://fredaccount.stlouisfed.org/apikeys](https://fredaccount.stlouisfed.org/apikeys) (make a free account if you don't have one already)

This currently can track the following mortgage types:
- [30-Year Fixed Rate Index](https://fred.stlouisfed.org/series/OBMMIC30YF), updated daily (OBMMIC30YF)
- [30-Year Fixed Rate Jumbo Index](https://fred.stlouisfed.org/series/OBMMIJUMBO30YF), updated daily (OBMMIJUMBO30YF)
- [15-Year Fixed Rate](https://fred.stlouisfed.org/series/MORTGAGE15US), updated every Thursday (MORTGAGE15US)
- [30-Year Fixed Rate](https://fred.stlouisfed.org/series/MORTGAGE30US), updated every Thursday (MORTGAGE30US)

## TODO
- [ ] Add animation/graphical tracker over selectable time period

## References 
Uses the free [https://fred.stlouisfed.org/](https://fred.stlouisfed.org/) economic data and API
