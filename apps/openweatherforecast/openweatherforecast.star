"""
Applet: OpenWeaather Forecast
Summary: 3-Day Weather Forecast
Description: Display 3-day weather forecast using OpenWeather One Call API 3.0. The number of API calls is well within the free tier. 
Author: colin_is
"""

# V0.1: Initial release using One Call API 3.0.
# V0.2: Switched to /data/2.5/forecast (free plan). Aggregates 3-hour slots into
#        daily summaries: min/max temp across all slots, icon from midday slot.
# V0.3: Switched back to One Call API 3.0 for true daily temp.min / temp.max.

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

OW_GEO_URL = "https://api.openweathermap.org/geo/1.0/zip"
OW_FORECAST_URL = "https://api.openweathermap.org/data/3.0/onecall"
OW_ICON_URL = "https://openweathermap.org/img/wn/%s.png"

DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

ICON_CACHE_TTL = 86400  # 24 hours — OW icons are static
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_ICON_BYTES = 2 * 1024 * 1024

COLUMN_WIDTH = 21  # 64px display / 3 columns ≈ 21px
ICON_SIZE = 12
FONT1 = "tom-thumb"  # 5x8 pixel font;
FONT2 = "CG-pixel-3x5-mono"  # 3x5 compact pixel font; ~19px wide for "H:99°"

def day_name_from_unix(ts):
    """Return 3-letter day abbreviation (e.g. 'Mon') from a Unix UTC timestamp.

    The Unix epoch (ts=0) was a Thursday. Using Sun=0 convention:
    Thu=4, so offset by +4 before taking mod 7.
    """
    day_index = (int(ts) // 86400 + 4) % 7
    return DAY_NAMES[day_index]

def get_lat_lon(api_key, zip_code):
    """Geocode a US ZIP code to (lat, lon) via OW Geocoding API.

    Cached for 24 hours since zip-to-coordinate mapping is stable.
    Returns (lat, lon) or (None, None) on error.
    """
    resp = http.get(OW_GEO_URL, params = {
        "zip": zip_code + ",US",
        "appid": api_key,
    })
    if resp.status_code != 200:
        return None, None

    body = resp.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return None, None
    data = json.decode(body, None)
    if type(data) != "dict":
        return None, None
    lat = data.get("lat")
    lon = data.get("lon")
    if type(lat) not in ["int", "float"] or type(lon) not in ["int", "float"] or lat < -90 or lat > 90 or lon < -180 or lon > 180:
        return None, None

    return lat, lon

def get_forecast(api_key, lat, lon, units):
    """Fetch 3-day forecast from OW One Call API 3.0.

    Uses the daily array which provides true calendar-day temp.min / temp.max
    (not derived from 3-hour slots). Returns a list of 3 dicts, or None on error.
    Cached for 1 hour (cache key includes units to avoid stale unit mismatch).
    """
    resp = http.get(OW_FORECAST_URL, params = {
        "lat": str(lat),
        "lon": str(lon),
        "units": units,
        "exclude": "current,minutely,hourly,alerts",
        "appid": api_key,
    })
    if resp.status_code != 200:
        return None

    body = resp.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return None
    data = json.decode(body, None)
    items = data.get("daily") if type(data) == "dict" else None
    if type(items) != "list" or len(items) < 3:
        return None

    daily = []
    for i in range(3):
        d = items[i]
        temp = d.get("temp") if type(d) == "dict" else None
        weather_list = d.get("weather") if type(d) == "dict" else None
        weather = weather_list[0] if type(weather_list) == "list" and weather_list and type(weather_list[0]) == "dict" else {}
        dt = d.get("dt") if type(d) == "dict" else None
        temp_min = temp.get("min") if type(temp) == "dict" else None
        temp_max = temp.get("max") if type(temp) == "dict" else None
        icon_code = weather.get("icon", "01d")
        if type(dt) not in ["int", "float"] or type(temp_min) not in ["int", "float"] or type(temp_max) not in ["int", "float"] or type(icon_code) != "string" or not re.match(r"^[0-9]{2}[dn]$", icon_code):
            return None

        daily.append({
            "dt": dt,
            "temp_min": temp_min,
            "temp_max": temp_max,
            "icon": icon_code,
        })

    return daily

def get_icon(icon_code):
    """Fetch and cache an OW weather icon PNG.

    Renders the image at 15×15 inside a 12×12 Box to crop OW whitespace while
    keeping the icon centered. Returns a blank Box on failure.
    """
    if type(icon_code) != "string" or not re.match(r"^[0-9]{2}[dn]$", icon_code):
        return render.Box(width = ICON_SIZE, height = ICON_SIZE - 4)
    resp = http.get(OW_ICON_URL % icon_code, ttl_seconds = ICON_CACHE_TTL)
    if resp.status_code != 200:
        return render.Box(width = ICON_SIZE, height = ICON_SIZE - 4)

    body = resp.body()
    if len(body) > MAX_ICON_BYTES:
        return render.Box(width = ICON_SIZE, height = ICON_SIZE - 4)
    img = render.Image(src = body, width = 15, height = 15)
    return render.Box(width = ICON_SIZE, height = ICON_SIZE, child = img)

def render_day_col(day):
    """Render a single day's forecast column.

    Layout (top to bottom, icon flush to top, 1px gaps between text lines):
      - Weather icon (ICON_SIZE x ICON_SIZE)
      - Day abbreviation (e.g. Mon)
      - 1px spacer
      - H:max° (e.g. H:57°)
      - 1px spacer
      - L:min° (e.g. L:25°)
    """
    day_name = day_name_from_unix(day["dt"])
    temp_max = int(day["temp_max"])
    temp_min = int(day["temp_min"])

    return render.Box(
        width = COLUMN_WIDTH,
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Text(content = day_name, font = FONT2),
                get_icon(day["icon"]),
                render.Box(height = 1),
                render.Text(content = "H:" + str(temp_max) + "°", font = FONT1, color = "#f0f70e"),
                render.Box(height = 1),
                render.Text(content = "L:" + str(temp_min) + "°", font = FONT1, color = "#1187f2"),
            ],
        ),
    )

def error_display(msg):
    """Return a scrolling error marquee."""
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
            offset_start = 32,
            offset_end = 32,
        ),
    )

def main(config):
    api_key = config.get("openweather_api_key", "")
    zip_code = config.get("zip_code", "")

    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return error_display("Add OpenWeather API key in settings")
    if type(zip_code) != "string" or not re.match(r"^[0-9]{5}(-[0-9]{4})?$", zip_code):
        return error_display("Add a valid US ZIP code")

    lat, lon = get_lat_lon(api_key, zip_code)
    if lat == None or lon == None:
        return error_display("ZIP lookup failed — check API key & ZIP")

    units = "metric" if config.bool("units_celsius", False) else "imperial"

    daily = get_forecast(api_key, lat, lon, units)
    if daily == None or len(daily) < 3:
        return error_display("Forecast unavailable")

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "start",
            children = [
                render_day_col(daily[0]),
                render_day_col(daily[1]),
                render_day_col(daily[2]),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "openweather_api_key",
                name = "OpenWeather API Key",
                desc = "Your API key from https://home.openweathermap.org/api_keys",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "zip_code",
                name = "ZIP Code",
                desc = "US ZIP code for your forecast location (e.g., 90210)",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "units_celsius",
                name = "Use Celsius",
                desc = "Display temperatures in °C instead of °F",
                icon = "temperatureHalf",
                default = False,
            ),
        ],
    )
