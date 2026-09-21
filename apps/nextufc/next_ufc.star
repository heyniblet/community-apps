# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Next UFC
Summary: Next UFC event
Description: Shows next upcoming UFC event with date and time.
Author: Stephen So
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon.png", ICON_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

ICON = ICON_ASSET.readall()

def main(config):
    now = time.now().in_location(config.get("$tz", "UTC"))
    end = now + time.parse_duration("2160h")
    url = "https://site.api.espn.com/apis/site/v2/sports/mma/ufc/scoreboard?dates=" + now.format("20060102") + "-" + end.format("20060102") + "&limit=100"
    response = http.get(url, ttl_seconds = 3600)
    if response.status_code != 200:
        fail("UFC schedule request failed: %d" % response.status_code)
    upcoming = []
    for item in json.decode(response.body()).get("events", []):
        if "UFC" not in item.get("name", ""):
            continue
        starts = time.parse_time(item["date"], format = "2006-01-02T15:04Z").in_location(config.get("$tz", "UTC"))
        if starts >= now:
            upcoming.append((starts, item["name"]))
    if not upcoming:
        return render.Root(child = render.WrappedText(content = "No UFC event scheduled", align = "center"))
    starts, event = sorted(upcoming)[0]
    date = starts.format("Jan 2")
    event_time = starts.format("3:04 PM")

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            render.Image(
                                src = ICON,
                            ),
                            pad = (1, 7, 0, 0),
                        ),
                        render.Padding(
                            render.Column(
                                children = [
                                    render.WrappedText(
                                        content = date,
                                        align = "center",
                                    ),
                                    render.WrappedText(
                                        content = event_time,
                                        align = "center",
                                    ),
                                ],
                            ),
                            pad = (1, 3, 1, 1),
                        ),
                    ],
                ),
                render.Padding(
                    render.Box(
                        width = 64,
                        height = 9,
                        color = "#a61212",
                        child = render.Marquee(
                            width = 64,
                            offset_start = 64,
                            offset_end = 64,
                            align = "center",
                            child = render.Text(
                                content = event,
                            ),
                        ),
                    ),
                    pad = (0, 0, 0, 0),
                ),
            ],
        ),
    )
