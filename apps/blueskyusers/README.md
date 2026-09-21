<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Bluesky Users

## Overview

This is a simple app that displays the total number of users on the [Bluesky](https://bsky.social/) social network.

Data is gathered from the website https://bsky-users.theo.io.

The app displays an animation of the user count increasing, according to a growth rate returned from the aforementioned website.

---

## Configuration (Schema)

The app supports some configuration options like changing the user count color and using dots instead of commas as thousands separator.

---

## API Details

There is a single and unauthenticated API being used: https://bsky-users.theo.io/api/stats.

We are not sure if there is any kind of rate limiting implemented, but results are cached for 15 minutes using the http module native caching mechanism.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, a non 200 response from the API will be handled and a message will be shown on the screen.

---

## Future Improvements

There's nothing left to add here since the API only returns the user count and the growth rate.
