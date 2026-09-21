<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# LA Street Sweep

![LA Street Sweep](la_street_sweeping.gif)

Counts down to your next Los Angeles street sweeping day. A side-view car sits at
the curb while the street-sweeper truck creeps closer each day (the countdown chip
goes green → amber → red); on sweep day the car is gone and the sweeper passes the
freshly-cleaned spot.

## Configuration

Set, per side of the street:

- **Day** of the week the side is swept
- **Weeks** — `1st & 3rd`, `2nd & 4th`, `Every week`, or `Non-posted`
- **Time** window (start / end)

Optionally enable **Track the other side too** for the opposite curb.

Find your days at **streets.lacity.gov/services/street-sweeping**.

## How it works

Sweep dates come straight from the City of LA's public street-sweeping Google
Calendar feeds. Those feeds are already holiday-adjusted and contain no phantom
5th-week dates, so the next sweep is just the earliest feed date on your weekday
that isn't in the past — no address lookup, geocoding, or date math.

Author: Ryan Taylor (@ryantaylor16)
