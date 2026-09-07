"""
Applet: CTA Bus Tracker
Summary: CTA Bus arrival times
Description: View CTA Bus arrival times for the closest stop to your location.
Author: John Sylvain
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = """
{
	"lat": "41.969082",
	"lng": "-87.659828",
	"description": "Chicago, IL, USA",
	"locality": "Chicago",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/Chicago"
}
"""

DEFAULT_ROUTE = "36"
API_BASE = "https://www.ctabustracker.com/bustime/api/v3"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "CTA API Key",
                desc = "Your CTA Bus Tracker API key. See https://www.transitchicago.com/developers/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "route",
                name = "Bus Route",
                desc = "CTA route ID, such as 36, X9, or J14.",
                icon = "bus",
                default = DEFAULT_ROUTE,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Current location for closest bus stop.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide when no service",
                desc = "Hide when no service is scheduled for the selected route.",
                icon = "eye",
                default = True,
            ),
        ],
    )

def main(config):
    api_key = config.get("api_key")
    route = config.get("route", DEFAULT_ROUTE)
    hide = config.bool("hide", True)
    location = config.get("location", DEFAULT_LOCATION)
    if not api_key or len(api_key) > 256:
        return render.Root(child = render.Text("CTA API Key not set"))
    if not route or len(route) > 10:
        return render.Root(child = render.Text("Invalid route"))
    for c in route.elems():
        if c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
            return render.Root(child = render.Text("Invalid route"))
    if len(location) > 2048 or not location.startswith("{"):
        return render.Root(child = render.Text("Invalid location"))
    loc = json.decode(location)
    if type(loc) != "dict" or "lat" not in loc or "lng" not in loc:
        return render.Root(child = render.Text("Invalid location"))
    if float(loc["lat"]) < -90 or float(loc["lat"]) > 90 or float(loc["lng"]) < -180 or float(loc["lng"]) > 180:
        return render.Root(child = render.Text("Invalid location"))

    full_route = get_bus_route(route, api_key)
    if not full_route:
        return render.Root(child = render.Text("Route unavailable"))

    directions = get_bus_route_directions(route, api_key) or []

    stops = [get_nearest_stop(route, direction["dir"], loc, api_key) for direction in directions[:2] if type(direction) == "dict" and direction.get("dir")]

    potential_arrivals = [get_arrivals(route, stop, api_key, full_route) for stop in stops if stop]

    arrivals = []

    for arrival in potential_arrivals:
        if arrival != None:
            arrivals.append(arrival)

    if len(arrivals) == 2:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render_arrival(arrivals[0]),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                    render_arrival(arrivals[1]),
                ],
            ),
        )
    elif len(arrivals) == 1:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render_arrival(arrivals[0]),
                ],
            ),
        )
    elif hide:
        return []
    else:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render_no_arrival(full_route),
                ],
            ),
        )

######################
# Utility methods
######################
def get_distance(lat1, lon1, lat2, lon2):
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    earth_radius = 6371.0

    dlon = lon2_rad - lon1_rad
    dlat = lat2_rad - lat1_rad
    a = math.sin(dlat / 2) * math.sin(dlat / 2) + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) * math.sin(dlon / 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = earth_radius * c

    return distance

######################
# API Calls
######################
def get_nearest_stop(route, direction, current_location, api_key):
    if not api_key:
        return None

    response = http.get(
        API_BASE + "/getstops",
        params = {
            "key": api_key,
            "format": "json",
            "rt": route,
            "dir": direction,
        },
    )

    if response.status_code != 200 or len(response.body()) > 1024 * 1024:
        return None
    data = response.json().get("bustime-response", {})
    if type(data) != "dict" or type(data.get("stops")) != "list":
        return None
    stops = data["stops"][:500]

    shortest_distance = 0.0
    nearest_stop = {}

    for stop in stops:
        if type(stop) != "dict" or "lat" not in stop or "lon" not in stop or not stop.get("stpid"):
            continue
        distance_from_user_to_stop = get_distance(
            float(stop["lat"]),
            float(stop["lon"]),
            float(current_location["lat"]),
            float(current_location["lng"]),
        )
        if distance_from_user_to_stop < shortest_distance or shortest_distance == 0.0:
            shortest_distance = distance_from_user_to_stop
            nearest_stop = stop

    return nearest_stop

def build_route_arrival_time(arrival):
    time = arrival["prdctdn"]

    if time != "DUE" and time != "DLY":
        return time + "m"
    elif time == "DUE":
        return "Due"
    elif time == "DLY":
        return "Delay"
    else:
        return time

def get_arrivals(route, nearest_stop, api_key, full_route):
    if not api_key or not nearest_stop:
        return None

    response = http.get(
        API_BASE + "/getpredictions",
        params = {
            "key": api_key,
            "format": "json",
            "rt": route,
            "stpid": nearest_stop["stpid"],
            "top": "2",
        },
    )

    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return None
    arrivals = response.json().get("bustime-response", {})
    if type(arrivals) != "dict":
        return None

    if "error" in arrivals or type(arrivals.get("prd")) != "list" or not arrivals["prd"]:
        return None

    predictions = [arrival for arrival in arrivals["prd"][:2] if type(arrival) == "dict" and "prdctdn" in arrival and "des" in arrival and "rt" in arrival]
    if not predictions:
        return None
    times = [build_route_arrival_time(arrival) for arrival in predictions]

    return {
        "destination": str(predictions[0]["des"])[:100],
        "times": times,
        "route": str(predictions[0]["rt"])[:10],
        "route_color": full_route["color"],
    }

def get_bus_route(route, api_key):
    routes = get_bus_routes(api_key)

    route_map = {}

    for rt in routes:
        route_map[rt["route"]] = rt

    return route_map.get(route)

def build_route(route):
    color = str(route["rtclr"])
    if color.startswith("#"):
        color = color[1:]
    if len(color) != 6:
        color = "666666"
    for c in color.elems():
        if c not in "0123456789abcdefABCDEF":
            color = "666666"
            break
    return {
        "route": str(route["rt"])[:10],
        "name": str(route["rtnm"])[:100],
        "color": "#" + color,
    }

def get_bus_routes(api_key):
    if not api_key:
        return None

    response = http.get(
        API_BASE + "/getroutes",
        params = {
            "key": api_key,
            "format": "json",
        },
    )
    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return []
    body = response.json().get("bustime-response", {})
    if type(body) != "dict" or type(body.get("routes")) != "list":
        return []
    data = body["routes"][:500]
    routes = [build_route(route) for route in data if type(route) == "dict" and "rt" in route and "rtnm" in route and "rtclr" in route]
    return routes

def get_bus_route_directions(route, api_key):
    if not api_key:
        return None

    response = http.get(
        API_BASE + "/getdirections",
        params = {
            "rt": route,
            "key": api_key,
            "format": "json",
        },
    )
    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return []
    data = response.json().get("bustime-response", {})
    return data.get("directions", []) if type(data) == "dict" and type(data.get("directions")) == "list" else []

######################
# Render methods
######################
def render_no_arrival(full_route):
    background_color = render.Box(
        width = 22,
        height = 11,
        color = full_route["color"],
    )

    stack = render.Stack(
        children = [
            background_color,
            render.Box(
                color = "#0000",
                width = 22,
                height = 11,
                child = render.Text(full_route["route"], color = "#000", font = "CG-pixel-4x5-mono"),
            ),
        ],
    )

    column = render.Marquee(
        width = 40,
        child = render.Text("No service scheduled.", color = "#666", height = 7),
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )

def render_arrival(arrival):
    background_color = render.Box(
        width = 22,
        height = 11,
        color = arrival["route_color"],
    )
    destination_text = render.Marquee(
        width = 40,
        child = render.Text(arrival["destination"], font = "CG-pixel-3x5-mono", height = 7),
    )

    arrival_in_text = render.Marquee(
        width = 40,
        child = render.Text(", ".join(arrival["times"]), color = "#f3ab3f", font = "tb-8"),
    )

    stack = render.Stack(
        children = [
            background_color,
            render.Box(
                color = "#0000",
                width = 22,
                height = 11,
                child = render.Text(arrival["route"], color = "#000", font = "CG-pixel-4x5-mono"),
            ),
        ],
    )

    column = render.Column(
        children = [
            destination_text,
            arrival_in_text,
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )
