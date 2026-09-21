<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Chicago Tribune

Display the latest headlines or the latest article from the Chicago Tribune's RSS feed.

News Feed: [Chicago Tribune.com RSS Feeds](https://www.chicagotribune.com/news/feed/)

## Configuration

|Option|Description|
|------|-----------|
|Category|Choose which category of the news to display.|
|News Format|Choose how to display the news. Latest Headlines will return the three recent headlines from the selected feed. Latest Article returns the most recent article in that feed.|

## Screenshots

### Latest Headlines

![Latest Headlines](chicago_tribune_headlines.gif)

### Latest Article

![Latest Article](chicago_tribune_article.gif)
