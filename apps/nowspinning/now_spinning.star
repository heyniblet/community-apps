"""
Applet: Now Spinning
Summary: Showcase your music
Description: Displays the name and cover of an artist's album. Not connected to any music service, you need to manually change the album. Type the album name to view available options, include the artist's name to help refine results.
Author: Daniel Sitnik
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/record_icon.webp", RECORD_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

RECORD_ICON = RECORD_ICON_ASSET.readall()

DEFAULT_FONT_NAME = "tb-8"
DEFAULT_HEADER_COLOR = "#1db954"
DEFAULT_ALBUM_COLOR = "#e833f2"
DEFAULT_ARTIST_COLOR = "#ffffff"
DEFAULT_HIDE_APP = False

DEFAULT_USER_AGENT = "Niblet/1.0 (https://heyniblet.com)"

COVER_CACHE_TTL = 86400  # 1 day

DEBUG = False

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        widget: Root widget tree.
    """

    album_font_name = config.str("album_font_name", DEFAULT_FONT_NAME)
    artist_font_name = config.str("artist_font_name", DEFAULT_FONT_NAME)
    header_color = config.str("header_color", DEFAULT_HEADER_COLOR)
    album_color = config.str("album_color", DEFAULT_ALBUM_COLOR)
    artist_color = config.str("artist_color", DEFAULT_ARTIST_COLOR)
    album = resolve_album(config.str("album", ""))
    hide_app = config.bool("hide_app", DEFAULT_HIDE_APP)
    dprint(album)

    # hides the app
    if hide_app:
        return []

    # if user has not selected an album yet, render default view
    if album["value"] == "none":
        return render_app(RECORD_ICON, "Select", "#fff", "album!", "#fff", header_color, DEFAULT_FONT_NAME, DEFAULT_FONT_NAME)

    # if there was an error, render default view
    if album["value"] == "error":
        return render_app(RECORD_ICON, "Error", "#f00", "try again", "#ff0", header_color, DEFAULT_FONT_NAME, DEFAULT_FONT_NAME)

    parts = album["value"].split("|")
    if len(parts) != 3:
        return render_app(RECORD_ICON, "Error", "#f00", "select album", "#ff0", header_color, DEFAULT_FONT_NAME, DEFAULT_FONT_NAME)
    album_name = parts[0][:120]
    artist_name = parts[1][:120]
    cover_id = parts[2]

    # get cover
    cover = get_cover(cover_id)

    # check if there was an error getting the cover
    if cover == None:
        cover = RECORD_ICON

    return render_app(cover, album_name, album_color, artist_name, artist_color, header_color, album_font_name, artist_font_name)

def get_cover(cover_id):
    """Retrieves the cover image for an album.

    Args:
        cover_id (str): MusicBrainz release-group ID.

    Returns:
        blob: Retrieved image content or None if not found/error.
    """

    if cover_id.startswith("https://coverartarchive.org/release-group/"):
        cover_id = cover_id[len("https://coverartarchive.org/release-group/"):].strip("/")
    if not valid_release_group_id(cover_id):
        return RECORD_ICON

    image_url = "https://images.weserv.nl/?url=coverartarchive.org/release-group/{}/front-250&w=64&h=64&fit=cover".format(cover_id)
    res = http.get(image_url, ttl_seconds = COVER_CACHE_TTL, headers = {
        "User-Agent": DEFAULT_USER_AGENT,
    })

    if res.status_code != 200:
        return RECORD_ICON
    body = res.body()
    return body if body and len(body) <= 2000000 else RECORD_ICON

def valid_release_group_id(value):
    return type(value) == "string" and len(value) == 36 and all([char in "0123456789abcdefABCDEF-" for char in value.codepoints()])

def resolve_album(value):
    value = value.strip()
    if not value:
        return {"value": "none"}
    if value.startswith("{"):
        legacy = json.decode(value)
        return legacy if type(legacy) == "dict" and type(legacy.get("value")) == "string" else {"value": "error"}
    return find_album(value[:120])

def find_album(query):
    url = "https://musicbrainz.org/ws/2/release-group/?query=releasegroup:{}%20AND%20status:official&limit=1&fmt=json".format(humanize.url_encode(query))
    res = http.get(url, ttl_seconds = COVER_CACHE_TTL, headers = {"User-Agent": DEFAULT_USER_AGENT})
    if res.status_code != 200:
        return {"value": "error"}
    body = res.body()
    if not body or len(body) > 1048576:
        return {"value": "error"}
    data = json.decode(body)
    releases = data.get("release-groups", []) if type(data) == "dict" else []
    if type(releases) != "list" or not releases or type(releases[0]) != "dict":
        return {"value": "error"}
    release = releases[0]
    artists = release.get("artist-credit", [])
    artist = artists[0].get("name", "Unknown") if type(artists) == "list" and artists and type(artists[0]) == "dict" else "Unknown"
    release_id = release.get("id", "")
    if not valid_release_group_id(release_id):
        return {"value": "error"}
    return {"value": "|".join([release.get("title", query), artist, release_id])}

def render_header(header_color):
    """Renders the app header widgets.

    Args:
        header_color (str): The hex color for the header text.

    Returns:
        widget: Widgets to render the app header.
    """

    return render.Box(
        width = 64,
        height = 6,
        child = render.Text("now spinning", font = "tom-thumb", color = header_color),
    )

def render_app(cover, album, album_color, artist, artist_color, header_color, album_font_name, artist_font_name):
    """Renders the app widget structure.

    Args:
        cover (blob): The album's cover art.
        album (str): The album's name.
        album_color (str): The hex color for the album name.
        artist (str): The artist' name.
        artist_color (str): The hex color for the artist name.
        header_color (str): The hex color for the app header.

    Returns:
        widget: Root widget structure.
    """

    return render.Root(
        delay = 80,
        child = render.Column(
            children = [
                render_header(header_color),
                render.Box(width = 64, height = 1, color = "#fff"),
                render.Padding(
                    pad = 1,
                    child = render.Row(
                        children = [
                            render.Image(height = 23, src = cover),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 39,
                                            child = render.Text(album, color = album_color, font = album_font_name),
                                        ),
                                        render.Marquee(
                                            width = 39,
                                            child = render.Text(artist, color = artist_color, font = artist_font_name),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    """Setup the schema for the configuration screen.

    Returns:
        schema: Schema for the configuration screen.
    """

    font_options = [
        schema.Option(display = "Small", value = "tom-thumb"),
        schema.Option(display = "Medium", value = DEFAULT_FONT_NAME),
        schema.Option(display = "Large", value = "Dina_r400-6"),
        schema.Option(display = "Extra Large", value = "6x13"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "album",
                name = "Album",
                desc = "Album name; add the artist to refine the match.",
                icon = "compactDisc",
                default = "",
            ),
            schema.Color(
                id = "header_color",
                name = "Header color",
                desc = "Color of the app name.",
                icon = "brush",
                default = DEFAULT_HEADER_COLOR,
            ),
            schema.Color(
                id = "album_color",
                name = "Album color",
                desc = "Color of the album name.",
                icon = "brush",
                default = DEFAULT_ALBUM_COLOR,
            ),
            schema.Dropdown(
                id = "album_font_name",
                name = "Album text size",
                desc = "Size of the album name text.",
                icon = "font",
                default = DEFAULT_FONT_NAME,
                options = font_options,
            ),
            schema.Color(
                id = "artist_color",
                name = "Artist color",
                desc = "Color of the artist name.",
                icon = "brush",
                default = DEFAULT_ARTIST_COLOR,
            ),
            schema.Dropdown(
                id = "artist_font_name",
                name = "Artist text size",
                desc = "Size of the artist name text.",
                icon = "font",
                default = DEFAULT_FONT_NAME,
                options = font_options,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide app",
                desc = "Removes the app from your rotation.",
                icon = "toggleOff",
                default = DEFAULT_HIDE_APP,
            ),
        ],
    )

def dprint(message):
    """Prints messages when in debug mode.

    Args:
        message (str): The message to print.
    """
    if DEBUG:
        print(message)
