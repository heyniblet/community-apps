<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Reddit Image Shuffler For Tidbyt

Displays a random image post from subreddits you specify and/or a list of default subreddits, along with its name, subreddit, and post ID.

To access any posts on reddit, tack the ID onto the end of the URL. For example, the post below is located at <https://www.reddit.com/td4fnp>.

![Sample Shuffle](image-shuffler-example.png)

## Reddit API

This uses Reddit's OAuth listing API. Create a Reddit API application at
<https://www.reddit.com/prefs/apps>, then enter its client ID and client secret
in the app settings. The client ID is shown beneath the app name; the secret is
kept in the secret configuration field.

See Reddit's [OAuth documentation](https://github.com/reddit-archive/reddit/wiki/OAuth2)
and [`GET /r/subreddit/hot`](https://www.reddit.com/dev/api/#GET_hot) for API details.
