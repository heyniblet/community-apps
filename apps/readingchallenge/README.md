<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Goodreads yearly reading challenge progress 

Displays the progress of your reading challenge along with different icons to illustrate how many books you've read thus far.

![Demo](reading_challenge.png)

## Goodreads.com

Goodreads closed its public API in 2020. A public challenge page at
`https://www.goodreads.com/user_challenges/{challenge_id}` still exposes reading
progress. Enter the challenge ID from that URL in the app settings. The app
parses the page's `progressText` element, so changes to Goodreads HTML may require
an app update.

Parsing HTML is more fragile than making a real API call.
