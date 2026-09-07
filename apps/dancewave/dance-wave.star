"""
Dance Wave - A Tidbyt app showing the currently playing song from Dance Wave Online Radio
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/dw_logo.gif", DW_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DW_LOGO = DW_LOGO_ASSET.readall()

# Dance Wave Logo

# Cache TTL for API responses
CACHE_TTL_SECONDS = 30  # Cache for 30 seconds (more frequent updates for live radio)
PLAYLIST_URL = "https://dancewave.online/api/playlist.cgi?user=dw8080&streamid=1&mount=/dw.ogg&num=1&excludestring=Dance%20Wave&out=json"

def config_color(config):
    color = config.get("text_color", "#0ff1b2")
    return color if type(color) == "string" and len(color) in [4, 7] and color.startswith("#") and all([char in "0123456789abcdefABCDEF" for char in color[1:].codepoints()]) else "#0ff1b2"

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured colors
    text_color = config_color(config)

    # Fetch current playing track
    current_track = fetch_current_track()

    if current_track == None:
        # Fallback display if API is unavailable
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = DW_LOGO,
                            width = 32,
                            height = 32,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "Dance Wave Radio • Loading...",
                                font = "tb-8",
                                color = text_color,
                            ),
                            scroll_direction = "horizontal",
                        ),
                    ],
                ),
            ),
        )

    # Display current track info
    artist = current_track.get("artist", "Unknown Artist")
    title = current_track.get("title", "Unknown Track")

    # Build the display children
    children = [
        render.Image(
            src = DW_LOGO,
            width = 32,
            height = 16,
        ),
        render.Marquee(
            width = 64,
            child = render.Text(
                content = artist + " • " + title,
                font = "tb-8",
                color = text_color,
            ),
            scroll_direction = "horizontal",
        ),
    ]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def get_schema():
    """
    Configuration schema for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for track information text",
                icon = "palette",
                default = "#0ff1b2",
            ),
        ],
    )

def fetch_current_track():
    """
    Fetch current track from Dance Wave Radio API
    """
    headers = {
        "Referer": "https://dancewave.online/tracklist/",
    }

    resp = http.get(PLAYLIST_URL, headers = headers, ttl_seconds = CACHE_TTL_SECONDS)
    if resp.status_code != 200 or len(resp.body()) > 64 * 1024:
        return None

    data = json.decode(resp.body(), None)
    playlist = data.get("mscp", {}).get("playlist") if type(data) == "dict" and type(data.get("mscp")) == "dict" else None
    current = playlist[0] if type(playlist) == "list" and playlist and type(playlist[0]) == "dict" else {}
    artist = current.get("artist")
    title = current.get("title")
    if type(artist) != "string" or type(title) != "string":
        return None
    return {"artist": artist[:100] or "Unknown Artist", "title": title[:160] or "Unknown Track"}
