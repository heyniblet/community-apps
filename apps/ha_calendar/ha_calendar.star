"""
Applet: HA Calendar
Summary: Events from Home Assistant Calendar
Description: Shows events from Home Assistant Calendar entities.
Author: radiocolin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_RESPONSE_BYTES = 1024 * 1024
MAX_EVENTS = 100

def main(config):
    scale = 2 if canvas.is2x() else 1
    ha_url = normalized_url(config.get("ha_url"))
    calendar_id = config.get("calendar", "calendar.default_calendar")
    api_key = config.get("api_key")
    header_color = safe_color(config.get("header_color"), "#800080")
    if not ha_url or not valid_calendar(calendar_id) or not valid_token(api_key):
        return message("Configure public HTTPS Home Assistant, token, and calendar", scale)

    now = time.now()
    end = now + time.parse_duration("48h")
    response = http.get(
        ha_url + "/api/calendars/" + calendar_id,
        params = {
            "start": now.format("2006-01-02T15:04:05Z07:00"),
            "end": end.format("2006-01-02T15:04:05Z07:00"),
        },
        headers = {"Authorization": "Bearer " + api_key},
    )
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return message("Home Assistant unavailable (%d)" % response.status_code, scale)
    events = json.decode(body, [])
    if type(events) != "list":
        return message("Invalid calendar response", scale)
    parsed = parse_events(events[:MAX_EVENTS], now)
    return render_calendar(parsed, header_color, now, scale)

def parse_events(events, now):
    today = now.format("2006-01-02")
    tomorrow = (now + time.parse_duration("24h")).format("2006-01-02")
    today_events = []
    tomorrow_events = []
    for event in events:
        if type(event) != "dict":
            continue
        start = event.get("start")
        finish = event.get("end")
        summary = event.get("summary")
        if type(start) != "dict" or type(summary) != "string" or not summary:
            continue
        summary = summary[:200]
        date = start.get("date")
        if valid_date(date):
            if date == today:
                today_events.append(("All-day", summary))
            elif date == tomorrow:
                tomorrow_events.append(("Tomorrow", summary))
            continue
        starts_at = start.get("dateTime")
        ends_at = finish.get("dateTime") if type(finish) == "dict" else None
        if not valid_timestamp(starts_at) or not valid_timestamp(ends_at):
            continue
        start_time = time.parse_time(starts_at)
        end_time = time.parse_time(ends_at)
        if starts_at[:10] == today and end_time > now:
            today_events.append((start_time.format("03:04pm"), summary))
        elif starts_at[:10] == tomorrow:
            tomorrow_events.append((start_time.format("Mon 03:04pm"), summary))
    return (today_events + tomorrow_events)[:6]

def render_calendar(events, header_color, now, scale):
    rows = [event_row(start, summary, header_color, scale) for start, summary in events]
    if not rows:
        rows = [event_row("", "No more events today", header_color, scale)]
    delay = int(10000 / len(rows))
    date_font = "tb-8" if scale == 1 else "terminus-18"
    return render.Root(
        delay = delay,
        child = render.Column(children = [
            render.Padding(child = render.Text(content = now.format("Mon, Jan 02"), font = date_font), pad = (1 * scale, 0, 0, 0)),
            render.Animation(children = rows),
        ]),
    )

def event_row(start, summary, header_color, scale):
    header_font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-12"
    event_font = "tom-thumb" if scale == 1 else "terminus-14"
    return render.Column(children = [
        render.Box(
            color = header_color,
            width = 64 * scale,
            height = 7 * scale,
            child = render.Padding(child = render.Text(start, font = header_font, color = "#fff"), pad = (1 * scale, 0, 0, 0)),
        ),
        render.Padding(child = render.WrappedText(content = summary, font = event_font, width = 64 * scale), pad = (1 * scale, 0, 0, 0)),
    ])

def message(text, scale):
    return render.Root(child = render.WrappedText(content = text, font = "tom-thumb" if scale == 1 else "terminus-14", width = 64 * scale))

def normalized_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]]):
        return ""
    parts = value.split("/", 3)
    host = parts[2].lower() if len(parts) >= 3 else ""
    if not host or "@" in host or ":" in host:
        return ""
    return value.rstrip("/")

def valid_calendar(value):
    return type(value) == "string" and value.startswith("calendar.") and len(value) <= 128 and all([char.isalnum() or char in "._-" for char in value.elems()])

def valid_token(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 4096 and not any([char in value for char in ["\r", "\n"]])

def valid_date(value):
    return type(value) == "string" and len(value) == 10 and value[4] == "-" and value[7] == "-" and (value[:4] + value[5:7] + value[8:]).isdigit()

def valid_timestamp(value):
    if type(value) != "string" or len(value) < 20 or len(value) > 35 or value[4] != "-" or value[7] != "-" or value[10] != "T":
        return False
    return value.endswith("Z") or "+" in value[19:] or "-" in value[19:]

def safe_color(value, fallback):
    if type(value) == "string" and len(value) in [4, 7] and value.startswith("#") and all([char.lower() in "0123456789abcdef" for char in value[1:].elems()]):
        return value
    return fallback

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "ha_url", name = "Home Assistant URL", desc = "Public HTTPS root URL, such as a Home Assistant Cloud remote URL.", icon = "house", default = ""),
            schema.Text(id = "api_key", name = "Long-Lived Access Token", desc = "Your Home Assistant long-lived access token.", icon = "key", default = "", secret = True),
            schema.Text(id = "calendar", name = "Calendar Entity ID", desc = "Calendar entity, such as calendar.default_calendar.", icon = "calendar", default = "calendar.default_calendar"),
            schema.Color(id = "header_color", name = "Header Color", desc = "Event header background color.", icon = "palette", default = "#800080"),
        ],
    )
