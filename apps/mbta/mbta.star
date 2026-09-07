"""Show upcoming MBTA departures."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://api-v3.mbta.com/predictions"
DEFAULT_STOP = "place-sstat"
MAX_DEPARTURES = 3
MINUTES = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "15", "20", "25", "30", "45", "60"]
T_ABBREV = {
    "Blue": "BL",
    "Mattapan": "M",
    "Orange": "OL",
    "Red": "RL",
    "Commuter Rail": "CR",
    "Ferry": "F",
}

def stop_config(value):
    """Read a direct stop and the option JSON saved by the old location picker."""
    value = value.strip() if type(value) == "string" else ""
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value", "") if type(option) == "dict" else ""
    value = value.strip() if type(value) == "string" else ""
    if not value:
        value = DEFAULT_STOP
    parts = value.split("|")
    if len(parts) > 2:
        return None
    stop_id = parts[0]
    route_id = parts[1] if len(parts) == 2 else ""
    if not valid_id(stop_id) or route_id and not valid_id(route_id):
        return None
    return stop_id, route_id

def valid_id(value):
    return value and len(value) <= 80 and all([value[i].isalnum() or value[i] in ["-", "_", "."] for i in range(len(value))])

def api_data(stop_id, route_id, api_key):
    params = {
        "sort": "departure_time",
        "include": "route,trip",
        "filter[stop]": stop_id,
        "page[limit]": "200",
    }
    if route_id:
        params["filter[route]"] = route_id
    if api_key:
        params["api_key"] = api_key
    response = http.get(API_URL, params = params, headers = {"Accept": "application/vnd.api+json"})
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return None
    data = json.decode(body, None)
    return data if type(data) == "dict" else None

def index_included(body, kind):
    result = {}
    included = body.get("included")
    if type(included) != "list":
        return result
    for item in included[:400]:
        if type(item) == "dict" and item.get("type") == kind and type(item.get("id")) == "string":
            result[item["id"]] = item
    return result

def relationship_id(prediction, name):
    relationships = prediction.get("relationships")
    relation = relationships.get(name) if type(relationships) == "dict" else None
    data = relation.get("data") if type(relation) == "dict" else None
    return data.get("id") if type(data) == "dict" and type(data.get("id")) == "string" else ""

def safe_colour(value, fallback):
    value = value.lower() if type(value) == "string" else ""
    chars = "0123456789abcdef"
    return "#" + value if len(value) == 6 and all([value[i] in chars for i in range(6)]) else fallback

def departure_headsign(prediction, route_attrs, trips):
    trip = trips.get(relationship_id(prediction, "trip"), {})
    trip_attrs = trip.get("attributes") if type(trip) == "dict" else None
    if type(trip_attrs) == "dict" and type(trip_attrs.get("headsign")) == "string" and trip_attrs["headsign"]:
        return trip_attrs["headsign"][:120].upper()

    attrs = prediction.get("attributes", {})
    destinations = route_attrs.get("direction_destinations")
    direction = attrs.get("direction_id")
    if type(destinations) == "list" and type(direction) == "int" and direction >= 0 and direction < len(destinations):
        value = destinations[direction]
        return value[:120].upper() if type(value) == "string" else ""
    return ""

def departures(body, now, minimum):
    routes = index_included(body, "route")
    trips = index_included(body, "trip")
    data = body.get("data")
    if type(data) != "list":
        return []

    result = []
    for prediction in data[:200]:
        if type(prediction) != "dict":
            continue
        attrs = prediction.get("attributes")
        if type(attrs) != "dict" or attrs.get("schedule_relationship") in ["SKIPPED", "CANCELLED"]:
            continue
        timestamp = attrs.get("arrival_time") or attrs.get("departure_time")
        if type(timestamp) != "string" or len(timestamp) < 20 or len(timestamp) > 40:
            continue
        remaining = time.parse_time(timestamp) - now
        if remaining.minutes < 0 or remaining.minutes < minimum:
            continue

        route = routes.get(relationship_id(prediction, "route"))
        route_attrs = route.get("attributes") if type(route) == "dict" else None
        if type(route_attrs) != "dict":
            continue
        short_name = route_attrs.get("short_name") or T_ABBREV.get(route.get("id"), "") or T_ABBREV.get(route_attrs.get("fare_class"), "")
        status = attrs.get("status")
        result.append({
            "short_name": str(short_name or "?")[:4],
            "color": safe_colour(route_attrs.get("color"), "#ffc72c"),
            "text_color": safe_colour(route_attrs.get("text_color"), "#000000"),
            "headsign": departure_headsign(prediction, route_attrs, trips),
            "minutes": int(remaining.minutes + 0.5),
            "status": status[:80] if type(status) == "string" else "",
        })
        if len(result) == MAX_DEPARTURES:
            break
    return result

def message(text):
    return render.Root(child = render.Marquee(width = 64, child = render.Text(text, height = 8, offset = -1, font = "Dina_r400-6")))

def departure_row(item):
    heading = item["headsign"]
    if item["status"]:
        heading += " · " + item["status"]
    return render.Row(main_align = "space_between", cross_align = "center", children = [
        render.Circle(
            diameter = 12,
            color = item["color"],
            child = render.Text(item["short_name"], color = item["text_color"], font = "CG-pixel-3x5-mono" if len(item["short_name"]) > 2 else "tb-8"),
        ),
        render.Box(width = 2, height = 5),
        render.Column(main_align = "start", cross_align = "left", children = [
            render.Marquee(width = 50, child = render.Text(heading, height = 8, offset = -1, font = "Dina_r400-6")),
            render.Text("%d min" % item["minutes"] if item["minutes"] else "Now", height = 8, offset = -1, font = "Dina_r400-6", color = "#ffd11a"),
        ]),
    ])

def main(config):
    stop = stop_config(config.get("stop"))
    api_key = config.str("api", "").strip()
    minimum_value = config.str("mintime", "0")
    if not stop or len(api_key) > 512 or minimum_value not in MINUTES:
        return message("Configure a valid MBTA stop")
    body = api_data(stop[0], stop[1], api_key)
    if body == None:
        return message("MBTA unavailable")
    items = departures(body, time.now(), int(minimum_value))
    if not items:
        return message("No departures")
    rows = []
    for item in items:
        rows.extend([departure_row(item), render.Box(height = 1, width = 64, color = "#8c8c8c")])
    return render.Root(max_age = 60, delay = 2000, show_full_animation = True, child = render.Column(children = rows))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(
            id = "stop",
            name = "Stop",
            desc = "MBTA stop ID, optionally followed by | and a route ID. Existing location-picker selections continue to work.",
            icon = "bus",
            default = DEFAULT_STOP,
        ),
        schema.Dropdown(
            id = "mintime",
            name = "Show arriving in",
            desc = "Minimum arrival time.",
            icon = "bus",
            default = "0",
            options = [schema.Option(display = value + " minutes", value = value) for value in MINUTES],
        ),
        schema.Text(
            id = "api",
            name = "MBTA v3 API Key",
            desc = "Optional key from mbta.com/developers/v3-api; anonymous quota is supported.",
            icon = "gear",
            secret = True,
        ),
    ])
