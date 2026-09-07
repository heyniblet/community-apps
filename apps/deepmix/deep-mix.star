"""
Deep Mix - A Tidbyt app showing the currently playing song from Deep Mix Online Radio
"""

load("html.star", "html")
load("http.star", "http")
load("images/dm_logo.gif", DM_LOGO_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DM_LOGO = DM_LOGO_ASSET.readall()

# Deep Mix Logo

# Cache TTL for API responses
DEEP_MIX_URL = "https://deepmix.net/"
CACHE_TTL_SECONDS = 30

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured colors
    text_color = config.get("text_color", "#0ff1b2")
    if type(text_color) != "string" or not re.match(r"^#[0-9a-fA-F]{6}$", text_color):
        text_color = "#0ff1b2"

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
                            src = DM_LOGO,
                            # width = 128,
                            # height = 64,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "Deep Mix Radio • Loading...",
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
    # artist = current_track.get("artist", "Unknown Artist")
    title = current_track.get("title", "Unknown Track")

    # Build the display children
    children = [
        render.Image(
            src = DM_LOGO,
            width = 32,
            height = 16,
        ),
    ]

    # Use centered text for short titles, marquee for long ones
    if len(title) < 14:
        children.append(
            render.Text(
                content = title,
                font = "tb-8",
                color = text_color,
            ),
        )
    else:
        children.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = title,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            ),
        )

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
    Fetch current track from Deep Mix Radio's first-party HTTPS page.
    """
    response = http.get(
        DEEP_MIX_URL,
        ttl_seconds = CACHE_TTL_SECONDS,
        headers = {"User-Agent": "Niblet Deep Mix/1.0 (+https://heyniblet.com)"},
    )
    body = response.body()
    if response.status_code != 200 or len(body) > 256 * 1024:
        return None

    node = html(body).find("#now-playing-title")
    song_text = node.text().strip() if node else ""
    if not song_text or len(song_text) > 200:
        return None

    parts = song_text.split(" - ", 1)
    return {
        "artist": parts[0].strip() if len(parts) == 2 else "Unknown Artist",
        "title": parts[1].strip() if len(parts) == 2 else song_text,
    }
