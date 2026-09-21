<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Avatars In Pixels

## Overview

This app uses the [Avatars In Pixels API](https://www.avatarsinpixels.com/) to generate a random pixel art character, and then displays it using a nice scrolling animation.

Example:

![app](avatars_in_pixels.webp)

---

## API Details

This app needs two API calls to work. The first one calls the Avatars In Pixels generator, which returns the URL of the generated image. The second API call uses this URL to download the image itself.

### Terms of Use

Per the official [terms of use](https://www.avatarsinpixels.com/terms-of-use), the avatars can be used anywhere.

They also ask for attribution and a link back to the website. We provide this link on the app description, which is displayed on the Tidbyt mobile app.

### Authentication

The API requires no authentication. There is only one PHP session cookie (returned in the first API call) that needs to be passed to the second API to be able to download the avatar image.

### Rate Limiting

It is unknown if the API is rate limited.

Anyway, the images are cached for 1 hour so we don't stress the API.

---

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never called.

---

## Future Improvements

The Avatars In Pixels website has three different character generators: Minipix, Chibi and Pony.

We currently generate only the Minipix characters, meaning there's room for improvement.

Also, the API for the other character types seems to be very close to the Minipix one, which makes it easier to support them in the future.
