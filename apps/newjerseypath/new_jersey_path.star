"""
Applet: New Jersey PATH
Summary: NJ Path real-time arrivals
Description: Displays real-time departures for a New Jersey PATH station.
Author: karmeleon
Updated: API modernization
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Updated API endpoint
PATH_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json"
HEADERS = {"User-Agent": "Niblet/1.0 support@heyniblet.com"}

# Station mapping - keys are used in config, values are station IDs from new API
STATIONS = {
    "fourteenth_street": "14S",
    "twenty_third_street": "23S",
    "thirty_third_street": "33S",
    "christopher_street": "CHR",
    "exchange_place": "EXP",
    "grove_street": "GRV",
    "harrison": "HAR",
    "hoboken": "HOB",
    "journal_square": "JSQ",
    "newark": "NWK",
    "newport": "NEW",
    "ninth_street": "09S",
    "world_trade_center": "WTC",
}

# Display names for stations
STATION_NAMES = {
    "fourteenth_street": "14th Street",
    "twenty_third_street": "23rd Street",
    "thirty_third_street": "33rd Street",
    "christopher_street": "Christopher Street",
    "exchange_place": "Exchange Place",
    "grove_street": "Grove Street",
    "harrison": "Harrison",
    "hoboken": "Hoboken",
    "journal_square": "Journal Square",
    "newark": "Newark",
    "newport": "Newport",
    "ninth_street": "Ninth Street",
    "world_trade_center": "World Trade Center",
}

def get_display_row(message, widgetMode):
    """Create a display row for a single route"""

    # Use the provided arrival time message
    wait_time_text = message["arrivalTimeMessage"]
    if wait_time_text == "0 min":
        wait_time_text = "now"

    # Convert hex color to proper format
    colors = [safe_color(color) for color in message["lineColor"].split(",")]
    if len(colors) > 1:
        line_color1 = colors[0]
        line_color2 = colors[-1]

        # make a circle, half of each color
        circle_widget = render.PieChart(
            colors = [line_color1, line_color2],
            weights = [100, 100],
            diameter = 11,
        )
    else:  # it's a single color
        line_color1 = colors[0]

        # make a circle - for ease of troubleshooting it's going to be a piechart, although it doesn't need to be
        circle_widget = render.PieChart(
            colors = [line_color1],
            weights = [100],
            diameter = 11,
        )

    return render.Row(
        children = [
            render.Padding(
                child = circle_widget,
                pad = 2,
            ),
            render.Column(
                cross_align = "start",
                children = [
                    render.Marquee(
                        child = render.Text(message["headSign"]),
                        width = 49,
                    ) if not widgetMode else render.Text(message["headSign"]),
                    render.Text(
                        content = wait_time_text,
                        color = "#ffa500",
                        offset = 1,
                    ),
                ],
            ),
        ],
    )

def parse_api_response(api_response, station_id, direction):
    """Parse the new API response format to find relevant trains"""
    messages = []

    # Find our station in the results
    if type(api_response) != "dict" or type(api_response.get("results")) != "list":
        return []
    for station in api_response["results"]:
        if type(station) != "dict" or station.get("consideredStation") != station_id or type(station.get("destinations")) != "list":
            continue

        # Process each destination direction
        for dest in station["destinations"]:
            if type(dest) != "dict" or dest.get("label") not in ["ToNY", "ToNJ"] or type(dest.get("messages")) != "list":
                continue

            # Map API direction labels to our direction values
            current_direction = "TO_NY" if dest["label"] == "ToNY" else "TO_NJ"

            # Skip if we're filtering by direction and this isn't the one we want
            if direction != "both" and direction != current_direction:
                continue

            # Add all messages for this direction
            for message in dest["messages"]:
                if type(message) != "dict":
                    continue
                seconds = message.get("secondsToArrival")
                if type(seconds) != "string" or not seconds.isdigit():
                    continue
                if type(message.get("arrivalTimeMessage")) != "string" or type(message.get("headSign")) != "string" or type(message.get("lineColor")) != "string":
                    continue
                messages.append(message)

    # Sort by arrival time
    return sorted(messages, key = lambda x: int(x["secondsToArrival"]))

def query_api():
    """Query the PATH API with caching"""
    api_response = http.get(PATH_URL, headers = HEADERS, ttl_seconds = 30)
    if api_response.status_code != 200:
        return None
    response = api_response.json()
    return response if type(response) == "dict" else None

def main(config):
    station = config.get("station") or "grove_street"
    desired_direction = config.get("direction") or "both"
    if station not in STATIONS:
        station = "grove_street"
    if desired_direction not in ["both", "TO_NY", "TO_NJ"]:
        desired_direction = "both"
    widgetMode = config.bool("$widget")

    api_response = query_api()
    messages = parse_api_response(api_response, STATIONS[station], desired_direction) if api_response != None else []

    if len(messages) == 0:
        extra_text = ""
        if desired_direction != "both":
            extra_text = " toward {}".format("NY" if desired_direction == "TO_NY" else "NJ")
        text_content = "No scheduled PATH departures from {}{}.".format(STATION_NAMES[station], extra_text)
        content = render.WrappedText(text_content, font = "tom-thumb")
    elif len(messages) == 1:
        content = get_display_row(messages[0], widgetMode)
    else:
        content = render.Column(
            children = [
                get_display_row(messages[0], widgetMode),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                get_display_row(messages[1], widgetMode),
            ],
        )

    return render.Root(
        child = content,
        max_age = 60,
        delay = 100,
    )

def safe_color(value):
    value = value.strip().lower()
    if len(value) != 6 or len([char for char in value.elems() if char not in "0123456789abcdef"]) > 0:
        return "#888888"
    return "#" + value

def get_station_options():
    """Generate station options for the config schema"""
    options = []
    for value, display in STATION_NAMES.items():
        options.append(schema.Option(
            display = display,
            value = value,
        ))
    return options

def get_schema():
    """Define the config schema"""
    station_options = get_station_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "The station to view arrivals for.",
                icon = "trainSubway",
                options = station_options,
                default = station_options[0].value,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "The direction to display arrivals for.",
                icon = "arrowsTurnToDots",
                options = [
                    schema.Option(
                        display = "Both",
                        value = "both",
                    ),
                    schema.Option(
                        display = "NY",
                        value = "TO_NY",
                    ),
                    schema.Option(
                        display = "NJ",
                        value = "TO_NJ",
                    ),
                ],
                default = "both",
            ),
        ],
    )
