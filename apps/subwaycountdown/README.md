<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Niblet downstream changes (2026-10-05)

The GTFS-realtime decoder walks each feed once for both platforms instead of
once per direction, converts only the header and the trips that call at the
station to byte lists instead of the whole 0.2-1 MB feed, and inside a trip
decodes only the stop updates that can name the station plus the last one for
the terminal. Arrivals, order and display are unchanged. On 2026-10-05, 168
renders (12 stations including multi-feed and shuttle stations, board and big
number layouts, each direction, 1x and 2x, three clock times, two recorded
feed sets) were byte-identical before and after. Decoding both platforms of
the B/D/F/M feed for W 4 St took about 15 ms instead of about 52 ms. No
settings changed.
