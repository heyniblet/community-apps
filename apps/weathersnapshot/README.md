<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Weather Snapshot

## Overview

The Weather Snapshot app displays current temperature, humidity, and AQI data, based on the [OpenWeather One Call API 3.0](https://openweathermap.org/api/one-call-3) and [Air Pollution API](https://openweathermap.org/api/air-pollution).

![app](weather_snapshot.gif)

## Details

- **Temperature** - the temperature is displayed in Fahrenheit, with icons for weather conditions that are clear, partially cloudy, cloudy, foggy, rainy, thunderstorming, and snowy.
- **Humidity** - the humidity comes with icons for normal (0-70%), high (70-85%), and very high humidity (>=85%).
- **AQI** - the AQI is calculated from pollutant data, according to [standard AQI formulas in the USA](https://www.airnow.gov/sites/default/files/2020-05/aqi-technical-assistance-document-sept2018.pdf). The icons for AQI include good (0-50), moderate (51-100), unhealthy (101-150), and very unhealthy (>150).

## Caching

This app caches results for 6 hours, in order to reduce the number of calls to the OpenWeather One Call API. Furthermore, the API key associated with the app is limited to 1000 calls per day, meaning the app can support at most 250 installations.


