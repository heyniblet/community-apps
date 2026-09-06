"""Show scheduled and real-time San Diego MTS trolley arrivals."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NONE_STR = "__NONE__"
DEFAULT_STOP_ID_1 = "MTS_75078"
DEFAULT_STOP_ID_2 = "MTS_75079"
API_URL = "https://realtime.sdmts.com/api/api/where/arrivals-and-departures-for-stop"
ROUTE_COLORS = {"Blue": "#0000FF", "Green": "#009900", "Orange": "#FF6600", "Silver": "#B4BCC2"}

def config_value(value, default):
    if type(value) != "string" or not value.strip():
        return default
    value = value.strip()
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value") if type(option) == "dict" else None
    return value.strip() if type(value) == "string" and value.strip() else default

def valid_stop(stop_id):
    return len(stop_id) <= 40 and all([stop_id[i].isalnum() or stop_id[i] in ["_", "-"] for i in range(len(stop_id))])

def get_arrivals(stop_id, api_key, now):
    response = http.get(
        "%s/%s.json" % (API_URL, stop_id),
        params = {"key": api_key},
        headers = {"Accept": "application/json"},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return {}
    payload = json.decode(body, {})
    data = payload.get("data") if type(payload) == "dict" else None
    entry = data.get("entry") if type(data) == "dict" else None
    events = entry.get("arrivalsAndDepartures") if type(entry) == "dict" else None
    if type(events) != "list":
        return {}

    arrivals = {}
    for event in events[:200]:
        if type(event) != "dict":
            continue
        timestamp = event.get("predictedArrivalTime") if event.get("predicted") else event.get("scheduledArrivalTime")
        if type(timestamp) not in ["int", "float"]:
            continue
        minutes = int((timestamp / 1000 - now) / 60)
        if minutes <= 0 or minutes > 240:
            continue
        heading = str(event.get("tripHeadsign") or "Trolley")[:80]
        route = str(event.get("routeShortName") or "Line")[:20]
        times = arrivals.setdefault(heading, {}).setdefault(route, [])
        if len(times) < 4:
            times.append(str(minutes))
    return arrivals

def show_stop(arrivals):
    rows = []
    for heading in sorted(arrivals.keys())[:6]:
        for route in sorted(arrivals[heading].keys())[:4]:
            rows.append(render.Row(children = [
                render.Padding(child = render.Box(width = 4, height = 12, color = ROUTE_COLORS.get(route, "#B4BCC2")), pad = 2),
                render.Column(children = [
                    render.Text(heading),
                    render.Text(",".join(arrivals[heading][route]), color = "#f2711c"),
                ]),
            ]))
    return render.Column(children = rows or [render.WrappedText("No upcoming trolleys", width = 64, align = "center")])

def main(config):
    stop1 = config_value(config.get("stop1"), DEFAULT_STOP_ID_1)
    stop2 = config_value(config.get("stop2"), DEFAULT_STOP_ID_2)
    api_key = config_value(config.get("mts_api_key"), "OBAKEY")
    stops = [stop for stop in [stop1, stop2] if stop != NONE_STR]
    if not stops or any([not valid_stop(stop) for stop in stops]) or len(api_key) > 256:
        return render.Root(child = render.WrappedText("Configure valid MTS stops", width = 64, align = "center"))
    now = time.now().unix
    children = []
    for stop in stops:
        if children:
            children.append(render.Box(height = 1, width = 64, color = "#fff"))
        children.append(show_stop(get_arrivals(stop, api_key, now)))
    return render.Root(
        child = render.Marquee(height = 32, child = render.Column(children = children), scroll_direction = "vertical"),
        delay = 150,
        max_age = 60,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "stop1", name = "Top station", desc = "MTS stop ID for the first station.", icon = "arrowUp", default = DEFAULT_STOP_ID_1),
        schema.Text(id = "stop2", name = "Bottom station", desc = "MTS stop ID for the second station, or __NONE__.", icon = "arrowDown", default = DEFAULT_STOP_ID_2),
        schema.Text(id = "mts_api_key", name = "MTS API Key", desc = "Optional OneBusAway API key from MTS.", icon = "key", secret = True),
    ])
