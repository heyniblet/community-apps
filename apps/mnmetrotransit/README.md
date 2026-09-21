<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

This new app is the "MN Metro Transit" app as it encompasses everything within the Minneapolis - St. Paul Metropolitan area transit department offerings (Bus and Train). This new app adjusts the look of the original app to accommodate for some of the longer naming conventions of the bus lines and also has some additional colors and directional features to go along with it, including color matched name plates for BRT routes. Additionally, the Arterial BRT (ABRT) and standard bus routes have placards to mimic the signage on the respective busses. Light Rail Transit has been redesigned to have white lettering (as opposed to black lettering on BRT) to match the alteration in naming and direction within the app.

Also added to the app is an error screen for "Invalid Stop ID" so users can be certain if they have the right stop code entered. Finally, there are also indications for when there are no more transit departures at a stop for the night (which previously would cause the app to stop functioning due to calling an empty list). The app should also be capable of displaying future ABRT lines to be added in 2023 and 2024 (letters B, and E-H).

There are a lot of improvements coming to the Minnesota Metro area over the next 10 years to bring fast, frequent, and reliable transit to the region, and what better way to stay up to date on what's coming to a stop near you than this app bringing you arrival times of all forms, down to the minute!

A big thanks to @AmillionAirs for laying the foundation with the original app, and for all of the guidance along the way (as this was my first Tidbyt app/modification) with linting and formatting. Hope it is up to snuff for all to enjoy!

Ver 1.1: Custom stop naming fuctionality was added, as well as support for the upcoming Purple and Gold BRT lines.

![](https://github.com/GE-Ninety/community/blob/main/apps/mnmetrotransit/mn_metro_transit.gif)
