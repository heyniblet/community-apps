<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# VisiblePlanets for Tidbyt

Pick a planet, and this app will display information on the direction you need to face, and the number of degrees you need to look up. It will also tell you how bright it is, is relative magnitude and explain what that means. It will also tell you if you need to wait till sunset, and will also tell you when sunset is for your location. It will also tell you the constellation the planet appears in.

For inner planets (mercury, venus), you can see these just before and after sunrise and sunset at times. Since their orbits are close to the sun, they will always be near the sun. When they aren't directly behind or in front of the sun, they can be seen in the morning or evening hours for a short time. Outer planets you'll usually need to wait until it is dark. The application will provide guidance, like telling you the planet will be easier to see after sunset in those cases.

You can have the app skip displaying information for planets that are below your horizon by selecting "Hide if not visible".

If you want to track more than one planet, I'd suggest installing this app once per planet you want to track, have it skip when not visible because it is below the horizon. You could set the hours of the applciation to only run during evening hours, but there is logic to cache the data until it makes sense to check again, so there won't be too many unneccesary API calls. Also, during the day, the display will be telling you where to look in the evening sky.

There is now an option to display a summary![Summary Display of VisiblePlanets](visibleplanets_summary.webp) It will present all visible planets by the first letter of the planet's name (or "E" in the case of mercury). The higher the letter is on the display, the higher in the sky it will appear. There are direction markers on the bottom row (S = South, W = West, N = North, E = East) to show you where in the sky to look. Also, the brighter the font, the brighter the planet will appear in the sky.

The idea behind the summar is to let you job down on a piece of paper the info you see. During daylight hours, this display will be the night sky at sunset, otherwise, it'll be within an hour of the current time depending on caching. As the earth spins on its axis, the stars appear to move, so this summary display is always changing, but we do cache and with the Tidbyt display, you're provided with a rough estimate of the night sky.

My suggestion is to display the summary, but also display an instance of this application for each particular planet you are interested in, for more detailed information.

![VisiblePlanets for Tidbyt](visibleplanets_detail.webp)
