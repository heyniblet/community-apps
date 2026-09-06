"""
Applet: CycleCast
Summary: Weather Data for Cyclists
Description: Displays weather data important for cyclists.
Author: Robert Ison
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/cloud_icon.png", CLOUD_ICON_ASSET = "file")
load("images/directional_arrow.png", DIRECTIONAL_ARROW_ASSET = "file")
load("images/flag_base.png", FLAG_BASE_ASSET = "file")
load("images/moon_0.png", MOON_0_ASSET = "file")
load("images/moon_1.png", MOON_1_ASSET = "file")
load("images/moon_2.png", MOON_2_ASSET = "file")
load("images/moon_3.png", MOON_3_ASSET = "file")
load("images/moon_4.png", MOON_4_ASSET = "file")
load("images/moon_5.png", MOON_5_ASSET = "file")
load("images/moon_6.png", MOON_6_ASSET = "file")
load("images/moon_7.png", MOON_7_ASSET = "file")
load("images/rain_icon.png", RAIN_ICON_ASSET = "file")
load("images/sun_icon.png", SUN_ICON_ASSET = "file")
load("images/windrose_icon.png", WINDROSE_ICON_ASSET = "file")
load("images/windsock_1.png", WINDSOCK_1_ASSET = "file")
load("images/windsock_2.png", WINDSOCK_2_ASSET = "file")
load("images/windsock_3.png", WINDSOCK_3_ASSET = "file")
load("images/windsock_4.png", WINDSOCK_4_ASSET = "file")
load("images/windsock_5.png", WINDSOCK_5_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

CLOUD_ICON = CLOUD_ICON_ASSET.readall()
DIRECTIONAL_ARROW = DIRECTIONAL_ARROW_ASSET.readall()
FLAG_BASE = FLAG_BASE_ASSET.readall()
RAIN_ICON = RAIN_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()
WINDROSE_ICON = WINDROSE_ICON_ASSET.readall()

DEFAULT_LOCATION = """{"lat": "28.53933",	"lng": "-81.38325",	"description": "Orlando, FL, USA",	"locality": "Orlando",	"place_id": "???",	"timezone": "America/New_York"}"""
API_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=wind_direction_10m,temperature_2m,wind_speed_10m,rain,wind_gusts_10m,uv_index,showers,apparent_temperature,precipitation_probability,relative_humidity_2m,cloud_cover,is_day&timezone=auto&wind_speed_unit=mph&temperature_unit=fahrenheit"
WEATHER_BOUNDS = {
    "temperature_2m": [-200, 200],
    "apparent_temperature": [-200, 200],
    "wind_speed_10m": [0, 500],
    "wind_gusts_10m": [0, 500],
    "wind_direction_10m": [0, 360],
    "rain": [0, 1000],
    "showers": [0, 1000],
    "uv_index": [0, 100],
    "precipitation_probability": [0, 100],
    "relative_humidity_2m": [0, 100],
    "cloud_cover": [0, 100],
    "is_day": [0, 1],
}
CONDITION_UNITS = {
    "temperature_2m": "°F",
    "apparent_temperature": "°F",
    "wind_speed_10m": "mp/h",
    "wind_gusts_10m": "mp/h",
    "rain": "mm",
    "showers": "mm",
    "precipitation_probability": "%",
    "relative_humidity_2m": "%",
    "cloud_cover": "%",
}

#Weather Icons

WINDSOCKS = {
    "1": WINDSOCK_1_ASSET.readall(),
    "2": WINDSOCK_2_ASSET.readall(),
    "3": WINDSOCK_3_ASSET.readall(),
    "4": WINDSOCK_4_ASSET.readall(),
    "5": WINDSOCK_5_ASSET.readall(),
}

MOON_ICONS = {
    "0": MOON_0_ASSET.readall(),
    "1": MOON_1_ASSET.readall(),
    "2": MOON_2_ASSET.readall(),
    "3": MOON_3_ASSET.readall(),
    "4": MOON_4_ASSET.readall(),
    "5": MOON_5_ASSET.readall(),
    "6": MOON_6_ASSET.readall(),
    "7": MOON_7_ASSET.readall(),
}

# Parameters for Setting Options
scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def get_weather_data(latitude, longitude):
    local_api_url = API_URL % (latitude, longitude)
    response = http.get(local_api_url, ttl_seconds = 900)
    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return None
    data = json.decode(response.body(), None)
    current = data.get("current") if type(data) == "dict" else None
    current_time = current.get("time") if type(current) == "dict" else None
    if type(current_time) != "string" or len(current_time) != 16:
        return None
    for name, bounds in WEATHER_BOUNDS.items():
        value = current.get(name)
        if type(value) not in ["int", "float"] or value < bounds[0] or value > bounds[1]:
            return None
    return data

def get_current_condition(data, item_name, add_units = True):
    value = data["current"][item_name]
    if add_units:
        units = CONDITION_UNITS.get(item_name, "")
        display_tempate = "%s%s" if units == "mm" or units == "%" or units == "°F" else "%s %s"
        return display_tempate % (value, units)
    return value

def to_hex(n):
    """Converts an integer (0-255) to a two-character hex string."""
    hex_chars = "0123456789ABCDEF"
    return hex_chars[n // 16] + hex_chars[n % 16]

def most_contrasting_color(hex_color):
    """Returns the most contrasting color by inverting the input color."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Invert colors
    inverted_r = 255 - r
    inverted_g = 255 - g
    inverted_b = 255 - b

    # Convert back to hex
    return "#" + to_hex(inverted_r) + to_hex(inverted_g) + to_hex(inverted_b)

def luminance(r, g, b):
    """Calculates the relative luminance of an RGB color."""
    return (0.299 * r + 0.587 * g + 0.114 * b)

def best_contrast_color(hex_color):
    """Returns black (#000000) or white (#FFFFFF) based on the best contrast."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Determine luminance and choose contrast color
    if luminance(r, g, b) > 128:
        return "#000000"  # Dark text for light backgrounds
    else:
        return "#FFFFFF"  # Light text for dark backgrounds

def get_uv_index_category(index, color = False):
    index = float(index)

    # Define thresholds and corresponding values
    thresholds = [2, 5, 7, 10]
    colors = ["#8FC93A", "#FFD700", "#FF8C00", "#FF4500", "#800080"]
    labels = ["Low", "Moderate", "High", "Very High", "Extreme"]

    # Select appropriate category
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i] if color else labels[i]

    return colors[-1] if color else labels[-1]  # Highest category if above all thresholds

def get_temperature_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [32, 50, 65, 75, 85, 95]
    colors = ["#00A8E8", "#66D3FA", "#5BC8AC", "#8FC93A", "#FFD700", "#FF8C00", "#D62828"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all thresholds

def get_humidity_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [20, 40, 60, 75, 85, 95]
    colors = ["#FF4500", "#FF8C00", "#FFD700", "#8FC93A", "#5BC8AC", "#66D3FA", "#00A8E8"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all threshold

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_information_marquee(message):
    marquee = render.Marquee(
        width = 64,
        child = render.Text(message, color = "#ffff00", font = "CG-pixel-3x5-mono"),
    )

    return marquee

def moon_phase(year, month, day, show_description = True):
    # Constants for improved accuracy
    known_new_moon_julian = 2451550.1  # Julian date for January 6, 2000
    synodic_month = 29.53058867  # Average length of a lunar month in days

    # Convert the current date to Julian date
    julian_date = calculate_julian_date(year, month, day)

    # Calculate days since the known new moon
    days_since_new_moon = julian_date - known_new_moon_julian

    # Determine the phase of the moon as a fraction of the synodic month
    phase = days_since_new_moon % synodic_month
    phase = float(phase)

    # Define thresholds with corresponding descriptions and indexes
    phase_map = [
        (1.84566, "New Moon", 0),
        (5.53699, "Waxing Crescent", 1),
        (9.22831, "First Quarter", 2),
        (12.91963, "Waxing Gibbous", 3),
        (16.61096, "Full Moon", 4),
        (20.30228, "Waning Gibbous", 5),
        (23.99361, "Last Quarter", 6),
        (27.68493, "Waning Crescent", 7),
    ]

    # Iterate through the mapped phases
    for threshold, description, index in phase_map:
        if phase < threshold:
            return description if show_description else index

    return "New Moon" if show_description else 0  # Default to "New Moon" or index 0

def calculate_julian_date(year, month, day):
    # Convert Gregorian date to Julian date
    if month <= 2:
        year -= 1
        month += 12

    A = year // 100
    B = 2 - A + (A // 4)
    julian_date = (int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + B - 1524.5)
    return julian_date

def get_wind_sock_category(wind_speed):
    thresholds = [6.91, 10.36, 13.81, 17.26]

    # Iterate through thresholds and return appropriate category
    for i in range(len(thresholds)):
        if wind_speed <= thresholds[i]:
            return i + 1

    return len(thresholds) + 1  # Highest category if above all thresholds

def get_wind_rose_display(direction):
    #Start and Stop at the correct spot on the windrose
    #Simulate a little variability in the breeze in the windrose by having it move about the correct direction just a little.

    keyframes = []

    keyframes.append(animation.Keyframe(
        percentage = 0.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    for i in range(0, 100, 5):
        rotation = direction + ((100 - i) / 100 * 10 * (1 if i % 2 == 0 else -1))
        rotation = 360 if rotation > 360 else rotation

        keyframes.append(
            animation.Keyframe(
                percentage = i / 100,
                transforms = [animation.Rotate(rotation)],
                curve = "ease_in_out",
            ),
        )

    keyframes.append(animation.Keyframe(
        percentage = 1.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    return animation.Transformation(
        child = render.Image(src = DIRECTIONAL_ARROW),
        duration = 250,
        delay = 5,
        origin = animation.Origin(0.5, 0.5),
        keyframes = keyframes,
    )

def get_cardinal_position_from_degrees(bearing):
    """ Returns the cardinal position for a given bearing

    Args:
        bearing: in degrees
    Returns:
        The Cardinal position (N, NW, NE, S, SW, SE, E, W)
    """

    if bearing < 0:
        bearing = 360 + bearing

    # have bearning in degrees, now convert to cardinal point
    compass_brackets = ["North", "NNE", "NE", "ENE", "East", "ESE", "SE", "SSE", "South", "SSW", "SW", "WSW", "West", "WNW", "NW", "NNW", "North"]
    display_cardinal_point = compass_brackets[int(math.round(bearing // 22.5))]
    return display_cardinal_point

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "CycleCast by Robert Ison"

    instructions_1 = "CycleCast uses Open Meteo data (open-meteo.com/) to show current conditions for cyclists and outdoor enthusiasts. "
    instructions_2 = "It features a wind rose for direction, a windsock for speed (fluctuating between wind speed and gusts), and sun/moon phases with cloud and rain icons. "
    instructions_3 = "Color-coded boxes indicate UV index, temperature, and humidity—more green means better riding conditions!"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(title, color = "#FF7300", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(instructions_1, color = "#E3D8C5"),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#8F9779"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#FF7300"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", "45")) if config.get("scroll", "45") in ["30", "45", "60"] else 45,
    )

def render_error(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, align = "center", color = "#ff0"))

def parse_coordinate(value, minimum, maximum):
    text = str(value)
    unsigned = text[1:] if text.startswith("-") else text
    if not unsigned or len(text) > 20 or unsigned.count(".") > 1 or not unsigned.replace(".", "").isdigit():
        return None
    number = float(text)
    return number if minimum <= number and number <= maximum else None

def parse_location(raw):
    location = json.decode(raw, None) if type(raw) == "string" else raw
    if type(location) != "dict":
        return None
    latitude = parse_coordinate(location.get("lat"), -90, 90)
    longitude = parse_coordinate(location.get("lng"), -180, 180)
    return (latitude, longitude) if latitude != None and longitude != None else None

def get_animated_windsock(wind, gusts):
    children = []

    for _ in range(1, 3):
        for _ in range(0, 10):
            children.append(render.Image(src = WINDSOCKS[str(get_wind_sock_category(float(wind)))]))

        for j in range(get_wind_sock_category(float(wind)), get_wind_sock_category(float(gusts)) + 1):
            for _ in range(0, 2):
                children.append(render.Image(src = WINDSOCKS[str(j)]))

        for k in range(get_wind_sock_category(float(gusts)), get_wind_sock_category(float(wind)) - 1, -1):
            for _ in range(0, 6):
                children.append(render.Image(src = WINDSOCKS[str(k)]))

    return render.Animation(
        children = children,
    )

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    # Get location needed for local weather
    location = parse_location(config.get("location", DEFAULT_LOCATION))
    if location == None:
        return render_error("Configure a valid location")
    exact_latitude, exact_longitude = location

    # Round lat and lng to 1 decimal to make data available to more people (within about 11km x 11km area) and to not give away our users position exactly
    latitude = round(exact_latitude, 1)
    longitude = round(exact_longitude, 1)
    local_data = get_weather_data(latitude, longitude)
    if local_data == None:
        return render_error("Weather unavailable")

    local_date = local_data["current"]["time"][:10].split("-")
    if len(local_date) != 3 or not all([part.isdigit() for part in local_date]):
        return render_error("Invalid weather data")
    current_year, current_month, current_day = [int(part) for part in local_date]
    if current_year < 2000 or current_year > 2100 or current_month < 1 or current_month > 12 or current_day < 1 or current_day > 31:
        return render_error("Invalid weather data")

    # based on the time period, pull out the current conditions
    current_cloud_cover = get_current_condition(local_data, "cloud_cover")
    current_humidity = get_current_condition(local_data, "relative_humidity_2m")
    current_humidity_value = get_current_condition(local_data, "relative_humidity_2m", False)
    current_probability_precipitation = get_current_condition(local_data, "precipitation_probability")
    current_temperature = get_current_condition(local_data, "temperature_2m")
    current_temperature_value = get_current_condition(local_data, "temperature_2m", False)
    current_apparent_temperature = get_current_condition(local_data, "apparent_temperature")
    current_showers = get_current_condition(local_data, "showers")
    current_uv_index = get_current_condition(local_data, "uv_index", False)
    current_wind_gusts = get_current_condition(local_data, "wind_gusts_10m")
    current_wind_gusts_value = get_current_condition(local_data, "wind_gusts_10m", False)
    current_wind = get_current_condition(local_data, "wind_speed_10m")
    current_wind_value = get_current_condition(local_data, "wind_speed_10m", False)

    # current_rain = get_current_condition(local_data, closest_element_to_now, "rain")
    current_wind_direction = get_current_condition(local_data, "wind_direction_10m", False)

    message = "It is %s but feels like %s with cloud cover of %s and humidity of %s. The probability of precipitation is %s, expect %s of rain. The UV index is %s (%s) with winds from the %s at %s gusting to %s." % (current_temperature, current_apparent_temperature, current_cloud_cover, current_humidity, current_probability_precipitation, current_showers, current_uv_index, get_uv_index_category(current_uv_index), get_cardinal_position_from_degrees(current_wind_direction), current_wind, current_wind_gusts)

    display_items = []
    show_info_bar = config.bool("show_info_bar", False)

    if get_current_condition(local_data, "is_day", False) == 1:
        # print("Daytime")
        display_items.append(render.Box(width = 64, height = 26 if show_info_bar else 32, color = "#004764"))
        display_items.append(add_padding_to_child_element(render.Image(src = SUN_ICON), 48))
    else:
        # print("NightTime")
        display_items.append(add_padding_to_child_element(render.Image(src = MOON_ICONS[str(moon_phase(current_year, current_month, current_day, False))]), 43, -2))

    #Display Rain if Raining
    if get_current_condition(local_data, "rain", False) > 0:
        display_items.append(add_padding_to_child_element(render.Image(src = RAIN_ICON), 40, 6))
    elif get_current_condition(local_data, "cloud_cover", False) > 15:
        display_items.append(add_padding_to_child_element(render.Image(src = CLOUD_ICON), 40, 6))

    # Display The Windsock
    display_items.append(add_padding_to_child_element(get_animated_windsock(current_wind_value, current_wind_gusts_value), 0))

    # To make room for an info bar if requested, need an offset of height of 5 pixels
    height_offset = 0 if show_info_bar else 5

    # Marquee
    if show_info_bar:
        display_items.append(add_padding_to_child_element(get_information_marquee(message), 0, 27))
    else:
        display_items.append(add_padding_to_child_element(render.Image(src = FLAG_BASE), 0, 24))

    # Wind Direction
    if (get_current_condition(local_data, "wind_speed_10m", False) > 0):
        display_items.append(add_padding_to_child_element(render.Image(src = WINDROSE_ICON), 16, 6 + height_offset))
        display_items.append(add_padding_to_child_element(get_wind_rose_display(current_wind_direction), 16, 6 + height_offset))

    # Initialize Info Box Settings
    info_box_height = 9
    info_box_width = 14

    # UV Index Warning
    display_items.append(add_padding_to_child_element(render.Box(color = get_uv_index_category(current_uv_index, True), height = info_box_height, width = info_box_width), 29, 1))
    display_uv_score = str(int(current_uv_index))
    centering_additional_offet = int((info_box_width - (3 * len(display_uv_score)) - len(display_uv_score)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 3))
    display_items.append(add_padding_to_child_element(render.Text(str(int(display_uv_score)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 3))

    # Current Temperature
    display_items.append(add_padding_to_child_element(render.Box(color = get_temperature_color_code(current_temperature_value), height = info_box_height, width = info_box_width), 29, 17 + height_offset))
    display_temp = str(int(current_temperature_value))

    # To center the numbers, we need to have an offset based on the number of characters to display
    centering_additional_offet = int((info_box_width - (3 * len(display_temp)) - len(display_temp)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(str(int(current_temperature_value)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 19 + height_offset))

    # Humidity Box
    display_items.append(add_padding_to_child_element(render.Box(color = get_humidity_color_code(current_humidity_value), height = info_box_height, width = info_box_width), 49, 17 + height_offset))
    display_humidity = str(int(current_humidity_value))
    centering_additional_offet = int((info_box_width - (3 * len(display_humidity)) - len(display_humidity)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 51, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(display_humidity, font = "CG-pixel-3x5-mono", color = "#fff"), 49 + centering_additional_offet, 19 + height_offset))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", "45")) if config.get("scroll", "45") in ["30", "45", "60"] else 45,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show instructions on this app when first installing.",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location used for gathering weather data.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_info_bar",
                name = "Information Bar",
                desc = "Add an information bar at the bottom that provides more weather info.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
