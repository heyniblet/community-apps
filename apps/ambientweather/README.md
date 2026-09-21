<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Ambient Weather

Ambient Weather displays details from your [weather station](https://ambientweather.com).

Displayed:

- Location
- Temperature
- Humidity
- UV Index
- Wind speed and direction

## Configuration

In order to set up Ambient Weather, you'll need to gather a few things from your [Ambient Weather account](https://ambientweather.net/account).

1. Your Application Key
1. Your API Key
1. Your Station's MAC address

You can create a new API key on your account page. If you haven't already created one, an Application Key will be generated automatically for you.

You can find the MAC address of your station on your [devices page](https://ambientweather.net/devices).

## Thanks

Thanks a lot to @rohansingh as a lot of this applet was based on the work he did on the [Tempest applet](../tempest/).

## Screenshot

![](screenshot.png)
