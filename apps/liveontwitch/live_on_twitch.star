# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Live on Twitch
Summary: See who's live on Twitch
Description: Shows which configured Twitch channels are currently live through DecAPI.
Author: daltonclaybrook
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DECAPI_UPTIME = "https://decapi.me/twitch/uptime/{}"

def main(config):
    channels = unique_channels(config.str("channels", "twitch,ninja,shroud"))
    live = []
    for channel in channels:
        response = http.get(DECAPI_UPTIME.format(channel), ttl_seconds = 300)
        if response.status_code == 200 and len(response.body()) <= 256 and "offline" not in response.body().lower():
            live.append(channel)
    if not live:
        return render_message("No configured channels are live")
    return render.Root(
        child = render.Column(
            children = [
                render.Text("LIVE ON TWITCH", font = "tom-thumb", color = "#a970ff"),
                render.Marquee(
                    child = render.Text("  •  ".join(live), color = "#ffffff"),
                    width = 64,
                    align = "center",
                ),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def unique_channels(value):
    channels = []
    for raw in value.split(","):
        channel = raw.strip().lower()
        if channel and len(channel) <= 25 and channel.replace("_", "").isalnum() and channel not in channels:
            channels.append(channel)
        if len(channels) == 5:
            break
    return channels

def render_message(message):
    return render.Root(child = render.WrappedText(message, font = "tom-thumb", width = 62, align = "center", color = "#a970ff"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "channels",
                name = "Channels",
                desc = "Up to five comma-separated Twitch channel names.",
                icon = "twitch",
                default = "twitch,ninja,shroud",
            ),
        ],
    )
