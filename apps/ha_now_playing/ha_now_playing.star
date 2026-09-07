"""
Applet: HA Now Playing
Summary: Home Assistant Now Playing
Description: Display track details and artwork from any Home Assistant media_player entity.
Author: drudge, gabe565
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/default_cover.png", DEFAULT_COVER_ASSET = "file")
load("images/default_cover_2x.png", DEFAULT_COVER_2X_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_IMAGE = DEFAULT_COVER_ASSET.readall()

DEFAULT_IMAGE_2X = DEFAULT_COVER_2X_ASSET.readall()

SCROLL_TOGETHER = "together"
SCROLL_SEPARATE = "separate"
SCROLL_DISABLED = "disabled"
DEFAULT_SCROLL = SCROLL_TOGETHER
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024

def get_entity_status(ha_server, entity_id, token):
    if not ha_server or not valid_entity(entity_id) or not valid_token(token):
        return None

    rep = http.get("%s/api/states/%s" % (ha_server, entity_id), headers = {
        "Authorization": "Bearer %s" % token,
    })
    body = rep.body()
    if rep.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return None

    value = json.decode(body, {})
    if type(value) != "dict" or type(value.get("state")) != "string" or type(value.get("attributes")) != "dict":
        return None
    return value

def render_text_widget(content, width, color = "", font = "", scroll = DEFAULT_SCROLL):
    text = render.Text(
        content = content,
        color = color,
        font = font,
    )

    if scroll == SCROLL_DISABLED:
        return text

    offset = width if scroll == SCROLL_TOGETHER else 0
    return render.Marquee(
        width = width,
        offset_start = offset,
        offset_end = offset,
        child = text,
    )

def get_title_color(app_name):
    APP_COLORS = {
        "HBO": "#b535f6",
        "Movies": "#5ea8b8",
        "Music": "#e74e5a",
        "Netflix": "#e50914",
        "Overcast": "#fc7e0f",
        "Plex": "#e5a00d",
        "Podcasts": "#bf94ff",
        "Spotify": "#1db954",
        "TVMusic": "#e74e5a",
        "Twitch": "#bf94ff",
        "YouTube": "#f00000",
    }
    return APP_COLORS.get(app_name, "#009cc4")

def get_app_name(attributes):
    media_content_id = safe_text(attributes.get("media_content_id"))
    if media_content_id.startswith("spotify:"):
        return "Spotify"

    app_name = safe_text(attributes.get("app_name")) or safe_text(attributes.get("source"))
    if app_name:
        return app_name

    app_id = safe_text(attributes.get("app_id"))
    if not app_id:
        return safe_text(attributes.get("friendly_name"))

    APP_ID_FULL_MAP = {
        "com.apple.TVAirPlay": "AirPlay",
        "com.google.ios.youtube": "YouTube",
        "com.hbo.hbonow": "HBO",
        "com.plexapp.plex": "Plex",
        "com.timewarnercable.simulcast": "Spectrum TV",
    }
    if app_id in APP_ID_FULL_MAP:
        return APP_ID_FULL_MAP[app_id]

    name = app_id.split(".")[-1]

    APP_ID_SUFFIX_MAP = {
        "AIVApp": "Prime Video",
        "TVMovies": "Movies",
        "TVWatchList": "Apple TV",
    }
    return APP_ID_SUFFIX_MAP.get(name, name)

def main(config):
    ha_server = normalized_url(config.get("homeassistant_server"))
    entity_id = config.get("entity_id")
    token = config.get("auth")
    entity_status = get_entity_status(ha_server, entity_id, token)

    if not entity_status:
        return render.Root(
            child = render.WrappedText("Config missing or API error", color = "#ff0000"),
        )

    status = entity_status.get("state")
    attributes = entity_status.get("attributes", dict())

    if status != "playing":
        return []

    scale = 2 if canvas.is2x() else 1
    font = "terminus-18" if scale == 2 else "tb-8"

    media_title = safe_text(attributes.get("media_title"))

    media_image = None
    show_art = config.bool("show_art", True)
    if show_art:
        picture = attributes.get("entity_picture")
        url = ""
        if type(picture) == "string" and picture.startswith("/") and len(picture) <= 2048:
            url = ha_server + picture
        elif type(picture) == "string" and picture.startswith(ha_server + "/") and len(picture) <= 2048:
            url = picture
        if url:
            res = http.get(url, headers = {"Authorization": "Bearer %s" % token})
            body = res.body()
            image_type = res.headers.get("Content-Type", "")
            if res.status_code == 200 and len(body) <= MAX_IMAGE_BYTES and image_type.startswith("image/"):
                media_image = body
        if not media_image:
            media_image = DEFAULT_IMAGE_2X if scale >= 2 else DEFAULT_IMAGE

    media_content_type = safe_text(attributes.get("media_content_type"))
    media_artist = safe_text(attributes.get("media_artist"))
    friendly_name = safe_text(attributes.get("friendly_name", ""))
    app_name = get_app_name(attributes)
    media_artist = media_artist or friendly_name
    media_title = media_title or app_name
    media_album_name = safe_text(attributes.get("media_album_name")) or app_name

    line2 = media_album_name
    line1 = media_artist if line2 != media_artist else ""

    if media_content_type == "video" or app_name == "Overcast" or app_name == "Podcasts":
        line1 = line2
        line2 = media_artist

    if line2 == friendly_name:
        line2 = "→ %s" % line2

    media_title, line1, line2 = [s.replace("&amp;", "&") for s in (media_title, line1, line2)]

    if config.bool("upper"):
        media_title, line1, line2 = media_title.upper(), line1.upper(), line2.upper()

    image_size = 36 if scale == 2 else 17 * scale
    scroll = config.get("scroll", DEFAULT_SCROLL)
    secondary_width = 41 * scale if show_art else 60 * scale
    pad = 2 * scale

    return render.Root(
        delay = 50 if scale == 1 else 25,
        child = render.Column(
            children = [
                render.Padding(
                    pad = (pad, 2, 0 if show_art else pad, 0),
                    child = render_text_widget(media_title, 60 * scale, color = get_title_color(app_name), font = font, scroll = scroll),
                ),
                render.Padding(
                    pad = (pad, 2, 0 if show_art else pad, 0),
                    child = render.Row(
                        children = [
                            render.Image(
                                src = media_image,
                                height = image_size,
                                width = image_size,
                            ) if show_art else None,
                            render.Padding(
                                pad = (pad, 0, 0, 0) if show_art else 0,
                                child = render.Column(children = [
                                    render_text_widget(line1, width = secondary_width, font = font, scroll = scroll),
                                    render_text_widget(line2, width = secondary_width, color = "#cccccc", font = font, scroll = scroll),
                                ]),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "homeassistant_server",
                name = "Home Assistant Server",
                desc = "Public HTTPS root URL, such as a Home Assistant Cloud remote URL.",
                icon = "server",
            ),
            schema.Text(
                id = "entity_id",
                name = "Entity ID",
                icon = "play",
                desc = "Entity ID of the media player entity in Home Assistant",
            ),
            schema.Text(
                id = "auth",
                name = "Bearer Token",
                icon = "key",
                desc = "Long-lived access token for Home Assistant",
                secret = True,
            ),
            schema.Toggle(
                id = "upper",
                name = "Capitalize Text",
                desc = "Outputs text in upper case.",
                icon = "font",
                default = False,
            ),
            schema.Toggle(
                id = "show_art",
                name = "Show Album Art",
                desc = "Toggles album art.",
                icon = "image",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Mode",
                desc = "Changes how text lines scrolls.",
                icon = "gripLines",
                default = DEFAULT_SCROLL,
                options = [
                    schema.Option(
                        display = "Together",
                        value = SCROLL_TOGETHER,
                    ),
                    schema.Option(
                        display = "Separate",
                        value = SCROLL_SEPARATE,
                    ),
                    schema.Option(
                        display = "Disabled",
                        value = SCROLL_DISABLED,
                    ),
                ],
            ),
        ],
    )

def normalized_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]]):
        return ""
    parts = value.split("/", 3)
    host = parts[2].lower() if len(parts) >= 3 else ""
    if not host or "@" in host or ":" in host:
        return ""
    return value.rstrip("/")

def valid_entity(value):
    return type(value) == "string" and len(value) >= 3 and len(value) <= 128 and "." in value and all([char.isalnum() or char in "._-" for char in value.elems()])

def valid_token(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 4096 and not any([char in value for char in ["\r", "\n"]])

def safe_text(value):
    return value[:200] if type(value) == "string" else ""
