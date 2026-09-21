# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Xbox Gamerscore
Summary: Display Xbox Gamerscore
Description: Shows an Xbox Live profile by gamertag through OpenXBL.
Author: Nick Penree
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API = "https://api.xbl.io/v2/player/gamertag/{}"
MAX_RESPONSE_BYTES = 256 * 1024

def main(config):
    api_key = config.str("api_key")
    gamertag = config.str("gamertag", "Major Nelson").strip()
    if not api_key:
        return card("Major Nelson", "182365", "")
    if not gamertag or len(gamertag) > 32 or any([char in gamertag for char in ["/", "?", "#", "\r", "\n"]]):
        return message("Invalid gamertag")

    response = http.get(
        API.format(gamertag.replace(" ", "%20")),
        headers = {"X-Authorization": api_key, "Accept": "application/json"},
        ttl_seconds = 300,
    )
    if response.status_code != 200 or len(response.body()) > MAX_RESPONSE_BYTES:
        return message("Xbox profile unavailable")
    profile = response.json()
    if type(profile) != "dict":
        return message("Invalid Xbox profile")
    return card(
        str(profile.get("gamertag") or profile.get("modernGamertag") or gamertag),
        str(profile.get("gamerscore") or profile.get("gamerScore") or "0"),
        str(profile.get("profilePicture") or profile.get("displayPicRaw") or "") if config.bool("show_avatar", False) else "",
    )

def card(gamertag, gamerscore, avatar_url):
    avatar = None
    if avatar_url.startswith("https://images-eds-ssl.xboxlive.com/"):
        response = http.get(avatar_url, ttl_seconds = 3600)
        if response.status_code == 200 and len(response.body()) <= 2 * 1024 * 1024:
            avatar = render.Image(src = response.body(), width = 14, height = 14)
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [avatar, render.Text("G", font = "tb-8", color = "#52b043"), render.Text(gamerscore[:12], font = "6x13")],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
                render.Marquee(child = render.Text(gamertag[:64], color = "#52b043"), width = 64, align = "center"),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def message(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#52b043"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "api_key", name = "OpenXBL API key", desc = "A free OpenXBL API key from xbl.io.", icon = "key", secret = True),
            schema.Text(id = "gamertag", name = "Gamertag", desc = "Xbox gamertag to display.", icon = "gamepad", default = "Major Nelson"),
            schema.Toggle(id = "show_avatar", name = "Show avatar", desc = "Show the profile image when available.", icon = "image", default = False),
        ],
    )
