<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Helldivers 2

## Overview

This app shows the current number of players for the game Helldivers 2.

## API Details

We use the game's public API to retrieve the data. This is the same API used by websites like [helldivers.io](https://helldivers.io/) and [helldiversstats.com](https://www.helldiversstats.com/).

### Authentication

The API requires no authentication.

### Rate Limiting

It is unknown if the API is rate limited.

Results are cached for 15 minutes using the built-in caching provided by the `http` module.

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never used.

## Future Improvements

The API provides more data that could be used to enhance the application like:

- Show a chart with the player count history from the last 24h (using [this API](https://www.helldiversstats.com/api.php)).
- Show ongoing game global events and major orders.
- Show stats about a planet's liberation campaign.
