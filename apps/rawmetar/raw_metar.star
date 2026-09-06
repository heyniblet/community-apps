"""
Applet: Raw METAR
Summary: METAR text weather reports
Description: METAR text weather reports for pilots.
Author: tabrindle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ADDS_URL = "https://aviationweather.gov/api/data/metar?ids=%s&format=json&hours=2"
REQUEST_HEADERS = {"User-Agent": "Niblet/1.0 (hello@heyniblet.com)"}
MAX_RESPONSE_BYTES = 64 * 1024
MAX_METAR_LENGTH = 384
CACHE_SECONDS = 300

def main(config):
    station_id = config.str("station_id", "KMCO").strip().upper()
    if len(station_id) == 3:
        station_id = "K" + station_id
    if len(station_id) != 4 or not all([char.isalnum() for char in station_id.codepoints()]):
        return message("Invalid station ID")

    seconds_value = config.str("seconds", "4").strip()
    seconds = int(seconds_value) if seconds_value and len(seconds_value) <= 2 and all([char.isdigit() for char in seconds_value.codepoints()]) else 4
    seconds = max(1, min(seconds, 10))

    response = http.get(ADDS_URL % station_id, headers = REQUEST_HEADERS, ttl_seconds = CACHE_SECONDS)
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "list" or len(data) == 0 or type(data[0]) != "dict":
        return message("METAR unavailable")
    content = data[0].get("rawOb")
    if type(content) != "string" or not content:
        return message("METAR unavailable")
    content = content[:MAX_METAR_LENGTH]

    max_line_width = 12
    lines_per_page = 4

    lines_to_display = [content[i:i + max_line_width] for i in range(0, len(content), max_line_width)]
    pages_to_display = [lines_to_display[i:i + lines_per_page] for i in range(0, len(lines_to_display), lines_per_page)]

    frames = []
    for page in pages_to_display:
        for _ in range(seconds * 20):
            frames.append(page)

    return render.Root(
        max_age = CACHE_SECONDS,
        child = render.Animation(
            children = [
                render.WrappedText(
                    content = "".join(text),
                    font = "tb-8",
                )
                for text in frames
            ],
        ),
    )

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, align = "center", color = "#f00")))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station_id",
                name = "Station ID to lookup",
                desc = "The station ID to get the METAR for",
                icon = "locationPin",
            ),
            schema.Text(
                id = "seconds",
                name = "Seconds per page of data",
                desc = "How long to display each METAR page for",
                icon = "clock",
            ),
        ],
    )
