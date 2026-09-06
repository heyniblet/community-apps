"""
Applet: CO2 Signal
Summary: Local power CO2 intensity
Description: Shows the carbon intensity of your local electricity using the Electricity Maps API.
Author: Harper Trow
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://api.electricitymaps.com/v3"  # base electricity maps api url
MAX_RESPONSE_BYTES = 256 * 1024
FONT = "tom-thumb"

def main(config):
    location = config.get("location") or json.encode({
        "lat": "37.63247",
        "lng": "-77.58936",
    })
    api_key = str(config.get("api_key") or "")[:512]

    if not api_key:
        return render_message("Configure Settings")
    else:
        return render_data(api_key, location)

# Location and electricity API key are required settings.
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Set your current location",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Electricity Maps API key",
                desc = "Get API key: https://www.electricitymaps.com/get-started",
                icon = "gear",
                secret = True,
            ),
        ],
    )

# Render the message in the center of the screen.
def render_message(message):
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            "Electricity Maps CO2",
                            font = FONT,
                            color = "#fa0",
                        ),
                        render.WrappedText(
                            message,
                            font = FONT,
                            color = "#fa0",
                        ),
                    ],
                ),
            ],
        ),
    )

# Get and render Electricity Maps data for the given api key and location.
def render_data(api_key, location):
    data = get_data(api_key, location)

    if data == None:
        return render_message("Couldn't retrieve data")

    else:
        fossil_fuel_percentage = math.round(data["fossil_fuel_percentage"])
        fossil_fuel_color = get_fossil_fuel_color(fossil_fuel_percentage)

        # Frame 1: Original Carbon Intensity
        frame_main = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            data["grid"],
                            font = FONT,
                        ),
                        render.WrappedText(
                            "%s %s" % (int(data["carbon_intensity"]), data["intensity_units"]),
                            font = FONT,
                        ),
                        render.WrappedText(
                            "fossil: %s%%" % fossil_fuel_percentage,
                            font = FONT,
                            color = fossil_fuel_color,
                        ),
                    ],
                ),
            ],
        )

        # Frame 2: Renewable Gauge
        frame_renewable = render_gauge("Renewable", data["renewable_percentage"])

        # Frame 3: Fossil Free Gauge
        frame_fossil_free = render_gauge("Fossil Free", data["fossil_free_percentage"])

        return render.Root(
            delay = 3000,
            child = render.Animation(
                children = [
                    frame_main,
                    frame_renewable,
                    frame_fossil_free,
                ],
            ),
        )

# Get Electricity Maps data for the given API key and location.
def get_data(api_key, location_string):
    location = json.decode(location_string, None)
    if type(location) != "dict":
        return None
    latitude = coordinate(location.get("lat"), -90, 90)
    longitude = coordinate(location.get("lng"), -180, 180)
    if latitude == None or longitude == None:
        return None

    # Normalize coordinates before sending them to the provider.
    params = {
        "lat": humanize.float("#.#####", latitude),
        "lon": humanize.float("#.#####", longitude),
    }
    headers = {"auth-token": api_key}
    raw_intensity = request_json("%s/carbon-intensity/latest" % BASE_URL, params, headers)
    if raw_intensity == None or type(raw_intensity.get("carbonIntensity")) not in ["int", "float"]:
        return None
    raw_breakdown = request_json("%s/power-breakdown/latest" % BASE_URL, params, headers)
    fossil_free_percentage = percentage(raw_breakdown.get("fossilFreePercentage")) if raw_breakdown else 0
    renewable_percentage = percentage(raw_breakdown.get("renewablePercentage")) if raw_breakdown else 0
    return {
        "grid": str(raw_intensity.get("zone") or "Unknown")[:80],
        "carbon_intensity": raw_intensity["carbonIntensity"],
        "fossil_fuel_percentage": 100 - fossil_free_percentage,
        "fossil_free_percentage": fossil_free_percentage,
        "renewable_percentage": renewable_percentage,
        "intensity_units": "gCO2eq/kWh",
    }

def coordinate(value, minimum, maximum):
    value = str(value or "")
    if not value or len(value) > 24:
        return None
    dots = 0
    for index, char in enumerate(value.elems()):
        if char == ".":
            dots += 1
        elif char == "-" and index == 0:
            pass
        elif char not in "0123456789":
            return None
    if dots > 1 or value in ["-", ".", "-."]:
        return None
    number = float(value)
    return number if number >= minimum and number <= maximum else None

def request_json(url, params, headers):
    response = http.get(url, params = params, headers = headers)
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return data if type(data) == "dict" else None

def percentage(value):
    return max(0, min(100, int(value))) if type(value) in ["int", "float"] else 0

# Get the color highlighting the fossil fuel intensity percentage.
def get_fossil_fuel_color(fossil_fuel_percentage):
    fossil_fuel_int = int(fossil_fuel_percentage)

    if fossil_fuel_int < 25:
        return "#0f0"  # green
    elif fossil_fuel_int < 50:
        return "#ff0"  # yellow
    elif fossil_fuel_int < 66:
        return "#ffa500"  # orange

    return "#f00"  # red

# Get the color for efficiency metrics (higher is better).
def get_efficiency_color(percentage):
    if percentage >= 66:
        return "#0f0"  # green
    elif percentage >= 33:
        return "#ff0"  # yellow
    return "#f00"  # red

# Render a ring gauge with the percentage in the center.
def render_gauge(title, percentage):
    color = get_efficiency_color(percentage)

    # Ring parameters
    radius = 10
    dot_size = 3
    center = 12

    # Generate dots for the "track" (background ring)
    track_dots = []
    for i in range(0, 360, 10):
        angle = math.radians(i - 90)
        x = center + int(radius * math.cos(angle)) - 1
        y = center + int(radius * math.sin(angle)) - 1
        track_dots.append(
            render.Padding(
                pad = (x, y, 0, 0),
                child = render.Circle(diameter = dot_size, color = "#333"),
            ),
        )

    # Generate dots for the progress
    progress_dots = []
    end_angle = int(360 * percentage / 100)
    for i in range(0, end_angle, 10):
        angle = math.radians(i - 90)
        x = center + int(radius * math.cos(angle)) - 1
        y = center + int(radius * math.sin(angle)) - 1
        progress_dots.append(
            render.Padding(
                pad = (x, y, 0, 0),
                child = render.Circle(diameter = dot_size, color = color),
            ),
        )

    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(title, font = FONT, color = "#fa0"),
            render.Box(height = 1),
            render.Stack(
                children = [
                    # Container for the rings
                    render.Box(
                        width = 24,
                        height = 24,
                        child = render.Stack(children = track_dots + progress_dots),
                    ),
                    # Text in the middle
                    render.Box(
                        width = 24,
                        height = 24,
                        child = render.Row(
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Text("%d%%" % percentage, font = "tom-thumb", color = "#fff"),
                            ],
                        ),
                    ),
                ],
            ),
        ],
    )
