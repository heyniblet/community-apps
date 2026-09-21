<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# ShowTime Applet for Tidbyt

ShowTime will let you pick a region, and then pick a local area in that region. It will monitor your region for upcoming ticketed events in your region and display one at a time.

The source for this information is the Ticketmaster API. 

I don't use the http cache, which seems to be what folks want. The reason is that the Ticketmaster API returns a TON of extra information. So instead of caching all that and looking through it each time, I pull out the data I need, and cache just that.

Since it'll take a while to display all the cached items anyway, no point in going back to refresh the data that often. New events only pop up every few days or so at the most. 

In addition to picking your region, you can choose to display the event artwork in the background or not, add "closed caption" type black bars over the image to make the text easier to read, and you can also pick the colors of the title and detail scrolling text.

If anyone has an idea how to pick the most contrasting color based on the given image, I'd love to hear it!

![ShowTime Applet for Tidbyt](showtime.webp)
