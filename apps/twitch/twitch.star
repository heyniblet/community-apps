# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Twitch
Summary: Display info from Twitch
Description: Displays public Twitch channel information through DecAPI.
Author: drudge
"""

load("http.star", "http")
load("images/twitch_icon.png", TWITCH_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TWITCH_ICON = TWITCH_ICON_ASSET.readall()
DECAPI = "https://decapi.me/twitch/{}/{}"

def main(config):
    username = config.str("username", "twitch").strip().lower()
    if not username or len(username) > 25 or not username.replace("_", "").isalnum():
        return message("Invalid channel")

    uptime = fetch("uptime", username)
    if uptime == None:
        return message("Twitch data unavailable")
    live = "offline" not in uptime.lower()
    mode = config.str("display_mode", "status")
    if not live:
        detail = "OFFLINE"
    elif mode == "game":
        detail = fetch("game", username) or "LIVE"
    elif mode == "viewers":
        viewers = fetch("viewercount", username)
        detail = (viewers + " VIEWERS") if viewers else "LIVE"
    else:
        detail = "LIVE"

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(TWITCH_ICON, height = 16, width = 16),
                        render.Marquee(child = render.Text(detail, font = "tb-8", color = "#a970ff"), width = 46, align = "center"),
                    ],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
                render.Marquee(child = render.Text(username, color = "#aaaaaa"), width = 64, align = "center"),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def fetch(endpoint, username):
    response = http.get(DECAPI.format(endpoint, username), ttl_seconds = 300)
    if response.status_code != 200 or len(response.body()) > 1024:
        return None
    return response.body().strip()[:120]

def message(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#a970ff"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "username", name = "Channel", desc = "Twitch channel name.", icon = "user", default = "twitch"),
            schema.Dropdown(
                id = "display_mode",
                name = "Display",
                desc = "Information to show while the channel is live.",
                icon = "display",
                default = "status",
                options = [
                    schema.Option(display = "Live status", value = "status"),
                    schema.Option(display = "Game", value = "game"),
                    schema.Option(display = "Viewer count", value = "viewers"),
                ],
            ),
        ],
    )
