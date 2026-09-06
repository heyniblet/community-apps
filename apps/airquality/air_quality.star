"""
Applet: Air Quality
Summary: Monitor local air quality
Description: Monitor your local air quality with the OpenWeather Air Pollution API.
Author: Daniel Sitnik
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# default location to be shown if none is configured, Tidbyt HQ :)
DEFAULT_LOCATION = json.encode({
    "lat": "40.6969512",
    "lng": "-73.9538453",
    "description": "Brooklyn, NY, USA",
    "locality": "Tidbyt",
    "place_id": "ChIJr3Hjqu5bwokRmeukysQhFCU",
    "timezone": "America/New_York",
})

# default options
DEFAULT_LOCATION_NAME = ""
DEFAULT_24H_CLOCK = False
DEFAULT_DISPLAY_TYPE = "forecast"
DEFAULT_SCROLL_AQI = False
DEFAULT_COLOR_AQI1 = "#00ff38"  # green (good)
DEFAULT_COLOR_AQI2 = "#f9cd03"  # yellow (fair)
DEFAULT_COLOR_AQI3 = "#ffa500"  # orange (moderate)
DEFAULT_COLOR_AQI4 = "#ff0000"  # red (poor)
DEFAULT_COLOR_AQI5 = "#ff41ff"  # purple (very poor)
DEFAULT_COLOR_AQI6 = "#ffffff"  # white (unknown)

# OpenWeather API base url
OW_API_URL = "https://api.openweathermap.org"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
POLLUTANT_CODES = ["so2", "no2", "co", "pm2_5", "pm10", "o3"]

def error_display(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, align = "center", color = "#f66"))

def main(config):
    use24h = config.bool("use24h", DEFAULT_24H_CLOCK)
    display_type = config.str("display_type", DEFAULT_DISPLAY_TYPE)
    location_name = config.str("location_name", DEFAULT_LOCATION_NAME)
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg, None)
    if type(location) != "dict" or type(location.get("lat")) != "string" or type(location.get("lng")) != "string" or type(location.get("timezone")) != "string" or type(location.get("locality")) != "string" or not re.match(r"^-?[0-9]+(\.[0-9]+)?$", location["lat"]) or not re.match(r"^-?[0-9]+(\.[0-9]+)?$", location["lng"]):
        return error_display("Choose a valid location")
    timezone = location["timezone"]
    if len(timezone) > 80 or not re.match(r"^[A-Za-z0-9_+\-/]+$", timezone):
        return error_display("Choose a valid location")
    if float(location["lat"]) < -90 or float(location["lat"]) > 90 or float(location["lng"]) < -180 or float(location["lng"]) > 180:
        return error_display("Choose a valid location")
    pollutant_code = config.str("pollutant", "")
    if display_type not in [DEFAULT_DISPLAY_TYPE, "pollutants"]:
        display_type = DEFAULT_DISPLAY_TYPE
    if pollutant_code not in POLLUTANT_CODES:
        pollutant_code = POLLUTANT_CODES[0]
    location_name = location_name[:120]

    # load api key
    apikey = config.str("api_key", "")

    # validate if api key was provided
    if not apikey or len(apikey) > 2048 or "\r" in apikey or "\n" in apikey:
        return render.Root(
            render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    main_align = "space_around",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Text("please"),
                        render.Text("set API key"),
                        render.Text("in config", color = "#0f0", font = "tom-thumb"),
                    ],
                ),
            ),
        )

    data = get_data(location, apikey)
    if data == None:
        return error_display("Air quality data unavailable")

    # use locality from selected place
    locality = location["locality"][:120]

    # if user chose to override location name
    if location_name != "":
        locality = location_name

    # find data point closest to the current time
    # this allows using the cached data up to the
    # next 6th hour, where a refresh will happen
    now = time.now().unix
    index = 0

    for i in range(0, len(data["list"])):
        if int(data["list"][i]["dt"]) <= now:
            index = i
        else:
            break

    # retrieve air quality index
    aqi = data["list"][index]["main"]["aqi"] or 6
    aqi_color = get_color_for_aqi(aqi, config)
    aqi_text = get_text_for_aqi(aqi, config)

    # retrieve forecasts for 6 and 12 hours
    aqi6 = data["list"][6]["main"]["aqi"] or 6
    aqi6_color = get_color_for_aqi(aqi6, config)
    aqi6_hour = get_formatted_hour(use24h, data["list"][6]["dt"] or (time.now().unix + 21600), timezone)

    aqi12 = data["list"][12]["main"]["aqi"] or 6
    aqi12_color = get_color_for_aqi(aqi12, config)
    aqi12_hour = get_formatted_hour(use24h, data["list"][12]["dt"] or (time.now().unix + 43200), timezone)

    displayed_content = None
    if (display_type == DEFAULT_DISPLAY_TYPE):
        displayed_content = render_forecast(locality, aqi6_color, aqi6_hour, aqi12_color, aqi12_hour)
    else:
        pollutant_level = data["list"][index]["components"][pollutant_code]
        displayed_content = render_pollutant(pollutant_code, pollutant_level, config)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    color = "#151968",
                    height = 8,
                    child = render.Text("AIR QUALITY", font = "tb-8", color = "#01ffff"),
                ),
                render.Row(
                    children = [
                        render.Padding(
                            pad = 2,
                            child = render.Circle(
                                color = aqi_color,
                                diameter = 20,
                                child = render.Circle(
                                    color = "#1a1a1a",
                                    diameter = 16,
                                    child = render.Marquee(
                                        width = 10,
                                        align = "center",
                                        child = render.Text(aqi_text, font = "6x13", color = aqi_color),
                                    ),
                                ),
                            ),
                        ),
                        # conditional separator bar when display_type is pollutants
                        (render.Box(width = 1, height = 24, color = "#3b3b3b") if display_type == "pollutants" else None),
                        render.Padding(
                            pad = 2,
                            child = render.Column(
                                children = displayed_content,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    display_options = [
        schema.Option(display = "Forecast (6 and 12 hours)", value = DEFAULT_DISPLAY_TYPE),
        schema.Option(display = "Pollutant levels", value = "pollutants"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display air quality.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "OpenWeather API Key",
                desc = "Your OpenWeather API key. See https://openweathermap.org/api/air-pollution for details.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "display_type",
                name = "Display",
                desc = "What should be displayed by the app.",
                icon = "display",
                default = display_options[0].value,
                options = display_options,
            ),
            schema.Text(
                id = "location_name",
                name = "Location name (blank for default)",
                desc = "Override location name, for example home or office.",
                icon = "font",
                default = DEFAULT_LOCATION_NAME,
            ),
            schema.Toggle(
                id = "use24h",
                name = "24-Hour Clock",
                desc = "Use 24-Hour format in forecast.",
                icon = "clock",
                default = DEFAULT_24H_CLOCK,
            ),
            schema.Dropdown(
                id = "pollutant",
                name = "Pollutant",
                desc = "Pollutant to display when pollutant mode is selected.",
                icon = "smog",
                default = POLLUTANT_CODES[0],
                options = [
                    schema.Option(display = "SO2 (Sulphur Dioxide)", value = "so2"),
                    schema.Option(display = "NO2 (Nitrogen Dioxide)", value = "no2"),
                    schema.Option(display = "CO (Carbon Monoxide)", value = "co"),
                    schema.Option(display = "PM2.5 (Fine Particulate)", value = "pm2_5"),
                    schema.Option(display = "PM10 (Coarse Particulate)", value = "pm10"),
                    schema.Option(display = "O3 (Ozone)", value = "o3"),
                ],
            ),
            schema.Toggle(
                id = "scroll_desc",
                name = "Scroll Description",
                desc = "Scroll air quality description.",
                icon = "arrowsLeftRightToLine",
                default = DEFAULT_SCROLL_AQI,
            ),
            schema.Color(
                id = "aqi1_color",
                name = "Good Quality Color",
                desc = "Color for good air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI1,
            ),
            schema.Color(
                id = "aqi2_color",
                name = "Fair Quality Color",
                desc = "Color for fair air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI2,
            ),
            schema.Color(
                id = "aqi3_color",
                name = "Moderate Quality Color",
                desc = "Color for moderate air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI3,
            ),
            schema.Color(
                id = "aqi4_color",
                name = "Poor Quality Color",
                desc = "Color for poor air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI4,
            ),
            schema.Color(
                id = "aqi5_color",
                name = "Very Poor Quality Color",
                desc = "Color for very poor air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI5,
            ),
            schema.Color(
                id = "aqi6_color",
                name = "Unknown Quality Color",
                desc = "Color for unknown air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI6,
            ),
        ],
    )

def get_data(location, apikey):
    # round coordinates to avoid exposing user's precise location
    lat = get_rounded_coord(location["lat"])
    lon = get_rounded_coord(location["lng"])

    # call openweather api
    res = http.get(OW_API_URL + "/data/2.5/air_pollution/forecast", params = {
        "appid": apikey,
        "lat": str(lat),
        "lon": str(lon),
    })

    # check response code
    if res.status_code != 200:
        return None

    body = res.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return None
    data = json.decode(body, None)
    items = data.get("list") if type(data) == "dict" else None
    if type(items) != "list":
        return None
    clean = []
    for item in items[:96]:
        main = item.get("main") if type(item) == "dict" else None
        components = item.get("components") if type(item) == "dict" else None
        dt = item.get("dt") if type(item) == "dict" else None
        aqi = main.get("aqi") if type(main) == "dict" else None
        if type(dt) not in ["int", "float"] or type(aqi) not in ["int", "float"] or aqi < 1 or aqi > 5 or type(components) != "dict" or any([type(components.get(code)) not in ["int", "float"] for code in POLLUTANT_CODES]):
            continue
        clean.append({"dt": dt, "main": {"aqi": aqi}, "components": components})
    return {"list": clean} if len(clean) >= 13 else None

def get_rounded_coord(coord):
    # rounds to 4 decimal places
    return math.ceil(float(coord) * 10000) / 10000

def get_color_for_aqi(aqi, config):
    # returns the color for the ring and text based on the quality index
    aqi1_color = config.str("aqi1_color", DEFAULT_COLOR_AQI1)
    aqi2_color = config.str("aqi2_color", DEFAULT_COLOR_AQI2)
    aqi3_color = config.str("aqi3_color", DEFAULT_COLOR_AQI3)
    aqi4_color = config.str("aqi4_color", DEFAULT_COLOR_AQI4)
    aqi5_color = config.str("aqi5_color", DEFAULT_COLOR_AQI5)
    aqi6_color = config.str("aqi6_color", DEFAULT_COLOR_AQI6)

    if aqi == 1:
        return aqi1_color
    elif aqi == 2:
        return aqi2_color
    elif aqi == 3:
        return aqi3_color
    elif aqi == 4:
        return aqi4_color
    elif aqi == 5:
        return aqi5_color
    else:
        return aqi6_color

def get_text_for_aqi(aqi, config):
    # returns the textual description of the quality index
    descs = [
        {"short": "G", "long": "Good"},
        {"short": "F", "long": "Fair"},
        {"short": "M", "long": "Moderate"},
        {"short": "P", "long": "Poor"},
        {"short": "V", "long": "Very Poor"},
        {"short": "U", "long": "Unknown"},
    ]

    # check if we are in widget mode
    widget_mode = config.bool("$widget", False)
    scroll = config.bool("scroll_desc", DEFAULT_SCROLL_AQI)
    safe_aqi = int(aqi - 1) if aqi <= 5 else 5

    # widgets don't support animation, we can only scroll text if not in widget mode
    if scroll and not widget_mode:
        return descs[safe_aqi]["long"]
    else:
        return descs[safe_aqi]["short"]

def get_formatted_hour(use24h, timestamp, timezone):
    # formats hours based on 12 or 24 format

    # default is 12h format
    format = "Kaa"

    if use24h:
        format = "HH"

    # create a time object from the timestamp
    time_object = time.from_timestamp(int(timestamp))

    # convert timezone
    time_in_timezone = time_object.in_location(timezone)

    # humanize it using the specified format
    hour = humanize.time_format(format, time_in_timezone)

    # if using 24h, append an "h" at the end
    if use24h:
        return hour + "h"
    else:
        return hour

def render_forecast(locality, aqi6_color, aqi6_hour, aqi12_color, aqi12_hour):
    return [
        render.Marquee(
            align = "left",
            width = 36,
            offset_start = 36,
            offset_end = 36,
            child = render.Text(locality, font = "Dina_r400-6"),
        ),
        render.Row(
            children = [
                render.Padding(
                    pad = (0, 1, 1, 0),
                    child = render.Box(
                        width = 16,
                        height = 9,
                        color = aqi6_color,
                        child = render.Box(
                            width = 14,
                            height = 7,
                            color = "#000",
                            child = render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Text(aqi6_hour, font = "tom-thumb", color = "#fff"),
                            ),
                        ),
                    ),
                ),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Box(
                        padding = 0,
                        width = 16,
                        height = 9,
                        color = aqi12_color,
                        child = render.Box(
                            width = 14,
                            height = 7,
                            color = "#000",
                            child = render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Text(aqi12_hour, font = "tom-thumb", color = "#fff"),
                            ),
                        ),
                    ),
                ),
            ],
        ),
    ]

def render_pollutant(pollutant_code, pollutant_level, config):
    pollutant_names = {
        "so2": "SO2",
        "no2": "NO2",
        "co": "CO",
        "pm2_5": "PM2.5",
        "pm10": "PM10",
        "o3": "O3",
    }

    return [
        render.Text(pollutant_names[pollutant_code], font = "Dina_r400-6"),
        render.Text(str(pollutant_level), font = "tom-thumb"),
        render_pollutant_level_bar(pollutant_code, pollutant_level, config),
    ]

def render_pollutant_level_bar(pollutant_code, pollutant_level, config):
    ranges = {
        "so2": [0, 20, 80, 250, 350],
        "no2": [0, 40, 70, 150, 200],
        "co": [0, 4400, 9400, 12400, 15400],
        "pm2_5": [0, 10, 25, 50, 75],
        "pm10": [0, 20, 50, 100, 200],
        "o3": [0, 60, 100, 140, 180],
    }

    range = ranges[pollutant_code]
    less = [x for x in range if x <= pollutant_level]

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 7, height = 2, color = get_color_for_aqi(1, config)),
                    render.Box(width = 7, height = 2, color = get_color_for_aqi(2, config)),
                    render.Box(width = 7, height = 2, color = get_color_for_aqi(3, config)),
                    render.Box(width = 7, height = 2, color = get_color_for_aqi(4, config)),
                    render.Box(width = 7, height = 2, color = get_color_for_aqi(5, config)),
                ],
            ),
            render.Row(
                children = [
                    render.Box(width = ((len(less) - 1) * 7) + 3, height = 1, color = "#000"),
                    render.Box(width = 1, height = 1, color = "#fff"),
                ],
            ),
            render.Row(
                children = [
                    render.Box(width = ((len(less) - 1) * 7) + 2, height = 1, color = "#000"),
                    render.Box(width = 3, height = 1, color = "#fff"),
                ],
            ),
        ],
    )
