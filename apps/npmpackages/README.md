# NPM Packages

## Overview

This app shows the number of downloads for a NPM package for the last day, week or month.

## API Details

We use npm's public downloads API to retrieve the data:

- The [downloads](https://api.npmjs.org/downloads/range/last-week/axios) API retrieves the download counts for the package entered by the user.

### Authentication

The API requires no authentication.

### Rate Limiting

It is unknown if the API is rate limited.

Anyway, since NPM only updates the download counts on a daily basis, results are cached for 6 hours using the built-in caching provided by the `http` module.

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never used.
