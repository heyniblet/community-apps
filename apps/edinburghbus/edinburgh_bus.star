"""
Applet: Edinburgh Bus
Summary: Shows the next 3 buses
Description: Give it an Edinburgh stop ID and it will show the next 3 arrivals for the next 3 services at that stop.
Author: dan0
"""

# buildifier: disable=<category_name>

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOP = 6200201940
DEFAULT_DISPLAY_DESTINATIONS = False
BUS_URL = "https://lothianapi.co.uk/departureBoards/website/new?stops={}"
MAX_RESPONSE_BYTES = 512 * 1024

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "Stop ID",
                desc = "Enter your preferred Stop ID.",
                icon = "bus",
            ),
            schema.Toggle(
                id = "display_destinations",
                name = "Show Bus Destinations",
                desc = "Show the final destination for each individual arrival for a service.",
                icon = "flag",
                default = False,
            ),
        ],
    )

def main(config):
    # Get stop ID from config or use the default stop ID
    stop_id = valid_stop_id(config.get("stop_id") or DEFAULT_STOP)
    display_destinations = config.bool("display_destinations") or DEFAULT_DISPLAY_DESTINATIONS

    # Fetch bus information using the stop ID
    bus_info = fetch_bus_info(stop_id)

    # Get stop text and bus text for display
    stop_text = get_stop_text(bus_info)
    bus_text = next_buses(bus_info, display_destinations)

    font = config.get("font", "tb-8")

    def render_bus_row(row_info):
        service_name = "" if not row_info[0] else str(row_info[0])
        next_times_text = "" if not row_info[1] else str(row_info[1])

        return render.Row(
            children = [
                render.Box(
                    # Bus service number in red box
                    width = 16,
                    height = 8,
                    padding = 0,
                    color = "#8c1713",
                    child = render.Text(service_name, font = font, color = "#fff"),
                ),
                render.Box(
                    # Black dividing 1px row for padding
                    width = 1,
                    height = 8,
                    padding = 0,
                    color = "#000",
                ),
                render.Marquee(
                    # Marquee showing times of next buses for given service
                    width = 48,
                    child = render.Text(next_times_text, font = font, color = "#FCFCFC"),
                ),
            ],
        )

    def render_divider():
        return render.Box(
            width = 64,
            height = 1,
            color = "#333",
        )

    # Initialize an empty list for the children of the render.Column
    column_children = [
        render.Text(
            content = stop_text,
            color = "#ae9962",
            font = "CG-pixel-3x5-mono",
        ),
    ]

    # Loop through the first three elements of bus_text and add render_bus_row and render_divider for each element
    for bus_info in bus_text[:3]:
        column_children.append(render_divider())
        column_children.append(render_bus_row(bus_info))

    return render.Root(
        child = render.Column(
            children = column_children,
        ),
    )

def fetch_bus_info(stop_id):
    response = http.get(
        BUS_URL.format(stop_id),
        headers = {
            "Accept": "application/json",
            "Origin": "https://www.lothianbuses.com",
            "Referer": "https://www.lothianbuses.com/",
            "User-Agent": "Mozilla/5.0 (compatible; Niblet/1.0; +https://heyniblet.com)",
        },
        ttl_seconds = 30,
    )
    body = response.body()
    payload = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    stop = payload[0] if type(payload) == "list" and payload and type(payload[0]) == "dict" else {}
    services = stop.get("services")
    return {
        "stop": {"name": "Stop", "direction": str(stop_id)[-6:]},
        "services": services[:100] if type(services) == "list" else [],
    }

def valid_stop_id(value):
    value = str(value or "").strip()
    if len(value) < 6 or len(value) > 12 or not value.isdigit():
        return str(DEFAULT_STOP)
    return value

def time_left(minutes):
    # Return "Due" if the time left is 0 or negative, otherwise return the time left in minutes
    time_left_text = "Due" if minutes <= 0 else str(minutes) + "m"

    # if there are over 60 minutes return it in the format eg. 1h 15m
    if minutes > 60:
        time_left_text = str(minutes // 60) + "h " + str(minutes % 60) + "m"

    return time_left_text

def get_stop_text(data):
    # Format and return the stop name and direction as a string
    stop = data.get("stop")
    return (str(stop.get("name") or "Stop") + " " + str(stop.get("direction") or ""))[:80] if type(stop) == "dict" else "Stop unavailable"

def next_buses(data, display_destinations):
    # Initialize an empty list to store the formatted bus information
    lines = []

    # Iterate through the services in the data
    services = data.get("services")
    for service in services if type(services) == "list" else []:
        if type(service) != "dict":
            continue
        line = []

        # Get the departures for each service
        next_three_departures = service.get("departures")
        if type(next_three_departures) != "list":
            continue

        # Format the minutes until each departure
        minutes_list = []
        for departure in next_three_departures[:3]:
            if type(departure) != "dict" or type(departure.get("minutes")) not in ["int", "float"]:
                continue
            readable_time = time_left(int(departure["minutes"]))
            if display_destinations:
                bus_text = str(departure.get("destination") or "")[:80] + " " + readable_time
            else:
                bus_text = readable_time

            minutes_list.append(bus_text)

        line = [str(service.get("service_name") or "?")[:8], " · ".join(minutes_list)]

        # Join the formatted minutes and add the result to the list
        lines.append(line)

    # Join the lines and return the result
    return lines
