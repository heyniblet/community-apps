# Air Quality

## Overview

This app uses the [OpenWeather Air Pollution API](https://openweathermap.org/api/air-pollution) to show the current Air Quality Index (AQI) of a given location.

The AQI ranges from 1 to 5, meaning:

1. Good condition
2. Fair condition
3. Moderate condition
4. Poor condition
5. Very poor condition

The app displays the current AQI and forecasts for the next 6 and 12 hours:

![app](air_quality.gif)

---

## API Details

We currently use the [forecast endpoint](https://openweathermap.org/api/air-pollution#forecast). It gives us the current conditions as well as a 4 day hour-by-hour forecast, from which we pick the results for the next 6 and 12 hours.

### Authentication

OpenWeather requires an API key to work. You can sign-up for a free account and create as many keys as you need.

To run the app locally, pass your own key through the `api_key` configuration field. Do not add it to the source tree.

### Rate Limiting

OpenWeather applies plan-specific rate limits. Refresh and cache cadence is deployment policy rather than app source; each installation uses its owner's key.

---

## Configuration (Schema)

The app supports many configuration options. Since this is a geolocation based service, the user needs to provide a location via the `Location` widget.

The user can also override the name of the displayed location (to show something meaningfule like "Home" or "Office"), customize the colors for each AQI level and choose to scroll the description of the current AQI level or not.

---

## Error Handling

Invalid configuration, rejected credentials, malformed responses, and unavailable data render a concise error instead of exposing upstream payloads.

---

## Pollutant View

The OpenWeather API returns other meaningful data about polluting gases, which are used to calculate the AQI level.

The pollutant view exposes SO2, NO2, CO, PM2.5, PM10, and O3 alongside the forecast view.
