<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Product Hunt

## Overview

This app shows the daily top tech products being launched on [Product Hunt](https://www.producthunt.com/).

There is an option to show only the current top product, or the top 3 where each one is displayed for about 5 seconds.

The app shows the product name, logo and the current vote count.

Votes are cast by the Product Hunt community and are used to rank the products. Users of the app may see different products displayed on the Tidbyt along the day.

---

## API Details

The app uses Product Hunt's official [GraphQL API](https://api.producthunt.com/v2/docs). Create a developer token in your Product Hunt API dashboard and enter it in the app configuration.

### Rate Limiting

The API publishes its current quota in response headers. The app caches results and thumbnails for 30 minutes.

---

## Configuration (Schema)

The app requires a developer token and lets the user choose whether to show the top product or the top three.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, API errors will be rendered with the `render_api_error` function and will try to extract an error message from the payload.

Errors when trying to download the product's logo will be handled and a default image will be shown instead.

The `fail` function is never used in the code.

---

## Future Improvements

Product Hunt's GraphQL API has a lot of information available such as product categories, rewiews, ratings, descriptions, number of followers etc.

The app could be improved with new display options to show this data.

We could also add more config options to allow customization of colors, to hide the product logo and show something else there, or even to let the user select a specific category and view only the products that are part of that.
