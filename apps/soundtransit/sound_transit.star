"""Show upcoming Sound Transit Link light rail arrivals."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NONE_STR = "__NONE__"
STATION1_DEFAULT = "40_99603"
STATION2_DEFAULT = "40_99610"
API_URL = "https://api.pugetsound.onebusaway.org/api/where/schedule-for-stop"

def config_value(value, default):
    if type(value) != "string" or not value.strip():
        return default
    value = value.strip()
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value") if type(option) == "dict" else None
    return value.strip() if type(value) == "string" and value.strip() else default

def valid_station(station):
    return len(station) <= 40 and all([station[i].isalnum() or station[i] in ["_", "-"] for i in range(len(station))])

def route_color(value):
    value = str(value or "")
    hex_chars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    if len(value) == 6 and all([value[i].lower() in hex_chars for i in range(len(value))]):
        return "#" + value
    return "#000000"

def get_stop_data(station, api_key, now):
    response = http.get(
        "%s/%s.json" % (API_URL, station),
        params = {"key": api_key},
        headers = {"Accept": "application/json"},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return []
    payload = json.decode(body, {})
    data = payload.get("data") if type(payload) == "dict" else None
    references = data.get("references") if type(data) == "dict" else None
    route_list = references.get("routes") if type(references) == "dict" else None
    entry = data.get("entry") if type(data) == "dict" else None
    schedules = entry.get("stopRouteSchedules") if type(entry) == "dict" else None
    if type(route_list) != "list" or type(schedules) != "list":
        return []

    routes = {}
    for route in route_list[:100]:
        if type(route) == "dict" and type(route.get("id")) == "string":
            routes[route["id"]] = route

    result = []
    for schedule in schedules[:50]:
        if type(schedule) != "dict":
            continue
        route = routes.get(schedule.get("routeId"), {})
        directions = schedule.get("stopRouteDirectionSchedules")
        if type(directions) != "list":
            continue
        for direction in directions[:20]:
            if type(direction) != "dict":
                continue
            stop_times = direction.get("scheduleStopTimes")
            if type(stop_times) != "list":
                continue
            minutes = []
            for stop_time in stop_times[:200]:
                arrival = stop_time.get("arrivalTime") if type(stop_time) == "dict" else None
                if type(arrival) not in ["int", "float"]:
                    continue
                remaining = int((arrival / 1000 - now) / 60)
                if remaining >= 0 and remaining <= 240:
                    minutes.append(str(remaining))
                if len(minutes) == 4:
                    break
            if minutes:
                short_name = str(route.get("shortName") or "L")[:2]
                result.append(struct(
                    color = route_color(route.get("color")),
                    name = short_name,
                    headsign = str(direction.get("tripHeadsign") or "Link")[:80],
                    times = ",".join(minutes),
                ))
    return result[:8]

def stop_rows(stops, scroll_names):
    rows = []
    for stop in stops:
        heading = render.Text(stop.headsign if scroll_names else stop.headsign[:12], font = "CG-pixel-4x5-mono")
        if scroll_names and len(stop.headsign) > 12:
            heading = render.Marquee(width = 46, child = heading)
        rows.append(render.Row(children = [
            render.Padding(child = render.Circle(color = stop.color, diameter = 13, child = render.Text(stop.name)), pad = (1, 1, 0, 0)),
            render.Padding(child = render.Column(children = [heading, render.Text(stop.times, color = "#B84")]), pad = (1, 2, 0, 0)),
        ]))
    return rows

def main(config):
    station1 = config_value(config.get("station1"), STATION1_DEFAULT)
    station2 = config_value(config.get("station2"), STATION2_DEFAULT)
    api_key = config_value(config.get("oba_api_key"), "OBAKEY")
    stations = [station for station in [station1, station2] if station != NONE_STR]
    if not stations or any([not valid_station(station) for station in stations]) or len(api_key) > 256:
        return render.Root(child = render.WrappedText("Configure valid Link stations", width = 64, align = "center"))

    now = time.now().unix
    scroll_names = config.bool("scroll_names", True)
    children = []
    for station in stations:
        rows = stop_rows(get_stop_data(station, api_key, now), scroll_names)
        if children:
            children.append(render.Box(color = "#444", height = 1, width = 64))
        children.extend(rows or [render.WrappedText("No upcoming trains", width = 64, align = "center")])
    return render.Root(
        child = render.Marquee(height = 32, child = render.Column(children = children), scroll_direction = "vertical"),
        delay = 150 if scroll_names else 5000,
        max_age = 60,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "station1", name = "Top station", desc = "OneBusAway stop ID for the first Link station.", icon = "arrowUp", default = STATION1_DEFAULT),
        schema.Text(id = "station2", name = "Bottom station", desc = "OneBusAway stop ID for the second station, or __NONE__.", icon = "arrowDown", default = STATION2_DEFAULT),
        schema.Toggle(id = "scroll_names", name = "Scroll names", desc = "Scroll long destination names.", icon = "scissors", default = True),
        schema.Text(id = "oba_api_key", name = "OBA API Key", desc = "Optional OneBusAway API key from Sound Transit.", icon = "key", secret = True),
    ])
