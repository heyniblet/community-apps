<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Roblox for Tidbyt

Displays an online friends or favorite games view for a specified Roblox username.

A pulsating green dot will appear if the Roblox user is online, otherwise it will show gray for offline. Friend avatars also provide an online vs offline dot indicator.

### ONLINE FRIENDS VIEW

![Sample Online Friends View](https://www.dropbox.com/s/3na6toovhxn6kc0/roblox_friends.gif?raw=1)

### FAVORITE GAMES VIEW

![Sample Favorite Games View](https://www.dropbox.com/s/pbdxea94fqya76g/roblox_favorite_games.gif?raw=1)


### Customization

This app provides various UI options. The user can customize their experience by choosing to show their online friends vs. favorite games views, selecting an accent text color or enabling dark vs. light modes.  

These customizations can be adjusted using the properties of the app.

### Roblox API

This app uses Roblox's public, unauthenticated [users](https://create.roblox.com/docs/cloud/reference/features/users), [thumbnails](https://create.roblox.com/docs/cloud/reference/features/thumbnails), friends, presence, and games endpoints.

### Notes

API responses are cached briefly and media is restricted to Roblox's thumbnail CDN.

### –
#### Happy coding! CODE𝗦𝗧𝗥𝗢𝗡𝗚
