"""
Applet: AirNowAQI
Summary: Air Now AQI
Description: Displays preliminary current AQI values and levels provided by AirNow.gov.
Author: mjc-gh
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")

ACCURACY = "#.###"
MAX_RESPONSE_BYTES = 256 * 1024

DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

CATEGORY_NAME_TO_NUMBER = {
    "Good": 1,
    "Moderate": 2,
    "Unhealthy for Sensitive Groups": 3,
    "Unhealthy": 4,
    "Very Unhealthy": 5,
    "Hazardous": 6,
}

def get_alert_colors(category_num):
    if category_num == 1:
        return ("#00e400", "#000")
    elif category_num == 2:
        return ("#ffff00", "#000")
    elif category_num == 3:
        return ("#ff7e00", "#000")
    elif category_num == 4:
        return ("#ff0000", "#FFF")
    elif category_num == 5:
        return ("#8f3f97", "#FFF")
    else:
        return ("#7e0023", "#FFF")

def get_current_observation_url(api_key, lat, lng):
    return "https://www.airnowapi.org/aq/observation/current/ziplatlong/?format=application/json&latitude={lat}&longitude={lng}&api_key={api_key}".format(
        lat = lat,
        lng = lng,
        api_key = api_key,
    )

def normalize_observation(raw):
    if type(raw) != "dict":
        return None

    hour_raw = raw.get("hourObserved", 0)
    hour_text = str(hour_raw).split(":")[0]
    if not re.findall("^[0-9]{1,2}$", hour_text):
        return None
    hour = int(hour_text)

    category_name = raw.get("aqiCategoryName", "")
    if type(category_name) != "string":
        return None
    category_number = CATEGORY_NAME_TO_NUMBER.get(category_name, -1)

    parameter_name = raw.get("parameterName", "")
    if type(parameter_name) != "string":
        return None
    if parameter_name == "OZONE":
        parameter_name = "O3"

    aqi = raw.get("nowcastAQI", raw.get("aqi", -1))
    if type(aqi) not in ["int", "float"] or aqi < 0 or aqi > 1000:
        return None

    return {
        "DateObserved": raw.get("dateObserved", ""),
        "HourObserved": hour,
        "LocalTimeZone": raw.get("localTimeZone", ""),
        "ReportingArea": raw.get("reportingAreaName", "")[:80] if type(raw.get("reportingAreaName")) == "string" else "",
        "ParameterName": parameter_name,
        "AQI": int(aqi),
        "Category": {
            "Number": category_number,
            "Name": category_name,
        },
    }

def get_current_observation(api_key, lat, lng):
    response = http.get(url = get_current_observation_url(api_key, lat, lng))
    if response.status_code != 200:
        return {"error": response.status_code}

    body = response.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "list":
        return None

    for raw in data[:32]:
        observation = normalize_observation(raw)
        if observation and observation["ParameterName"] == "PM2.5":
            return observation

    return None

def render_alert_circle(aqi, alert_colors):
    scale = 2 if canvas.is2x() else 1

    bg_color, txt_color = alert_colors
    font = "terminus-28-light" if scale == 2 else "terminus-14-light"

    if aqi > 99:
        font = "terminus-24-light" if scale == 2 else "terminus-12"

    return render.Box(
        width = 26 * scale,
        height = 32 * scale,
        padding = 1 * scale,
        child = render.Circle(
            color = bg_color,
            diameter = 24 * scale,
            child = render.Text("%d" % (aqi), font = font, color = txt_color),
        ),
    )

def render_category_text(category_name, reporting_area, alert_colors):
    scale = 2 if canvas.is2x() else 1

    bg_color, _ = alert_colors
    font = "terminus-14" if scale == 2 else "tom-thumb"

    if category_name == "Unhealthy for Sensitive Groups":
        category_name = "Unhealthy for Sensitive"

    return render.Box(
        width = 38 * scale,
        height = 32 * scale,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.WrappedText(
                    category_name,
                    align = "center",
                    color = bg_color,
                    font = font,
                ),
                render.Marquee(
                    width = 30 * scale,
                    offset_start = 30 * scale,
                    offset_end = 30 * scale,
                    child = render.Text(
                        reporting_area,
                        color = "#DDD",
                        font = font,
                    ),
                ),
            ],
        ),
    )

def main(config):
    location_raw = config.get("location", DEFAULT_LOCATION)
    location = json.decode(location_raw, None) if type(location_raw) == "string" and len(location_raw) <= 8192 else None
    api_key_raw = config.get("api_key", "")
    api_key = api_key_raw.strip() if type(api_key_raw) == "string" else ""
    hide_below = config.get("hide_below", "0")

    if type(location) != "dict" or not re.findall("^[A-Za-z0-9-]{16,128}$", api_key):
        return render_error("Add a valid AirNow API key and location")
    if hide_below not in ["0", "2", "3", "4", "5", "6"]:
        return render_error("Choose a valid AQI threshold")

    lat_raw = str(location.get("lat", ""))
    lng_raw = str(location.get("lng", ""))
    number_pattern = "^-?[0-9]{1,3}(\\.[0-9]+)?$"
    if not re.findall(number_pattern, lat_raw) or not re.findall(number_pattern, lng_raw):
        return render_error("Choose a valid location")

    lat_value = float(lat_raw)
    lng_value = float(lng_raw)
    if lat_value < -90 or lat_value > 90 or lng_value < -180 or lng_value > 180:
        return render_error("Choose a valid location")

    lat = humanize.float(ACCURACY, lat_value)
    lng = humanize.float(ACCURACY, lng_value)

    observation = get_current_observation(api_key, lat, lng)

    if observation and "error" in observation:
        msg = "AirNow API Error: %d" % observation["error"]
        if observation["error"] == 429:
            msg = "Rate limit exceeded. Please configure your own API Key."
        return render_error(msg)

    if not observation:
        return render_error("No PM2.5 data for this location")

    category_num = observation["Category"]["Number"]
    category_name = observation["Category"]["Name"]
    reporting_area = observation["ReportingArea"]
    aqi = observation["AQI"]

    if category_num == -1:
        return render_error("Unknown AQI category")

    if category_num < int(hide_below):
        return []

    alert_colors = get_alert_colors(category_num)

    return render.Root(
        delay = 25 if canvas.is2x() else 50,
        child = render.Row(
            main_align = "start",
            expanded = True,
            children = [
                render_alert_circle(aqi, alert_colors),
                render_category_text(category_name, reporting_area, alert_colors),
            ],
        ),
    )

def render_error(message):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = message,
                width = canvas.width(),
                align = "center",
                color = "#f66",
            ),
        ),
    )

def get_schema():
    hide_options = [
        schema.Option(
            display = "Always Show",
            value = "0",
        ),
        schema.Option(
            display = "Moderate (51-100)",
            value = "2",
        ),
        schema.Option(
            display = "Unhealthy for Sensitive Groups (101-150)",
            value = "3",
        ),
        schema.Option(
            display = "Unhealthy (151-200)",
            value = "4",
        ),
        schema.Option(
            display = "Very Unhealthy (201-300)",
            value = "5",
        ),
        schema.Option(
            display = "Hazardous (301-500)",
            value = "6",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather radar.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "API Key, freely available at airnowapi.org",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "hide_below",
                name = "Hide Below",
                desc = "Hide this app if the AQI is below the chosen value.",
                icon = "eye",
                default = hide_options[0].value,
                options = hide_options,
            ),
        ],
    )
