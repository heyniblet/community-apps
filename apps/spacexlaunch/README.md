<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# SpaceX Launch
by [rytrose](https://github.com/rytrose)

SpaceX Launch displays information about an upcoming SpaceX rocket launch. Data is provided by the [Launch Library 2 API](https://thespacedevs.com/llapi).

If you have a [Launch Library 2 API key](https://github.com/TheSpaceDevs/Tutorials/blob/main/faqs/faq_LL2.md#free-and-paid-access), you can change the search query to something other than the default "SpaceX" (the free API has a 15 req/hr rate limit).

## Screenshots
### Normal operation
![normal operation screenshot](./spacex_launch.png)

### Error
![error screenshot](./error.png)