"""
Applet: OG Clock Remake with Weather
Summary: OG Clock Remake with Location Configuration and Weather Display
Description: Display time plus current temperature and humidity from OpenWeather, National Weather Service, or an Ambient Weather station. Ambient Weather requires an Application Key and API Key from AmbientWeather.net.
Author: g3rmanaviator
Version: 1.1

"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/cloudy.png", CLOUDY_ASSET = "file")
load("images/foggy.png", FOGGY_ASSET = "file")
load("images/haily.png", HAILY_ASSET = "file")
load("images/moony.png", MOONY_ASSET = "file")
load("images/moonyish.png", MOONYISH_ASSET = "file")
load("images/raindrop_icon.png", RAINDROP_ICON_ASSET = "file")
load("images/rainy.png", RAINY_ASSET = "file")
load("images/sleety.png", SLEETY_ASSET = "file")
load("images/sleety2.png", SLEETY2_ASSET = "file")
load("images/snowy.png", SNOWY_ASSET = "file")
load("images/snowy2.png", SNOWY2_ASSET = "file")
load("images/sunny.png", SUNNY_ASSET = "file")
load("images/sunnyish.png", SUNNYISH_ASSET = "file")
load("images/thundery.png", THUNDERY_ASSET = "file")
load("images/tornady.png", TORNADY_ASSET = "file")
load("images/windy.png", WINDY_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

# Weather API URLs from Time & Weather
NWS_POINTS_URL = "https://api.weather.gov/points/{latitude},{longitude}"
NWS_STATIONS_URL = "https://api.weather.gov/gridpoints/{grid_id}/{grid_x},{grid_y}/stations"
NWS_LATEST_OBSERVATION_URL = "{station_url}/observations/latest"
OPENWEATHER_CURRWEATHER_URL = "https://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units={units}&lang=en"
OPENWEATHER_ONECALL_URL = "https://api.openweathermap.org/data/3.0/onecall?lat={latitude}&lon={longitude}&exclude=minutely,hourly,daily,alerts&appid={api_key}&units={units}&lang=en"
AMBIENT_WEATHER_DEVICES_URL = "https://rt.ambientweather.net/v1/devices"
MAX_RESPONSE_BYTES = 512 * 1024
NWS_HEADERS = {"User-Agent": "Niblet/1.0 (heyniblet.com)"}

TEMP_COLOR_DEFAULT = "#FFFFFF"
TIME_NIGHT_COLOR = "#333333"

# Complete weather icons from Time & Weather
WEATHER_ICONS = {
    "cloudy.png": CLOUDY_ASSET.readall(),
    "foggy.png": FOGGY_ASSET.readall(),
    "haily.png": HAILY_ASSET.readall(),
    "moony.png": MOONY_ASSET.readall(),
    "moonyish.png": MOONYISH_ASSET.readall(),
    "rainy.png": RAINY_ASSET.readall(),
    "sleety.png": SLEETY_ASSET.readall(),
    "sleety2.png": SLEETY2_ASSET.readall(),
    "snowy.png": SNOWY_ASSET.readall(),
    "snowy2.png": SNOWY2_ASSET.readall(),
    "sunny.png": SUNNY_ASSET.readall(),
    "sunnyish.png": SUNNYISH_ASSET.readall(),
    "thundery.png": THUNDERY_ASSET.readall(),
    "tornady.png": TORNADY_ASSET.readall(),
    "windy.png": WINDY_ASSET.readall(),
}

RAINDROP_ICON = RAINDROP_ICON_ASSET.readall()

# Weather API functions from Time & Weather
def get_nws_observation_station(lat, lon, ttl = 3600):
    # Get the grid point data
    res = http.get(NWS_POINTS_URL.format(
        latitude = humanize.ftoa(lat, 4),
        longitude = humanize.ftoa(lon, 4),
    ), headers = NWS_HEADERS, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Could not obtain the grid point data.", res.status_code)

    data = response_json(res)
    properties = data.get("properties", {}) if type(data) == "dict" else {}
    if (
        type(properties) != "dict" or
        type(properties.get("gridId")) != "string" or
        type(properties.get("gridX")) not in ["int", "float"] or
        type(properties.get("gridY")) not in ["int", "float"]
    ):
        fail("Invalid NWS grid point response.")
    grid_id = properties["gridId"]
    grid_x = properties["gridX"]
    grid_y = properties["gridY"]

    # Get the stations list from the gridpoint
    stations_url = NWS_STATIONS_URL.format(
        grid_id = grid_id,
        grid_x = grid_x,
        grid_y = grid_y,
    )
    stations_res = http.get(stations_url, headers = NWS_HEADERS, ttl_seconds = ttl)
    if stations_res.status_code != 200:
        fail("Could not obtain stations list.", stations_res.status_code)

    # Get the first station from the observationStations list
    stations_data = response_json(stations_res)
    observation_stations = stations_data.get("observationStations", []) if type(stations_data) == "dict" else []
    if type(observation_stations) != "list" or len(observation_stations) == 0:
        fail("No observation stations found for this location.")

    first_station = observation_stations[0]
    if type(first_station) != "string" or not first_station.startswith("https://api.weather.gov/stations/"):
        fail("Invalid NWS observation station.")
    return first_station

def get_nws_latest_observation(station_url, ttl = 300):
    # Call the station's latest observation endpoint
    latest_url = NWS_LATEST_OBSERVATION_URL.format(station_url = station_url)
    res = http.get(latest_url, headers = NWS_HEADERS, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Could not obtain latest observation.", res.status_code)
    return response_json(res)

def get_current_weather_conditions(url, ttl):
    res = http.get(url, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Current conditions request failed with status", res.status_code)
    return response_json(res)

def get_ambient_weather_conditions(application_key, api_key, station_id, display_metric, now):
    # The devices endpoint returns every station available to the supplied API key,
    # with the most recent observation in each device's lastData object.
    res = http.get(
        url = AMBIENT_WEATHER_DEVICES_URL,
        params = {
            "applicationKey": application_key,
            "apiKey": api_key,
        },
        ttl_seconds = 60,
    )
    if res.status_code != 200:
        fail("Ambient Weather device request failed with status", res.status_code)

    stations = response_json(res)
    if type(stations) != "list" or len(stations) == 0:
        fail("No Ambient Weather devices are available for this API key.")

    station = stations[0]
    if station_id:
        station = None
        for candidate in stations:
            if candidate.get("macAddress") == station_id:
                station = candidate
                break
        if station == None:
            fail("Ambient Weather device was not found. Check the station MAC address.")

    if type(station) != "dict":
        fail("Ambient Weather returned an invalid device.")

    conditions = station.get("lastData", {})
    temp_f = conditions.get("tempf")
    if temp_f == None:
        fail("The selected Ambient Weather device has no outdoor temperature reading.")

    temperature = int(temp_f)
    if display_metric:
        temperature = int((temp_f - 32) * 5.0 / 9.0)

    # Ambient Weather supplies measurements rather than a weather-condition code.
    # Use recent rain and wind when available; otherwise select a time-appropriate
    # neutral sky icon.
    if conditions.get("hourlyrainin", 0) > 0:
        icon_ref = "rainy.png"
    elif conditions.get("windspeedmph", 0) >= 20:
        icon_ref = "windy.png"
    elif now.hour >= 6 and now.hour < 19:
        icon_ref = "sunnyish.png"
    else:
        icon_ref = "moonyish.png"

    humidity = conditions.get("humidity")
    if humidity != None:
        humidity = int(humidity)
    else:
        humidity = "?"

    return {
        "temp": temperature,
        "humidity": humidity,
        "icon_ref": icon_ref,
    }

def response_json(response):
    body = response.body()
    if not body or len(body) > MAX_RESPONSE_BYTES:
        fail("Weather service returned an invalid response.")
    return response.json()

def openweather_conditions(data, one_call):
    if type(data) != "dict":
        fail("Weather service returned invalid conditions.")
    values = data.get("current", {}) if one_call else data.get("main", {})
    weather = values.get("weather", []) if one_call and type(values) == "dict" else data.get("weather", [])
    if type(values) != "dict" or type(weather) != "list" or not weather or type(weather[0]) != "dict":
        fail("Weather service returned incomplete conditions.")
    temp = values.get("temp")
    humidity = values.get("humidity")
    icon_num = weather[0].get("id")
    icon_code = weather[0].get("icon")
    if type(temp) not in ["int", "float"] or type(humidity) not in ["int", "float"]:
        fail("Weather service returned invalid measurements.")
    if type(icon_num) != "int" or type(icon_code) != "string":
        fail("Weather service returned an invalid condition.")
    return {
        "temp": int(temp),
        "humidity": int(humidity),
        "icon_ref": openweather_icon(icon_num, icon_code),
    }

def openweather_icon(icon_num, icon_code):
    is_day = "d" in icon_code
    if icon_num == 800:
        return "sunny.png" if is_day else "moony.png"
    if icon_num >= 801 and icon_num <= 804:
        return "sunnyish.png" if is_day and icon_num <= 802 else ("moonyish.png" if not is_day else "cloudy.png")
    if (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 701:
        return "rainy.png"
    if icon_num >= 200 and icon_num < 300:
        return "thundery.png"
    if icon_num >= 600 and icon_num < 700:
        return "snowy2.png"
    if icon_num == 731:
        return "windy.png"
    if icon_num >= 701 and icon_num < 800:
        return "foggy.png"
    return "cloudy.png"

def clock_minutes(value, default):
    if type(value) != "string" or not re.match(r"^[0-2][0-9][0-5][0-9]$", value):
        return default
    hour = int(value[:2])
    return default if hour > 23 else hour * 60 + int(value[2:])

def nightScreen(now, config):
    # Use OG Clock’s settings
    use_24_hour = config.bool("24hour_format", False)
    time_color = TIME_NIGHT_COLOR  # dim color at night

    # Blinking colon: reuse your exact OG logic
    if config.bool("blink", True):
        blink_vec = [render.Text(":", font = "6x13", color = time_color)] * 5
        blink_vec.extend([render.Text(":", font = "6x13", color = "#000")] * 5)
        blink_text = render.Animation(blink_vec)
    else:
        blink_text = render.Text(":", font = "6x13", color = time_color)

    # Hours / minutes: reuse your existing formatting
    if use_24_hour:
        hour_text = now.format("15")
        minute_text = now.format("04")
    else:
        if now.hour == 0:
            hour_text = "12"
        elif now.hour > 12:
            hour_text = str(now.hour - 12)
        else:
            hour_text = str(now.hour)
        minute_text = now.format("04 PM")

    return render.Root(
        delay = 500,
        max_age = 120,
        child = render.Padding(
            pad = (0, 8, 0, 0),
            child = render.Column(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(width = 64, height = 1),
                    render.Row(
                        children = [
                            render.Text(content = hour_text, font = "6x13", color = time_color),
                            blink_text,
                            render.Text(content = minute_text, font = "6x13", color = time_color),
                        ],
                    ),
                ],
            ),
        ),
    )

def main(config):
    # Get location info from config or use default
    location_info = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location_info["timezone"]
    latitude = float(location_info["lat"])
    longitude = float(location_info["lng"])

    # Add this right after getting the current time
    now = time.now().in_location(timezone)

    # Night mode check
    start_total = clock_minutes(config.get("nightModeStart"), 23 * 60)
    end_total = clock_minutes(config.get("nightModeEnd"), 7 * 60)

    night_mode_enabled = config.bool("night_mode", False)
    if night_mode_enabled:
        current_hour = now.hour
        current_minute = now.minute
        current_total = current_hour * 60 + current_minute

        # Check if night mode crosses midnight
        if start_total > end_total:
            # Crosses midnight (e.g., 23:00 to 07:00)
            in_night_mode = current_total >= start_total or current_total < end_total
        else:
            # Same day (e.g., 01:00 to 05:00)
            in_night_mode = current_total >= start_total and current_total < end_total

        if in_night_mode:
            return nightScreen(now, config)

    # Get display settings from OG Clock
    use_24_hour = config.bool("24hour_format", False)
    time_color = config.get("time_color", "fff")

    # Get blinking separator setting (matching custom clock implementation)
    if config.bool("blink", True):
        blink_vec = [render.Text(":", font = "6x13", color = time_color)] * 5
        blink_vec.extend([render.Text(":", font = "6x13", color = "#000")] * 5)
        blink_text = render.Animation(blink_vec)
    else:
        blink_text = render.Text(":", font = "6x13", color = time_color)

    # Weather settings
    api_service = config.get("weatherApiService") or "OpenWeather"
    if api_service not in ["National Weather Service (NWS)", "OpenWeather", "OpenWeatherOneCall", "Ambient Weather"]:
        api_service = "OpenWeather"
    api_key = config.get("apiKey", "")
    ambient_application_key = config.get("ambientApplicationKey", "")
    ambient_api_key = config.get("ambientApiKey", "")
    ambient_station_id = config.get("ambientStationId", "")
    system_of_measurement = config.get("systemOfMeasurement", "Imperial").lower()
    temp_color = config.get("tempColor", TEMP_COLOR_DEFAULT)

    display_metric = (system_of_measurement == "metric")
    display_sample = (
        (api_service == "OpenWeather" or api_service == "OpenWeatherOneCall") and not api_key
    ) or (
        api_service == "Ambient Weather" and (not ambient_application_key or not ambient_api_key)
    )

    # Format time components for proper blinking colon display
    if use_24_hour:
        hour_text = now.format("15")
        minute_text = now.format("04")
    else:
        if now.hour == 0:
            hour_text = "12"
        elif now.hour > 12:
            hour_text = str(now.hour - 12)
        else:
            hour_text = str(now.hour)
        minute_text = now.format("04 PM")

    # Initialize weather variables
    icon_ref = None
    result_current_conditions = {}

    if display_sample:
        # Sample data to display if user-specified API / location key are not available
        icon_ref = "sunnyish.png"
        result_current_conditions["temp"] = 14 if display_metric else 57
        result_current_conditions["humidity"] = 50
    elif api_service == "National Weather Service (NWS)":
        station_url = get_nws_observation_station(latitude, longitude, 3600)
        observation_data = get_nws_latest_observation(station_url, 300)

        properties = observation_data.get("properties", {})

        # Get temperature - NWS observations use Celsius by default
        temp_data = properties.get("temperature", {})
        temp_celsius = temp_data.get("value") if temp_data else None
        if temp_celsius != None:
            if display_metric:
                result_current_conditions["temp"] = int(temp_celsius)
            else:
                result_current_conditions["temp"] = int((temp_celsius * 9.0 / 5.0) + 32)
        else:
            result_current_conditions["temp"] = "?"

        # Get humidity
        humidity_data = properties.get("relativeHumidity", {})
        humidity_value = humidity_data.get("value") if humidity_data else None
        if humidity_value != None:
            result_current_conditions["humidity"] = int(humidity_value)
        else:
            result_current_conditions["humidity"] = "?"

        # Determine icon based on text description and time of day
        text_description = properties.get("textDescription", "")
        if text_description:
            text_description = text_description.lower()

        # Check if it's daytime (simple check - can be improved)
        current_hour = now.hour
        is_daytime = current_hour >= 6 and current_hour < 19

        # Icon mapping based on text description
        if text_description:
            if ("clear" in text_description or "fair" in text_description) and is_daytime:
                icon_ref = "sunny.png"
            elif ("mostly clear" in text_description or "partly cloudy" in text_description or "few clouds" in text_description) and is_daytime:
                icon_ref = "sunnyish.png"
            elif "cloudy" in text_description or "overcast" in text_description:
                icon_ref = "cloudy.png"
            elif "rain" in text_description or "drizzle" in text_description:
                icon_ref = "rainy.png"
            elif "thunder" in text_description or "storm" in text_description:
                icon_ref = "thundery.png"
            elif "snow" in text_description:
                icon_ref = "snowy2.png"
            elif "fog" in text_description or "mist" in text_description:
                icon_ref = "foggy.png"
            elif ("clear" in text_description or "fair" in text_description) and not is_daytime:
                icon_ref = "moony.png"
            elif ("mostly clear" in text_description or "partly cloudy" in text_description) and not is_daytime:
                icon_ref = "moonyish.png"
            else:
                icon_ref = "cloudy.png"  # default
        else:
            icon_ref = "cloudy.png"  # default if no description

    elif api_service == "OpenWeather":
        request_url = OPENWEATHER_CURRWEATHER_URL.format(
            latitude = latitude,
            longitude = longitude,
            api_key = api_key,
            units = system_of_measurement,
        )
        raw_current_conditions = get_current_weather_conditions(request_url, 300)
        result_current_conditions = openweather_conditions(raw_current_conditions, False)
        icon_ref = result_current_conditions["icon_ref"]

    elif api_service == "OpenWeatherOneCall":
        request_url = OPENWEATHER_ONECALL_URL.format(
            latitude = latitude,
            longitude = longitude,
            api_key = api_key,
            units = system_of_measurement,
        )
        raw_current_conditions = get_current_weather_conditions(request_url, 300)
        result_current_conditions = openweather_conditions(raw_current_conditions, True)
        icon_ref = result_current_conditions["icon_ref"]

    elif api_service == "Ambient Weather":
        ambient_conditions = get_ambient_weather_conditions(
            application_key = ambient_application_key,
            api_key = ambient_api_key,
            station_id = ambient_station_id,
            display_metric = display_metric,
            now = now,
        )
        result_current_conditions["temp"] = ambient_conditions["temp"]
        result_current_conditions["humidity"] = ambient_conditions["humidity"]
        icon_ref = ambient_conditions["icon_ref"]

    # Prepare weather display components
    if icon_ref:
        weather_image = render.Image(width = 16, height = 16, src = WEATHER_ICONS[icon_ref])
    else:
        weather_image = render.Box(width = 16, height = 16)

    # Temperature and humidity display
    show_unit = config.bool("show_temp_unit", True)
    temp_unit = ("C" if display_metric else "F") if show_unit else ""
    temp_text = render.Text(
        content = str(result_current_conditions.get("temp", "?")) + "°" + temp_unit,
        font = "5x8",
        color = temp_color,
    )

    humidity_text = render.Text(
        content = str(result_current_conditions.get("humidity", "?")) + "%",
        font = "5x8",
        color = "#848fEE",
    )

    # Layout - keeping OG Clock structure but adding weather
    return render.Root(
        delay = 500,
        max_age = 60,
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # Render Time - using the exact custom clock blinking implementation
                    render.Row(
                        children = [
                            render.Text(
                                content = hour_text,
                                font = "6x13",
                                color = time_color,
                            ),
                            # Blinking colon separator (exactly like custom clock)
                            blink_text,
                            render.Text(
                                content = minute_text,
                                font = "6x13",
                                color = time_color,
                            ),
                        ],
                    ),
                    # Weather section
                    render.Row(
                        cross_align = "center",
                        children = [
                            # Render Weather Icon
                            weather_image,
                            # Add spacing
                            render.Box(width = 4, height = 1),
                            render.Column(
                                children = [
                                    # Render Temperature
                                    temp_text,
                                    # Render Humidity
                                    humidity_text,
                                ],
                            ),
                        ],
                    ),
                    # Sample indicator
                    render.Text(
                        content = "SAMPLE" if display_sample else "",
                        font = "tom-thumb",
                        color = "#FF0000",
                    ) if display_sample else render.Box(width = 1, height = 1),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time and weather.",
                icon = "locationArrow",
            ),
            schema.Toggle(
                id = "24hour_format",
                name = "24 hour clock",
                desc = "Enable for 24-hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Color(
                id = "time_color",
                name = "Time color",
                desc = "Change the color of the time.",
                icon = "brush",
                default = "fff",
            ),
            schema.Dropdown(
                id = "weatherApiService",
                name = "Weather API Service",
                desc = "Select your preferred Weather API",
                icon = "database",
                default = "OpenWeather",
                options = [
                    schema.Option(
                        display = "National Weather Service (NWS)",
                        value = "National Weather Service (NWS)",
                    ),
                    schema.Option(
                        display = "OpenWeather",
                        value = "OpenWeather",
                    ),
                    schema.Option(
                        display = "OpenWeather (One Call API 3.0)",
                        value = "OpenWeatherOneCall",
                    ),
                    schema.Option(
                        display = "Ambient Weather",
                        value = "Ambient Weather",
                    ),
                ],
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "API key for weather data access (not needed for NWS)",
                icon = "gear",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "ambientApplicationKey",
                name = "Ambient Weather Application Key",
                desc = "Application key from your AmbientWeather.net account. Required when Ambient Weather is selected.",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "ambientApiKey",
                name = "Ambient Weather API Key",
                desc = "API key from your AmbientWeather.net account. Required when Ambient Weather is selected.",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "ambientStationId",
                name = "Ambient Weather Station MAC Address",
                desc = "Optional. Select a station by MAC address; leave blank to use the first available device.",
                icon = "temperatureHalf",
                default = "",
            ),
            schema.Dropdown(
                id = "systemOfMeasurement",
                name = "System of measurement",
                desc = "Choose which system to display measurements",
                icon = "ruler",
                default = "Imperial",
                options = [
                    schema.Option(
                        display = "Imperial",
                        value = "Imperial",
                    ),
                    schema.Option(
                        display = "Metric",
                        value = "Metric",
                    ),
                ],
            ),
            schema.Color(
                id = "tempColor",
                name = "Temperature color",
                desc = "Color for temperature display",
                icon = "brush",
                default = TEMP_COLOR_DEFAULT,
            ),
            schema.Toggle(
                id = "show_temp_unit",
                name = "Show temperature unit",
                desc = "Display C or F after temperature",
                icon = "thermometer",
                default = True,
            ),
            schema.Toggle(
                id = "blink",
                name = "Blinking separator",
                desc = "Blink the colon between hours and minutes.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                desc = "Enable night mode - Dim the display and show only the clock",
                icon = "gear",
                default = False,
            ),
            schema.Text(
                id = "nightModeStart",
                name = "Night Mode Start",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 2300",
                default = "2300",
            ),
            schema.Text(
                id = "nightModeEnd",
                name = "Night Mode End",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 0730",
                default = "0700",
            ),
        ],
    )
