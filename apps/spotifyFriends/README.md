<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Spotify Friends Display for Tidbyt
This app displays the most recently played song for a random spotify friend. 
## Configuration
This app uses the spotify web player API, and requires a cookie that is created when the web player is accessed. This API is not the public facing API, and thus requires the user to manually retrieve this value. This can be done by navigating to the spotify web player, opening developer tools in your browser, and copying the value from the cookie storage. The other configuration field asks for the user's spotify username, which can be found in the spotify account overview. More detailed instructions for both values are provided below. 
## Demo
![example render](/apps/spotifyFriends/spotify_friends.png)
## Acknowledgements
This use of the web player API is adapted from the code of [ValerianGalliat](https://github.com/valeriangalliat), as shown [here](https://github.com/valeriangalliat/spotify-buddylist) 
## sp_dc Cookie Walkthrough
First go to the [spotify web player](https://open.spotify.com/), and log in with your apotify account. Once logged in, open the inspect tab in your browser. This can be found on chrome by clicking the three dots directly next to your profile icon, then more tools, then developer tools. Click on the application tab at the top of the inspect pane, then find the Cookie tab under storage. This tab should have a file named **https://open.spotify.com/**, in which you can find the cookie named **sp_dc**.
### WARNING
This sp_dc cookie is a key that can be used to access a very large scope of your spotify data, so be careful with it. I do not know if it is accessible on mobile, so you will likely need to access it from a PC and get it onto your phone from there. This token must be refreshed once a year, and the recaptcha on spotify's login prevents it from being automated, but some extra caution once a year is would be prudent given the key's access. 
## Username Walkthrough
This value is significantly easier to get than the cookie, once at the [web player](https://open.spotify.com/), simply click on your profile picture and then the account link. This will redirect you to your account overview, and the first field in the profile section will display your username. This value is public and is simply used as a unique identifier to access cached user data. 
