"""Show upcoming Puget Sound transit arrivals for a stop."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop"
DEFAULT_STOP_ID = "29_2229"
FONT = "CG-pixel-3x5-mono"

def config_value(value, default):
    if type(value) != "string" or not value.strip():
        return default
    value = value.strip()
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value") if type(option) == "dict" else None
    return value.strip() if type(value) == "string" and value.strip() else default

def valid_stop(value):
    return len(value) <= 64 and all([value[i].isalnum() or value[i] in ["-", "_"] for i in range(len(value))])

def color(value, fallback):
    value = str(value or "")
    chars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    return "#" + value if len(value) == 6 and all([value[i].lower() in chars for i in range(6)]) else fallback

def get_data(stop_id, api_key):
    response = http.get(
        "%s/%s.json" % (API_URL, stop_id),
        params = {"key": api_key},
        headers = {"Accept": "application/json"},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return None
    payload = json.decode(body, {})
    data = payload.get("data") if type(payload) == "dict" else None
    entry = data.get("entry") if type(data) == "dict" else None
    references = data.get("references") if type(data) == "dict" else None
    events = entry.get("arrivalsAndDepartures") if type(entry) == "dict" else None
    if type(events) != "list" or type(references) != "dict":
        return None

    routes = {}
    route_list = references.get("routes")
    if type(route_list) == "list":
        for route in route_list[:200]:
            if type(route) == "dict" and type(route.get("id")) == "string":
                routes[route["id"]] = route
    stop_name = "Transit stop"
    stops = references.get("stops")
    if type(stops) == "list" and stops and type(stops[0]) == "dict":
        stop_name = str(stops[0].get("name") or stop_name)[:120]
    current = payload.get("currentTime")
    if type(current) not in ["int", "float"]:
        return None

    rows = []
    seen = {}
    for event in events[:200]:
        if type(event) != "dict":
            continue
        arrival = event.get("predictedArrivalTime") or event.get("scheduledArrivalTime")
        if type(arrival) not in ["int", "float"]:
            continue
        minutes = int((arrival - current) / 60000)
        if minutes < 0 or minutes > 240:
            continue
        route_name = str(event.get("routeShortName") or "?")[:3]
        headsign = str(event.get("tripHeadsign") or "Unknown destination")[:100]
        marker = "%s|%s|%s" % (route_name, headsign, int(arrival))
        if marker in seen:
            continue
        seen[marker] = True
        route = routes.get(event.get("routeId"), {})
        status = event.get("tripStatus")
        deviation = status.get("scheduleDeviation") if type(status) == "dict" else 0
        deviation = deviation if type(deviation) in ["int", "float"] else 0
        rows.append(struct(
            route = route_name,
            headsign = headsign,
            arrival = "due" if minutes == 0 else "%dm" % minutes,
            foreground = color(route.get("textColor"), "#FFFFFF"),
            background = color(route.get("color"), "#000000"),
            status = "#0080FF" if deviation > 59 else ("#FF0000" if deviation < -59 else "#00FF00"),
        ))
        if len(rows) == 4:
            break
    return struct(name = stop_name, rows = rows)

def arrival_row(row, default_color, single_color):
    foreground = default_color if single_color else row.foreground
    background = "#000000" if single_color else row.background
    status = default_color if single_color else row.status
    return render.Row(expanded = True, main_align = "space_between", children = [
        render.Box(width = 12, height = 5, color = background, child = render.Marquee(width = 12, child = render.Text(row.route, color = foreground, font = FONT))),
        render.Marquee(width = 40, align = "center", child = render.Text(row.headsign, color = default_color, font = FONT)),
        render.Marquee(width = 12, align = "end", child = render.Text(row.arrival, color = status, font = FONT)),
    ])

def main(config):
    stop_id = config_value(config.get("stop"), DEFAULT_STOP_ID)
    api_key = config_value(config.get("onebusaway_api_key"), "OBAKEY")
    default_color = config.str("color", "#FFBF00")
    if not valid_stop(stop_id) or len(api_key) > 256 or default_color not in ["#FFBF00", "#FFFFFF"]:
        return render.Root(child = render.WrappedText("Configure a valid transit stop", width = 64, align = "center"))
    data = get_data(stop_id, api_key)
    if data == None:
        return render.Root(child = render.WrappedText("Transit data unavailable", width = 64, align = "center"))
    rows = data.rows
    if not rows:
        return render.Root(child = render.WrappedText("No upcoming arrivals", width = 64, align = "center"))
    children = [
        render.Box(height = 1),
        render.Marquee(width = 64, align = "center", child = render.Text(data.name, color = default_color, font = FONT)),
        render.Box(height = 1),
    ]
    children.extend([arrival_row(row, default_color, config.bool("single_color", False)) for row in rows])
    return render.Root(max_age = 60, child = render.Column(children = children))

def get_schema():
    colors = [schema.Option(display = "Amber", value = "#FFBF00"), schema.Option(display = "White", value = "#FFFFFF")]
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "onebusaway_api_key", name = "OneBusAway API Key", desc = "Optional Puget Sound OneBusAway API key.", icon = "key", secret = True),
        schema.Text(id = "stop", name = "Stop", desc = "OneBusAway stop ID, such as 29_2229.", icon = "bus", default = DEFAULT_STOP_ID),
        schema.Dropdown(id = "color", name = "Default Text Color", desc = "Default display color.", icon = "brush", default = colors[0].value, options = colors),
        schema.Toggle(id = "single_color", name = "Single Color Mode", desc = "Use the selected color for all text.", icon = "palette", default = False),
    ])
