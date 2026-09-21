<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Met Eireann Tidbyt app

Pulls from Met Eireann's Forecast API to display a weather app on Tidbyt. Met Eireann is Ireland's national meteorological serivce.

Note: Met Eireann only provides data for locations in the Republic of Ireland, and some locations in the UK and North France. The app will not display data for locations not supported by the Met Eireann dataset.

# Data attribution

Weather forecast data is pulled from Met Eireann's public API.

- Copyright statement: Copyright Met Éireann
- Source [met.ie](https://met.ie)
- Licence Statement: This data is published under a Creative Commons Attribution 4.0 International (CC BY 4.0).
- Disclaimer: Met Éireann does not accept any liability whatsoever for any error or omission in the data, their availability, or for any loss or damage arising from their use.

Subjective aggregation of the data by this app can mean some slight differences between what this app displays and what's visible on Met Eireann's website.

# References:

- [Met Eireann forecast API on publicservicecatalogue.gov.ie](https://datacatalogue.gov.ie/dataset/met-eireann-weather-forecast-api)

