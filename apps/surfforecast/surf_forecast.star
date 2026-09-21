# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Surf Forecast
Summary: Daily surf forecast
Description: Daily marine forecast for any coastal location using Open-Meteo.
Author: smith-kyle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/icon_e.png", ICON_E_ASSET = "file")
load("images/icon_n.png", ICON_N_ASSET = "file")
load("images/icon_ne.png", ICON_NE_ASSET = "file")
load("images/icon_nw.png", ICON_NW_ASSET = "file")
load("images/icon_s.png", ICON_S_ASSET = "file")
load("images/icon_se.png", ICON_SE_ASSET = "file")
load("images/icon_sw.png", ICON_SW_ASSET = "file")
load("images/icon_w.png", ICON_W_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

ICONS = [
    ICON_N_ASSET.readall(),
    ICON_NE_ASSET.readall(),
    ICON_E_ASSET.readall(),
    ICON_SE_ASSET.readall(),
    ICON_S_ASSET.readall(),
    ICON_SW_ASSET.readall(),
    ICON_W_ASSET.readall(),
    ICON_NW_ASSET.readall(),
]
DEFAULT_LOCATION = """
{
    "lat": "19.61",
    "lng": "-155.98",
    "description": "Banyans, Kailua-Kona, HI, USA",
    "locality": "Kailua-Kona",
    "timezone": "Pacific/Honolulu"
}
"""
MARINE_URL = "https://marine-api.open-meteo.com/v1/marine?latitude={lat}&longitude={lng}&current=wave_height,wave_direction,wave_period&hourly=wave_height,wave_direction,wave_period&forecast_hours=24&length_unit=imperial&timezone=auto"
FORECAST_INDEXES = [0, 3, 6, 9, 12, 15, 18, 21]
MAX_RESPONSE_BYTES = 1024 * 1024

def main(config):
    location = json.decode(config.str("location", DEFAULT_LOCATION), None)
    if type(location) != "dict":
        return error("Choose a coastal location")
    lat = float(location.get("lat", "999"))
    lng = float(location.get("lng", "999"))
    if lat < -90 or lat > 90 or lng < -180 or lng > 180:
        return error("Invalid location")

    response = http.get(MARINE_URL.format(lat = lat, lng = lng), ttl_seconds = 900)
    if response.status_code != 200 or len(response.body()) > MAX_RESPONSE_BYTES:
        return error("Forecast unavailable")
    payload = response.json()
    current = payload.get("current", {}) if type(payload) == "dict" else {}
    hourly = payload.get("hourly", {}) if type(payload) == "dict" else {}
    heights = hourly.get("wave_height", []) if type(hourly) == "dict" else []
    height = current.get("wave_height") if type(current) == "dict" else None
    direction = current.get("wave_direction") if type(current) == "dict" else None
    period = current.get("wave_period") if type(current) == "dict" else None
    if height == None or direction == None or period == None or len(heights) < 22:
        return error("No marine forecast here")
    if height < int(config.get("min_height", "0")):
        return []

    sampled = [heights[index] for index in FORECAST_INDEXES if heights[index] != None]
    if not sampled:
        return error("No wave data")
    tallest = max(sampled)
    bars = [
        render.Box(
            width = 6,
            height = max(1, int(math.round(value * 20 / tallest))),
            color = "#66b5fa" if index else "#18d64c",
        )
        for index, value in enumerate(sampled)
    ]
    name = config.str("display_name") or location.get("locality") or "Surf"
    direction_index = int(math.floor((direction + 22.5) / 45)) % 8

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = bars,
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                ),
                render.Column(
                    children = [
                        render.Marquee(
                            child = render.Text(name, font = "tb-8"),
                            width = 64,
                            align = "center",
                        ),
                        render.Row(
                            children = [
                                render.Text(humanize.ftoa(height, digits = 1) + "ft", font = "CG-pixel-3x5-mono"),
                                render.Image(src = ICONS[direction_index]),
                                render.Text("%ds" % int(math.round(period)), font = "CG-pixel-3x5-mono"),
                            ],
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                ),
            ],
        ),
    )

def error(message):
    return render.Root(
        child = render.WrappedText(
            content = message,
            font = "tb-8",
            width = 64,
            align = "center",
            color = "#66b5fa",
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Surf location",
                desc = "Choose a coastal forecast location.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "display_name",
                name = "Display name",
                desc = "Optional location name to display.",
                icon = "pencil",
            ),
            schema.Dropdown(
                id = "min_height",
                name = "Minimum size",
                desc = "Hide the app below this wave height.",
                icon = "water",
                default = "0",
                options = [schema.Option(display = "%d ft" % height, value = str(height)) for height in [0, 1, 2, 3, 4, 6, 8, 10, 15, 20, 25, 30]],
            ),
        ],
    )
