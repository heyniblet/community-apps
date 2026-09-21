<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# ATC Radar for Tidbyt

Air Traffic Control Radar or ATC Radar

This application requires a RapidAPI API Key. 

Notes:
    Each initial green dot has a progress indicator next to it that flashes (unless it's heading off the screen).
    The flashing green dot indicates the direction the plane is going
    The brighter the flashing green dot, the closer to the ground
    The Yellow dot indicates YOUR location
    The Yellow dot is not always in the center, it will move to make better use of the available screen.
    You control how far to look for planes with the "Distance" selection.
    The screen will be optimized to best display the planes that are returned from the API
    The optional Information Bar:
        When displayed, you'll see some dots across the bottom of the screen. This represents the distance of the nearest plan as a percentage of the search area.
        So if your search area was 100km, and the nearest plane was 23km away, you'd see 23% of the dots lit up across the bottom of the screen.
        Also, green indicates newer data, yellow a little stale and red very stale data.
        More specifically, green will be displayed for the first third of the cache period you selected, yellow for the second third, and red for the final third.

The first 1000 API Calls are free per month. So if you want to keep under 1000 calls per month and just use the free service, pick the update "Update Frequency". 

To calculate the number of minutes for frequency to remain free:

    Hours Per Day of Display (You set the schedule for the app and the device to be active) / 32.25 * 60 (Where 1000/31 days is 32.25 calls per day and 60 is number of minutes per hour)

    For Example: 
        8 Hours Per Day / 32.25 * 60 = 14.886 - So pick a frequency of 15 minutes to update as often as possible without charges.
        12 Hours Per Day / 32.25 * 60 = 22.326 - so Pick a frequency of 25 minutes to update as often as possible without charges.
        24 Hours Per Day / 32.25 * 60 = 44.652 - so Pick a frequency of 45 minutes to update as often as possible without charges.

![ATC Radar for Tidbyt](atc_radar.webp)
