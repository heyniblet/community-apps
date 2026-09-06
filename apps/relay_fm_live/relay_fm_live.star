"""
Applet: Relay Live
Summary: Relay Live
Description: Shows live stream information for the Relay podcast network. Requires a Google Calendar API key.
Author: radiocolin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/relay_logo.png", RELAY_LOGO_ASSET = "file")
load("images/relay_logo@2x.png", RELAY_LOGO_2X_ASSET = "file")
load("qrcode.star", "qrcode")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RELAY_LOGO = RELAY_LOGO_ASSET.readall()
RELAY_LOGO_2X = RELAY_LOGO_2X_ASSET.readall()

LIVE_STATUS_URL = "https://www.relay.fm/live.json"
LIVE_PAGE_URL = "https://www.relay.fm/live"
LIVE_BROADCASTS_URL = "https://www.relay.fm/addtobroadcasts"
CALENDAR_URL = "https://www.googleapis.com/calendar/v3/calendars/relay.fm_t9pnsv6j91a3ra7o8l13cb9q3o%40group.calendar.google.com/events"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024
ART_HOSTS = ["https://relayfm.s3.amazonaws.com/", "https://cdn.relay.fm/", "https://www.relay.fm/", "https://relay.fm/"]

def generate_qrcode(url, scale):
    code = qrcode.generate(
        url = url,
        size = "large" if scale == 1 else "xlarge",
        color = "#fff",
        background = "#000",
    )
    return render.Image(src = code, width = 29 * scale, height = 29 * scale)

def get_live_status():
    response = http.get(LIVE_STATUS_URL, ttl_seconds = 60)
    body = response.body()
    status = json.decode(body, {}) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else {}
    return status if type(status) == "dict" else {}

def get_next_recording(status, timezone, scale, api_key):
    header_font = "tb-8" if scale == 1 else "terminus-14"
    title_font = "tb-8" if scale == 1 else "terminus-14"
    start_font = "tom-thumb" if scale == 1 else "terminus-12"

    if status.get("live") == True:
        broadcast = status.get("broadcast", {})
        broadcast = broadcast if type(broadcast) == "dict" else {}
        broadcast_title = broadcast.get("title", "Relay is live")
        broadcast_title = broadcast_title[:300] if type(broadcast_title) == "string" else "Relay is live"
        header = render.Text("Live:", font = header_font)
        title = render.Text(broadcast_title, font = title_font)
        start_text = render.Text("Relay", font = start_font)
    elif api_key:
        header = render.Text("Up next:", font = header_font)

        # We use a 1h grace period in the past for current events
        calendar_minimum_time = (time.now() - time.parse_duration("1h")).in_location("UTC").format("2006-01-02T15:04:05.000Z")
        response = http.get(
            CALENDAR_URL,
            headers = {"X-Goog-Api-Key": api_key},
            params = {"orderBy": "startTime", "singleEvents": "true", "timeMin": calendar_minimum_time},
        )
        body = response.body()
        calendar = json.decode(body, {}) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else {}
        items = calendar.get("items", []) if type(calendar) == "dict" else []
        if type(items) == "list" and items and type(items[0]) == "dict":
            next = items[0]
            summary = next.get("summary", "Relay recording")
            summary = summary[:300] if type(summary) == "string" else "Relay recording"
            title = render.Text(summary, font = title_font)

            # Handle dateTime or date for all-day events
            start_data = next.get("start", {})
            start_data = start_data if type(start_data) == "dict" else {}
            start_str = start_data.get("dateTime") or start_data.get("date")

            if type(start_str) != "string":
                start_text = render.Text("Relay", font = start_font)
            else:
                if len(start_str) == 10:  # YYYY-MM-DD
                    start = time.parse_time(start_str, "2006-01-02", timezone)
                elif len(start_str) == 20 and start_str.endswith("Z"):
                    start = time.parse_time(start_str, "2006-01-02T15:04:05Z")
                elif len(start_str) == 25 and (start_str[19] == "+" or start_str[19] == "-"):
                    start = time.parse_time(start_str, "2006-01-02T15:04:05-07:00")
                else:
                    start = None

                start_text = render.Text(start.in_location(timezone).format("Jan 2 3:04pm") if start else "Relay", font = start_font)
        else:
            header = render.Text("", font = header_font)
            title = render.Text("Check back soon for live streams", font = title_font)
            start_text = render.Text("Relay", font = start_font)
    else:
        header = render.Text("", font = header_font)
        title = render.Text("Check back soon for live streams", font = title_font)
        start_text = render.Text("Relay", font = start_font)

    return render.Box(
        child = render.Padding(
            child = render.Column(
                children = [
                    header,
                    render.Marquee(
                        width = 35 * scale,
                        child = title,
                        offset_start = 35 * scale,
                        offset_end = 35 * scale,
                    ),
                    render.Marquee(
                        width = 35 * scale,
                        child = start_text,
                        offset_start = 35 * scale,
                        offset_end = 35 * scale,
                    ),
                ],
            ),
            pad = (1 * scale, 0, 0, 0),
        ),
        height = 29 * scale,
        color = "#333F48",
    )

def main(config):
    scale = 2 if canvas.is2x() else 1
    timezone = config.get("timezone") or "America/New_York"
    api_key = config.get("api_key")
    api_key = api_key.strip() if type(api_key) == "string" else ""

    logo = RELAY_LOGO if scale == 1 else RELAY_LOGO_2X
    img = render.Image(src = logo, width = 29 * scale, height = 29 * scale)
    status = get_live_status()
    live = status.get("live") == True
    if not live and config.bool("live_only"):
        return []
    art = config.get("show_art") or LIVE_PAGE_URL
    if art not in ["show_art", "RELAY_LOGO", LIVE_PAGE_URL, LIVE_BROADCASTS_URL]:
        art = LIVE_PAGE_URL
    if live and art == "show_art":
        broadcast = status.get("broadcast", {})
        img_url = broadcast.get("show_art", "") if type(broadcast) == "dict" else ""
        if type(img_url) == "string" and any([img_url.startswith(host) for host in ART_HOSTS]):
            img_res = http.get(img_url, ttl_seconds = 3600)
            img_data = img_res.body()
            content_type = img_res.headers.get("Content-Type", img_res.headers.get("content-type", ""))
            if img_res.status_code == 200 and img_data and len(img_data) <= MAX_IMAGE_BYTES and content_type.startswith("image/"):
                img = render.Image(src = img_data, width = 29 * scale, height = 29 * scale)
    elif live and art == "RELAY_LOGO":
        img = render.Image(src = logo, width = 29 * scale, height = 29 * scale)
    elif live:
        img = generate_qrcode(art, scale)
    show = get_next_recording(status, timezone, scale, api_key)
    main_content = render.Row(
        children = [
            img,
            show,
        ],
        expanded = True,
    )
    return render.Root(
        max_age = 60,
        child = render.Column(
            children = [
                render.Box(height = 2 * scale, color = "#34657F"),
                main_content,
                render.Box(height = 1 * scale, color = "#34657F"),
            ],
        ),
    )

show_art_options = [
    schema.Option(
        display = "Display show art when live",
        value = "show_art",
    ),
    schema.Option(
        display = "Display QR when live: Relay website",
        value = LIVE_PAGE_URL,
    ),
    schema.Option(
        display = "Display QR when live: Broadcasts app",
        value = LIVE_BROADCASTS_URL,
    ),
    schema.Option(
        display = "Always show Relay logo",
        value = "RELAY_LOGO",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Google Calendar API Key",
                desc = "Required to show upcoming schedule.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "show_art",
                name = "Artwork/QR code settings",
                desc = "Settings for how to display artwork.",
                icon = "qrcode",
                default = show_art_options[0].value,
                options = show_art_options,
            ),
            schema.Toggle(
                id = "live_only",
                name = "Only show app when live",
                desc = "Don't show this app when nothing is live.",
                icon = "towerBroadcast",
                default = False,
            ),
        ],
    )
