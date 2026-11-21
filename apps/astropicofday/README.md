<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## November 2026: NASA's new APOD endpoint

NASA moved the Astronomy Picture of the Day to `science.nasa.gov`. The old
`api.nasa.gov/planetary/apod` endpoint then answered 500, or a "NASA Science"
logo in place of the picture. The app now reads the newest entry from
`science.nasa.gov/wp-json/wp/v2/apod-basic`, which needs no API key, and asks
NASA's image service for a small rendition. The endpoint is not documented by
NASA; `science.nasa.gov/feed/apod-basic/` carries the same entries.

# Astro Pic of Day Applet for Tidbyt

Displays NASA's [Astronomy Picture of the Day](https://science.nasa.gov/apod/) on your Tidbyt. It checks for a new photo every hour.

![Astro Pic of Day Applet for Tidbyt](screenshot.png)