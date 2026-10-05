# Modified in this community-maintained version; see Git history for contributors.
# Original author and license notices are retained below.

"""
Applet: NWS Daily Forecast
Summary: NWS three day forecast
Description: Three day weather forecast from the National Weather Service, styled like the AccuWeather app. Shows weather icon, day of week, low / high temperature, and wind direction.
Author: Glen Robertson
"""

load("assets.star", "WEATHER_ICONS", "WIND_ICONS")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NWS_POINTS_URL = "https://api.weather.gov/points/{lat},{lng}"

# NWS asks every client to identify itself; without a User-Agent the API may
# refuse the request.
NWS_HEADERS = {
    "User-Agent": "tronbyt-nws-daily-forecast (https://github.com/tronbyt/apps)",
    "Accept": "application/geo+json",
}

# Niblet: the /points lookup (grid -> forecast URL) is effectively static for a
# location, so it is remembered for 30 days instead of being requested on every
# render. A 404 from the forecast endpoint invalidates it.
POINTS_CACHE_SECONDS = 30 * 24 * 60 * 60

# Niblet: last good forecast periods, used when NWS has a transient error.
LAST_GOOD_CACHE_SECONDS = 6 * 60 * 60
LAST_GOOD_FIELDS = ["startTime", "isDaytime", "temperature", "windDirection", "shortForecast"]

DAY_LABELS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

def f_to_c(f):
    return int(math.round((f - 32) / 1.8))

def convert_temp(f, display_celsius):
    if display_celsius:
        return f_to_c(f)
    return int(math.round(f))

def pick_icon(short_forecast, is_daytime):
    fc = short_forecast.lower()
    if "thunder" in fc:
        return WEATHER_ICONS["thundery"]
    if "tornado" in fc:
        return WEATHER_ICONS["tornady"]
    if "hail" in fc:
        return WEATHER_ICONS["haily"]
    if "freezing rain" in fc or "sleet" in fc or "ice" in fc:
        return WEATHER_ICONS["sleety2"]
    if "snow" in fc or "blizzard" in fc or "flurries" in fc or "frost" in fc:
        return WEATHER_ICONS["snowy2"]
    if "rain" in fc or "shower" in fc or "drizzle" in fc:
        return WEATHER_ICONS["rainy"]
    if "fog" in fc or "haze" in fc or "smoke" in fc or "mist" in fc:
        return WEATHER_ICONS["foggy"]
    if "wind" in fc or "breezy" in fc:
        return WEATHER_ICONS["windy"]
    if "partly" in fc or "mostly" in fc:
        # partly cloudy / mostly sunny / mostly clear -> sunnyish; at night -> moonyish
        if is_daytime:
            return WEATHER_ICONS["sunnyish"]
        return WEATHER_ICONS["moonyish"]
    if "cloudy" in fc or "overcast" in fc:
        return WEATHER_ICONS["cloudy"]
    if "sunny" in fc or "clear" in fc or "fair" in fc or "hot" in fc:
        if is_daytime:
            return WEATHER_ICONS["sunny"]
        return WEATHER_ICONS["moony"]
    return None

def simplify_wind(wind_dir):
    if wind_dir == "NNE" or wind_dir == "ENE":
        return "NE"
    if wind_dir == "ESE" or wind_dir == "SSE":
        return "SE"
    if wind_dir == "SSW" or wind_dir == "WSW":
        return "SW"
    if wind_dir == "WNW" or wind_dir == "NNW":
        return "NW"
    return wind_dir

def render_forecast_column(fc):
    children = []

    icon = fc["icon"]
    if icon:
        children.append(render.Image(width = 13, height = 13, src = icon))
    else:
        children.append(render.Box(width = 13, height = 13))

    children.append(render.Text(fc["dow"], font = "CG-pixel-3x5-mono", color = "#ffffff"))
    children.append(render.Box(width = 1, height = 1))

    # low on the left (blue), high on the right (red)
    low_text = str(fc["temp_min"]) if fc["temp_min"] != None else "--"
    high_text = str(fc["temp_max"]) if fc["temp_max"] != None else "--"
    children.append(render.Row(
        children = [
            render.Text(low_text, font = "tom-thumb", color = "#0096FF"),
            render.Box(width = 1, height = 1),
            render.Text(high_text, font = "tom-thumb", color = "#FA8072"),
        ],
        main_align = "center",
    ))

    arrow_src = WIND_ICONS.get(fc["wind_dir"])
    if arrow_src:
        children.append(render.Image(width = 7, height = 7, src = arrow_src))
    else:
        children.append(render.Box(width = 7, height = 7))

    return render.Column(
        children = children,
        main_align = "center",
        cross_align = "center",
    )

def round_coordinate(value):
    # Niblet: NWS grid cells are ~2.5 km, so three decimals (~110 m) select
    # the same forecast while letting nearby installs send byte-identical
    # requests that the shared response cache can serve. Adding 0.0 turns
    # -0.0 into 0.0.
    return str(math.round(float(value) * 1000) / 1000 + 0.0)

def forecast_url_for(points_key, lat, lng):
    cached = cache.get(points_key)
    if cached:
        return cached

    # The points endpoint returns the gridpoint URL for a given lat/lng.
    points_resp = http.get(
        NWS_POINTS_URL.format(lat = lat, lng = lng),
        headers = NWS_HEADERS,
        ttl_seconds = 86400,
    )
    if points_resp.status_code != 200:
        print("NWS points request failed with status %d" % points_resp.status_code)
        return None

    forecast_url = points_resp.json()["properties"]["forecast"]
    cache.set(points_key, forecast_url, ttl_seconds = POINTS_CACHE_SECONDS)
    return forecast_url

def fetch_periods(lat, lng):
    points_key = "points:%s,%s" % (lat, lng)
    last_good_key = "periods:%s,%s" % (lat, lng)

    forecast_url = forecast_url_for(points_key, lat, lng)
    forecast_resp = None
    if forecast_url != None:
        # Forecast updates roughly hourly; cache that long.
        forecast_resp = http.get(forecast_url, headers = NWS_HEADERS, ttl_seconds = 3600)
        if forecast_resp.status_code == 404:
            # The grid moved; resolve it again on the next render.
            cache.set(points_key, "", ttl_seconds = 1)

    if forecast_resp == None or forecast_resp.status_code != 200:
        # Niblet: a transient NWS error (5xx, 429) shows the last good forecast
        # instead of failing the render.
        if forecast_resp != None:
            print("NWS forecast request failed with status %d" % forecast_resp.status_code)
        cached = cache.get(last_good_key)
        return json.decode(cached) if cached else None

    periods = forecast_resp.json()["properties"]["periods"]
    cache.set(last_good_key, json.encode([
        {k: p.get(k) for k in LAST_GOOD_FIELDS}
        for p in periods
    ]), ttl_seconds = LAST_GOOD_CACHE_SECONDS)
    return periods

def fetch_forecasts(location, display_celsius):
    periods = fetch_periods(round_coordinate(location["lat"]), round_coordinate(location["lng"]))
    if periods == None:
        return None

    timezone = location.get("timezone", "America/Los_Angeles")

    # Group periods by local calendar date. NWS day periods run ~6am-6pm and
    # night periods ~6pm-6am, so the night period shares its day's start date.
    buckets = []
    bucket_by_date = {}
    for period in periods:
        start = time.parse_time(period["startTime"]).in_location(timezone)
        date_key = start.format("2006-01-02")

        if date_key not in bucket_by_date:
            bucket = {"date": date_key, "day": None, "night": None}
            bucket_by_date[date_key] = bucket
            buckets.append(bucket)

        if period["isDaytime"]:
            bucket_by_date[date_key]["day"] = period
        else:
            bucket_by_date[date_key]["night"] = period

    forecasts = []
    for bucket in buckets:
        if len(forecasts) >= 3:
            break
        day = bucket["day"]
        night = bucket["night"]

        # Skip days where the daytime period is already past — only the night
        # remains, so we'd have a low without a meaningful high.
        if day == None:
            continue

        ref_start = time.parse_time(day["startTime"]).in_location(timezone)
        dow = DAY_LABELS[humanize.day_of_week(ref_start)]

        temp_max = convert_temp(day["temperature"], display_celsius)
        temp_min = convert_temp(night["temperature"], display_celsius) if night != None else None

        wind_dir = simplify_wind(day.get("windDirection", ""))
        icon = pick_icon(day["shortForecast"], True)

        forecasts.append({
            "dow": dow,
            "temp_min": temp_min,
            "temp_max": temp_max,
            "icon": icon,
            "wind_dir": wind_dir,
        })

    return forecasts

def sample_forecasts(display_celsius):
    return [
        {"dow": "MON", "temp_min": convert_temp(65, display_celsius), "temp_max": convert_temp(75, display_celsius), "icon": WEATHER_ICONS["sunny"], "wind_dir": "N"},
        {"dow": "TUE", "temp_min": convert_temp(66, display_celsius), "temp_max": convert_temp(74, display_celsius), "icon": WEATHER_ICONS["rainy"], "wind_dir": "NE"},
        {"dow": "WED", "temp_min": convert_temp(68, display_celsius), "temp_max": convert_temp(78, display_celsius), "icon": WEATHER_ICONS["sunnyish"], "wind_dir": "E"},
    ]

def main(config):
    temp_units = config.get("tempUnits", "F")
    display_celsius = (temp_units == "C")
    location_raw = config.get("location")

    if location_raw:
        location = json.decode(location_raw)
        forecasts = fetch_forecasts(location, display_celsius)
        if forecasts == None:
            # Niblet: NWS is unavailable and no recent forecast is cached; skip
            # this render so the display keeps its previous image.
            return []
        is_sample = False
    else:
        forecasts = sample_forecasts(display_celsius)
        is_sample = True

    # Pad with empty columns if NWS returned fewer than 3 days.
    for _ in range(3 - len(forecasts)):
        forecasts.append({"dow": "", "temp_min": None, "temp_max": None, "icon": None, "wind_dir": ""})

    columns = [render_forecast_column(fc) for fc in forecasts[:3]]
    divider1 = render.Column(children = [render.Box(width = 1, height = 32, color = "#5A5A5A")])
    divider2 = render.Column(children = [render.Box(width = 1, height = 32, color = "#5A5A5A")])

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [columns[0], divider1, columns[1], divider2, columns[2]],
                    main_align = "space_evenly",
                    expanded = True,
                ),
                render.Row(
                    children = [render.Text("SAMPLE" if is_sample else "", font = "6x13", color = "#FF0000", height = 22)],
                    main_align = "center",
                    expanded = True,
                ),
            ],
        ),
    )

def get_schema():
    temp_units_options = [
        schema.Option(display = "Fahrenheit", value = "F"),
        schema.Option(display = "Celsius", value = "C"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather data.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "tempUnits",
                name = "Temperature units",
                desc = "The units for temperature display",
                icon = "gear",
                default = temp_units_options[0].value,
                options = temp_units_options,
            ),
        ],
    )
