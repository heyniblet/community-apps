# Plex Recently Added

Shows recently added media from a Plex server. Because the app runs in the cloud, its Plex endpoint must be reachable through HTTPS. Keep Plex `Secure Connections` enabled.

![](./plex_recently_added.gif)

## Config

`serverIP` Public HTTPS URL for Plex or an HTTPS reverse proxy. A bare hostname can also be used with `serverPort`.

`serverPort` Port used with a bare hostname. Plex commonly uses 32400.

`plexToken` Follow [this article](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) on how to find this value.

## Optional proxy setup

The included Node proxy is retained for compatibility. Put it behind an HTTPS reverse proxy, restrict public access, set its `API_KEY`, and enter the same value in the app. A plain HTTP or LAN-only endpoint cannot be reached by the cloud renderer.
