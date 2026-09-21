<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# NPM Packages

## Overview

This app shows the number of downloads for a NPM package for the last day, week or month.

## API Details

We use npm's public downloads API to retrieve the data:

- The [downloads](https://api.npmjs.org/downloads/range/last-week/axios) API retrieves the download counts for the package entered by the user.

### Authentication

The API requires no authentication.

### Rate Limiting

It is unknown if the API is rate limited.

Anyway, since NPM only updates the download counts on a daily basis, results are cached for 6 hours using the built-in caching provided by the `http` module.

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never used.
