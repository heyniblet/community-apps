<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Verge Taglines

This app makes a request to the main page of popular tech news site, [The Verge](https://theverge.com), in order to display the latest tagline at the top of the page.

- No configuration is required.
- Requests are cached for 15min.
- Taglines shorter than the display are auto-centered by the updated marquee widget.

This app is inspired by the [Twitter bot](https://github.com/TylerCarberry/VergeTaglines) with the same purpose.
