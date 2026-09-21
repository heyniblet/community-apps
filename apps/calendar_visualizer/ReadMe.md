<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Calendar Visualizer for TronByt

Concept: Ctrl-G

Created by: Ctrl-G & Google's Gemini (Flash 3.6 - I think, although it might have been upgraded during this development).

Summary: Calendar Visualization App

Description: Displays a very dense visualization of events from a Google Calendar iCal URL.  Probably only helpful for
persons who don't have a lot of closely spaced events in their Google Calendar.  This was produced because I always wanted
to see the spatial relationship between the current time and my next 'event / meeting'.

The calendar graphing area shows 62 days, one day for each vertical column of LEDs.  Each dot in the vertical column indicates the following time:

<i>Calendar Visualizer - No animation</i>
<img src="./calendar_visualizer-DispExplain.gif" alt="Calendar Visualizer display explanation">

Future expansion:

        *.  Blinking colon of the clock.
        
        *.  Blinking current time dot (Done and optional!) on event graph display possibly
            to coincide with blinking colon of the clock (which is currently not blinking).
            The event graph display dot to reveal of the item under the dot, if any, when
            the dot is off.

        *.  Color entry for each of the hard coded color entries above.  This to be
            superseded by ...

        *.  Calendar Notes field Color keys for calviz use, like: "CalViz:Color:#EA3FF7"
            which will then make the event show up in Fuchsia (if #EA3FF7 is Fuchsia).
            I believe this would be a good color for important events and in particular
            important events with are critical but that you don't really want to do.  You
            might also like to use #22B14C for Financial events, for instance.

