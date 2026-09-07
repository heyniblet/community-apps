"""Show real-time Melbourne bus departures from the PTV Timetable API."""

load("encoding/json.star", "json")
load("hmac.star", "hmac")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://timetableapi.ptv.vic.gov.au"
DEFAULT_STOP_DATA = '{"stop_id":"10002","stop_name":"Dalgety St/Warrigal Rd","stop_routes":{"3453":{"route_number":"802C"},"8922":{"route_number":"862"},"8924":{"route_number":"802"},"8934":{"route_number":"804"},"13820":{"route_number":"800"}}}'
FONT = "Dina_r400-6"

def stop_config(value):
    """Read direct JSON and the nested option JSON saved by the old picker."""
    value = value.strip() if type(value) == "string" else ""
    if not value:
        value = DEFAULT_STOP_DATA
    decoded = json.decode(value, None)
    if type(decoded) == "dict" and type(decoded.get("value")) == "string":
        decoded = json.decode(decoded["value"], None)
    if type(decoded) != "dict":
        return None

    stop_id = decoded.get("stop_id")
    stop_name = decoded.get("stop_name")
    routes = decoded.get("stop_routes")
    if type(stop_id) not in ["int", "string"] or not str(stop_id).isdigit() or len(str(stop_id)) > 20:
        return None
    if type(stop_name) != "string" or not stop_name.strip() or len(stop_name) > 120 or type(routes) != "dict" or len(routes) > 50:
        return None

    clean_routes = {}
    for route_id, route in routes.items():
        number = route.get("route_number") if type(route) == "dict" else None
        if type(route_id) == "string" and route_id.isdigit() and len(route_id) <= 20 and type(number) == "string" and number:
            clean_routes[route_id] = number[:8]
    if not clean_routes:
        return None
    return {"stop_id": str(stop_id), "stop_name": stop_name.strip()[:120], "stop_routes": clean_routes}

def ptv_json(stop_id, api_id, api_key):
    path = "/v3/departures/route_type/2/stop/" + stop_id
    query = "max_results=20&include_cancelled=false&devid=" + api_id
    signature = hmac.sha1(api_key, path + "?" + query).upper()
    response = http.get(BASE_URL + path + "?" + query + "&signature=" + signature, headers = {"Accept": "application/json"})
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return None
    data = json.decode(body, None)
    return data if type(data) == "dict" else None

def remaining_minutes(value, now):
    if type(value) != "string" or len(value) < 20 or len(value) > 40:
        return None
    minutes = int((time.parse_time(value) - now).minutes)
    return minutes if minutes >= 0 and minutes <= 240 else None

def departures(stop, api_id, api_key):
    data = ptv_json(stop["stop_id"], api_id, api_key)
    items = data.get("departures") if type(data) == "dict" else None
    if type(items) != "list":
        return None

    now = time.now()
    result = []
    for item in items[:100]:
        if type(item) != "dict":
            continue
        route_id = item.get("route_id")
        route_id = str(route_id) if type(route_id) in ["int", "string"] else ""
        route_number = stop["stop_routes"].get(route_id)
        minutes = remaining_minutes(item.get("estimated_departure_utc") or item.get("scheduled_departure_utc"), now)
        if not route_number or minutes == None or "C" in route_number:
            continue
        result.append({"route": route_number, "minutes": minutes})
    return sorted(result, key = lambda item: item["minutes"])[:2]

def colour(minutes):
    if minutes <= 10:
        return "#E60707"
    if minutes <= 20:
        return "#F3B22C"
    return "#00E400"

def departure_row(item):
    eta = "now" if item["minutes"] == 0 else "%d mins" % item["minutes"]
    return render.Row(expanded = True, main_align = "space_between", cross_align = "center", children = [
        render.Box(color = colour(item["minutes"]), width = 26, height = 10, child = render.Text(item["route"], color = "#000000", font = "5x8")),
        render.Text(eta, color = "#F3AB3F"),
    ])

def message(text):
    return render.Root(child = render.WrappedText(text, width = 64, align = "center"))

def main(config):
    stop = stop_config(config.get("stop_data"))
    api_id = config.str("ptv_api_id", "").strip()
    api_key = config.str("ptv_api_key", "").strip()
    if not stop or not api_id.isdigit() or len(api_id) > 20 or not api_key or len(api_key) > 256:
        return message("Configure PTV stop and credentials")
    items = departures(stop, api_id, api_key)
    if items == None:
        return message("PTV API unavailable")
    if not items:
        return message("No bus departures found")

    children = [
        render.Row(expanded = True, main_align = "space_around", cross_align = "center", children = [
            render.Box(color = "#FF8200", width = 16, height = 8, child = render.Text("BUS", color = "#FFFFFF", font = "5x8")),
            render.Marquee(width = 46, child = render.Text(stop["stop_name"].upper(), font = FONT, offset = -2, height = 7)),
        ]),
        render.Box(width = 64, height = 1, color = "#666666"),
    ]
    for item in items:
        children.extend([departure_row(item), render.Box(width = 64, height = 1, color = "#666666")])
    return render.Root(max_age = 60, delay = 2000, show_full_animation = True, child = render.Column(expanded = True, main_align = "start", children = children))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(
            id = "stop_data",
            name = "Bus stop",
            desc = "PTV stop JSON containing stop_id, stop_name and stop_routes. Existing location-picker selections continue to work.",
            icon = "locationDot",
            default = DEFAULT_STOP_DATA,
        ),
        schema.Text(id = "ptv_api_id", name = "PTV API ID", desc = "Developer ID from the PTV Timetable API portal.", icon = "key", secret = True),
        schema.Text(id = "ptv_api_key", name = "PTV API Key", desc = "Secret key from the PTV Timetable API portal.", icon = "key", secret = True),
    ])
