# Reddit Image Shuffler For Tidbyt

Displays a random image post from subreddits you specify and/or a list of default subreddits, along with its name, subreddit, and post ID.

To access any posts on reddit, tack the ID onto the end of the URL. For example, the post below is located at http://www.reddit.com/td4fnp.

![Sample Shuffle](image-shuffler-example.png)

## Reddit API

This uses Reddit's OAuth listing API. Create a Reddit API application at
<https://www.reddit.com/prefs/apps>, then enter its client ID and client secret
in the app settings. The client ID is shown beneath the app name; the secret is
kept in the secret configuration field.

See Reddit's [OAuth documentation](https://github.com/reddit-archive/reddit/wiki/OAuth2)
and [`GET /r/subreddit/hot`](https://www.reddit.com/dev/api/#GET_hot) for API details.
