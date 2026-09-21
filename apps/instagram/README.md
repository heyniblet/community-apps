<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Instagram

## Overview

This app shows an Instagram user's number of followers, extracted from the user's public page, eg: [@hellotidbyt](https://www.instagram.com/hellotidbyt/).

It only works for public profiles. Private ones will not cause an error, but Instagram returns the followers count as zero.

---

## API Details

There are no APIs being used by this app. The data is extracted directly from the HTML of the profile page.

To be more specific, the page includes a `meta` tag with the number of followers like below:

```html
<meta
  property="og:description"
  content="41K Followers, 74 Following, 86 Posts - See Instagram photos and videos from Tidbyt (&#064;hellotidbyt)"
/>
```

We use a simple Regular Expression to read whatever is before the "Followers" word.

### Caveats

There are two caveats about this method that are worth mentioning:

1. It only works for public profiles. If the user has a private Instagram account they will see the number zero as the follower count.

2. For large accounts with over 1000 followers, Instagram shortens the number and uses a suffix like "K" for thousands and "M" for millions. This means that users will no longer see the exact number of followers. Also, these users will likely see the same number of followers for several days depending on the growth rate of their accounts. Eg: it could take a long time for the @hellotidbyt account to grow from "41K" to "42K" followers.

### Is there an official REST API?

Yes, Instagram does offer an official REST API. Unfortunately, you need to be a verified Meta Business Partner to use it in production. This involves having a legitimate business and going through a verification process. This is the kind of thing that Tidbyt Inc. could procure if they wanted to provide an official app like they do with YouTube, Spotify, etc.

However, the official API only works with Instagram business accounts, so it's not very useful for the majority of users.

Given the above, we feel that extracting the data from the HTML is easier and makes the app available for a broader audience.

### Rate Limiting

We don't know how Instagram handles rate limiting on public HTML pages.

But since this app has the potential of being installed by a lot of Tidbyt users, there will be a lot of requests for these profile pages coming from Tidbyt's servers.

To mitigate the risk of rate limiting, the app is caching the responses for **4 hours**. User's will be able to see an updated follower count only 6 times a day.

---

## Configuration (Schema)

The app is very simple and only has configuration options to set the Instagram username and the colors of the follower count and the username itself.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, API errors and non-existing accounts will be displayed on the screen to let the user know that something went wrong.

The `fail` function is never used.

---

## Future Improvements

There is more data available in the profile page HTML that could be displayed by the app, like the number of accounts that the user is following and the number of posts they have made.

Another option would be to display the profile's image instead of the Instagram icon.
