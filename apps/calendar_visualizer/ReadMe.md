<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

# Calendar Visualizer for TronByt

Concept: Ctrl-G

Created by: Ctrl-G & Google's Gemini (Flash 3.6 - I think, although it might have been upgraded during this development).

Summary: Calendar Visualization App

Description: Displays a very dense visualization of events from a Google Calendar iCal URL.  Probably only helpful for
persons who don't have a lot of closely spaced events in their google calendar.  This was produced because I always wanted
to see the spacial relationship between the current time and my next 'event / meeting'.

The calendar graphing area shows 62 days, one day for each vertical column of LEDs.  Each dot in the vertical column indicates the following time:

<i>Calendar Visualizer - No animation</i>
<img src = "./calendar_visualizer-DispExplain.gif" >

Future expansion:

        *.  Blinking colon of the clock.
        
        *.  Fixed a problem with displaying recurring events when they were created in
            a ST / DST time different than the one which is currently being observed.
            Now there is another similar problem with events being shifted for the part
            of the display that is not current, ie event in a time zone  that is different
            than the one currently being displayed, but this makes more since than what
            was being displayed before so I'll fix this later.

        *.  Color entry for each of the hard coded color entries above.  This to be
            superseded by ...

        *.  Calendar Notes field Color keys for calviz use, like: "CalViz:Color:#EA3FF7"
            which will then make the event show up in Fuchsia (if #EA3FF7 is Fuchsia).
            I believe this would be a good color for important events and in particular
            important events with are critical but that you don't really want to do.  You
            might also like to use #22B14C for Financial events, for instance.


## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.
