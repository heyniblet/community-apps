"""
Applet: AC Transit
Summary: Shows AC Transit bus times
Description: Shows bus departures times for AC Transit.
Author: wshue0
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PREDICTIONS_URL = "https://api.actransit.org/transit/actrealtime/prediction"
DEFAULT_STOPID = "55652"
AC_TRANSIT_TIME_ZONE = "America/Los_Angeles"
AC_TRANSIT_TIME_LAYOUT = "20060102 15:04"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024

def main(config):
    # Initialize API token, bus stop, and max predictions number with fallbacks
    api_key = config.get("api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return render.Root(
            child = render.WrappedText("API key not set. Please configure.", color = "#ff0000"),
        )

    stop_config = config.get("stop_id") or DEFAULT_STOPID
    stop_matches = re.findall(r'"value"\s*:\s*"([0-9]{1,10})"', stop_config) if type(stop_config) == "string" else []
    stop_id = stop_config if type(stop_config) == "string" and stop_config.isdigit() and len(stop_config) <= 10 else stop_matches[0] if stop_matches else None
    if stop_id == None:
        return render.Root(child = render.WrappedText("Enter a valid AC Transit stop ID.", color = "#ff0000"))

    predictions_config = config.get("predictions_max", "2")
    predictions_max = int(predictions_config) if predictions_config in ["1", "2", "3"] else 2

    # Call API to get predictions for the given stop
    data = get_times(stop_id, api_key)
    response_data = data.get("bustime-response") if type(data) == "dict" else None
    predictions = response_data.get("prd") if type(response_data) == "dict" else None
    predictions = predictions[:100] if type(predictions) == "list" else []

    num_predictions = len(predictions)
    bus_entries = {}

    # Create dictionary entry for each unique bus route
    # An entry contains a bus name (usually a number), route (a locale), and an array of departure times in minutes
    for i in range(0, num_predictions):
        prediction = predictions[i]
        timestamp = prediction.get("prdtm") if type(prediction) == "dict" else None
        bus = prediction.get("rtdd") if type(prediction) == "dict" else None
        route = prediction.get("rtdir") if type(prediction) == "dict" else None
        if type(timestamp) != "string" or not re.match(r"^[0-9]{8} [0-9]{2}:[0-9]{2}$", timestamp) or type(bus) != "string" or type(route) != "string":
            continue
        diff = time_from_now(timestamp)
        if diff < 0:
            continue
        bus = bus[:20]
        route = route[:160]
        route_key = bus + route
        if not route_key in bus_entries:
            bus_entries[route_key] = {"bus": bus, "route": route, "departures": [diff]}
        else:
            bus_entries[route_key]["departures"].append(diff)

    # Limit to 4 entries
    bus_entries = sorted(bus_entries.values(), key = lambda x: x["bus"])[:4]

    num_routes = len(bus_entries)

    # Display "No Data" when no predictions are available
    if num_routes == 0:
        return render.Root(
            child = render.Box(
                child = render.Text("No Data", font = "6x13", color = "#fff"),
            ),
        )
        # Display a single entry that takes up the screen

    elif num_routes == 1:
        return render.Root(
            delay = 60,
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Row(
                            main_align = "start",
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Box(
                                    height = 16,
                                    width = 1,
                                ),
                                render.Box(
                                    height = 16,
                                    width = 16,
                                    child = render.Text(bus_entries[0]["bus"], color = "#fff"),
                                    color = "#006747",
                                ),
                                render.Box(
                                    height = 16,
                                    width = 1,
                                ),
                                render.Marquee(
                                    width = 64,
                                    align = "start",
                                    offset_start = 5,
                                    offset_end = 8,
                                    child = render.Text(bus_entries[0]["route"], font = "6x13"),
                                ),
                            ],
                        ),
                        render.Box(
                            height = 10,
                            width = 64,
                            child = render.Text(get_displayed_times(bus_entries[0]["departures"], predictions_max), color = "ffb033"),
                        ),
                    ],
                ),
            ),
        )
        # Display two bus entries that each take up half the screen

    elif num_routes == 2:
        entry1 = render.Box(
            width = 64,
            height = 16,
            child = render.Row(
                main_align = "start",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(
                        height = 16,
                        width = 1,
                    ),
                    render.Box(
                        height = 11,
                        width = 12,
                        child = render.Text(bus_entries[0]["bus"], color = "#fff"),
                        color = "#006747",
                    ),
                    render.Box(
                        height = 12,
                        width = 2,
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = 64,
                                align = "start",
                                offset_start = 5,
                                offset_end = 8,
                                child = render.Text(bus_entries[0]["route"]),
                            ),
                            render.Text(get_displayed_times(bus_entries[0]["departures"], predictions_max), font = "5x8", offset = 1, color = "FFB033"),
                        ],
                    ),
                ],
            ),
        )
        entry2 = render.Box(
            width = 64,
            height = 16,
            child = render.Row(
                main_align = "start",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(
                        height = 16,
                        width = 1,
                    ),
                    render.Box(
                        height = 11,
                        width = 12,
                        child = render.Text(bus_entries[1]["bus"], color = "#fff"),
                        color = "#006747",
                    ),
                    render.Box(
                        height = 12,
                        width = 2,
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = 64,
                                align = "start",
                                offset_start = 5,
                                offset_end = 8,
                                child = render.Text(bus_entries[1]["route"]),
                            ),
                            render.Text(get_displayed_times(bus_entries[1]["departures"], predictions_max), font = "5x8", offset = 1, color = "FFB033"),
                        ],
                    ),
                ],
            ),
        )
        return render.Root(
            delay = 120,
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        entry1,
                        render.Box(
                            height = 1,
                            width = 62,
                            color = "#fff",
                        ),
                        entry2,
                    ],
                ),
            ),
        )
        # Display 3-4 bus entries that are evenly-spaced vertically

    else:
        bus_rows = []
        for entry in bus_entries:
            bus = entry["bus"]
            route = entry["route"]
            departures = get_displayed_times(entry["departures"], predictions_max)
            bus_rows.append(
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 8,
                            width = 2,
                        ),
                        render.Box(
                            height = 6,
                            width = 12,
                            color = "#006747",
                            child = render.Text(bus),
                        ),
                        render.Box(
                            height = 8,
                            width = 2,
                        ),
                        render.Text(departures, color = "#ffb033"),
                    ],
                ),
            )

        return render.Root(
            delay = 100,
            child = render.Box(
                height = 32,
                width = 64,
                child = render.Column(
                    main_align = "space_between",
                    cross_align = "start",
                    expanded = True,
                    children = bus_rows,
                ),
            ),
        )

def time_from_now(ac_timestamp):
    # Calculates an ETA in minutes using the AC Transit timestamp
    now = time.now().in_location(AC_TRANSIT_TIME_ZONE)
    eta_time = time.parse_time(ac_timestamp, AC_TRANSIT_TIME_LAYOUT, AC_TRANSIT_TIME_ZONE)
    diff = eta_time - now
    return int(diff.minutes)

def get_displayed_times(times, predictions_max):
    # Transforms list of departures times in integers to a comma-delimited string
    # Additionally substitutes "0 min" with "now"
    times = sorted(times)[:predictions_max]
    if len(times) == 1 and times[0] == 0:
        return "now"
    times = [str(t) if t != 0 else "now" for t in times]
    return "%s min" % ",".join(times)

def get_times(stop_id, api_key):
    # Hits AC Transit's prediction api if there are no cache hits
    rep = http.get(PREDICTIONS_URL, params = {"stpid": stop_id, "token": api_key})
    if rep.status_code != 200:
        return {"bustime-response": {"prd": []}}

    body = rep.body()
    return json.decode(body, None) if len(body) <= MAX_RESPONSE_BYTES else None

def get_schema():
    # The user selects a stop from a drop-down menu of the 20 closest stops sourced from AC Transit
    # The user also specifies a maximum number of departures times they want displayed per bus
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "predictions_max",
                name = "Departures",
                desc = "Choose number of departures displayed per bus",
                icon = "clock",
                default = "2",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                ],
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your AC Transit API key. See https://api.actransit.org/transit/actrealtime/prediction for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "stop_id",
                name = "Bus Stop",
                desc = "AC Transit stop ID shown on the stop sign or in the official stop list.",
                icon = "bus",
                default = DEFAULT_STOPID,
            ),
        ],
    )
