<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Flight Overhead for Tidbyt

Use AirLabs or OpenSky to find the flight overhead a location. By default, OpenSky is the provider. An optional OpenSky account can be used to extend the request quota. An AirLabs API Key is required to use AirLabs as the provider.

>>>
name = "Provider (Required)",
desc = "The provider for the data"

name = "Location (Required)",
desc = "The decimalized latitude and longitude to search"

name = "Radius",
desc = "The radius (in nautical miles) to search"

name = "AirLabs API Key",
desc = "An AirLabs API Key is required to use AirLabs as the provider"

name = "OpenSky Username",
desc = "An OpenSky account can be used to extend the request quota"

name = "OpenSky Password",
desc = "An OpenSky account can be used to extend the request quota"

name = "Provider TTL Seconds",
desc = "The number of seconds to cache results from the provider"

name = "Show Route",
desc = "Some providers can often display incorrect routes"

name = "Limit",
desc = "Limit the number of results to display"

name = "Return Message on Empty",
desc = "The message to return if no flights are found"

## Screenshot

![Flight Overhead for Tidbyt](screenshot.png)

## Credit

Thank you to [The OpenSky Network](https://opensky-network.org), [HexDB](https://hexdb.io), and [ADSB.lol](https://www.adsb.lol) for providing free access to their data.
