<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Steam Top Sellers (A Tidbyt App)

## Overview
A simple [Tidbyt](https://tidbyt.com/) appliction intended to render a random selection from Steam's Top Seller list, including the game name, price, discount (optional) and an image.

This data is exposed via the Steam API using the "featured categories" resource (ie. `https://store.steampowered.com/api/featuredcategories`).

The API payload includes game metadata as well as an image resource. These details are used to populate frames in the Tidbyt app.

## Usage
After installing [Pixlet](https://tidbyt.dev/docs/build/installing-pixlet), run the following commands to render/serve the image locally. 

```
# Serve locally (default port 8080)
pixlet serve steamtopsellers/steam_top_sellers.star

# Render webp artifact
pixlet serve steamtopsellers/steam_top_sellers.star
```

> See [Tidbyt.dev](https://tidbyt.dev/) for additional details about pushing to a device or publishing.