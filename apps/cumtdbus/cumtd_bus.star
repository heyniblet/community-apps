"""
CUMTD Bus Arrivals - Tidbyt App
Enter your address to see buses at nearby stops.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_BASE = "https://developer.mtd.org/api/v2.2/json"
MTD_BLUE = "#1E88E5"

def main(config):
    api_key = config.str("api_key")
    location = config.str("address", "")
    routes_str = config.str("routes", "")

    if not api_key or len(api_key) > 256:
        return render_error("Set API key")

    if not location or len(location) > 2048 or not location.startswith("{"):
        return render_error("Choose location")

    loc = json.decode(location)
    if type(loc) != "dict" or "lat" not in loc or "lng" not in loc:
        return render_error("Choose location")

    lat = float(loc["lat"])
    lon = float(loc["lng"])
    if lat < -90 or lat > 90 or lon < -180 or lon > 180:
        return render_error("Invalid location")

    stops = get_stops_from_location(api_key, lat, lon)

    if not stops:
        return render_error("No stops found")

    # Parse route filter
    route_filter = []
    if routes_str:
        route_filter = [r.strip().upper()[:12] for r in routes_str.split(",")[:20] if r.strip()]

    # Fetch departures for all stops (stops are ordered by distance, closest first)
    # Only keep the first occurrence of each route+direction (from closest stop)
    all_departures = []
    seen_routes = {}  # key: "route+direction", value: stop_name

    for stop in stops:
        departures = fetch_departures(api_key, stop["stop_id"], stop["name"], route_filter)
        for dep in departures:
            route_key = "%s%s" % (dep["route"], dep["direction"])
            if route_key not in seen_routes:
                seen_routes[route_key] = dep["stop_name"]
                all_departures.append(dep)

    # Sort by arrival time
    all_departures = sorted(all_departures, key = lambda d: d["mins"])

    return render.Root(
        delay = 120,  # Slower frame rate for easier reading
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render_header(str(loc.get("description", "Selected location"))[:100]),
                render_bus_list(all_departures[:5]),
            ],
        ),
    )

def render_error(msg):
    """Render error message."""
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                font = "tom-thumb",
                color = "#ff6600",
            ),
        ),
    )

def get_stops_from_location(api_key, lat, lon):
    """Find nearby CUMTD stops for a selected location."""
    stops_resp = http.get(
        API_BASE + "/getstopsbylatlon",
        params = {"key": api_key, "lat": str(lat), "lon": str(lon), "count": "5"},
    )

    if stops_resp.status_code != 200 or len(stops_resp.body()) > 512 * 1024:
        return []

    stops_data = stops_resp.json()
    if type(stops_data) != "dict" or type(stops_data.get("stops")) != "list":
        return []
    stops = []
    for stop in stops_data.get("stops", [])[:5]:
        if type(stop) != "dict" or not stop.get("stop_id") or not stop.get("stop_name"):
            continue
        stops.append({
            "stop_id": str(stop["stop_id"])[:40],
            "name": shorten_name(str(stop["stop_name"])[:100]),
        })

    return stops

def shorten_name(name):
    """Shorten stop name for display."""
    name = name.replace("Transit Plaza", "Plaza")
    name = name.replace("Illinois Street Residence Hall", "ISR")
    name = name.replace("Krannert Center", "Krannert")
    name = name.replace("Chemical and Life Sciences", "Chem&Life")
    name = name.replace(" and ", " & ")
    name = name.replace("Street", "St")
    name = name.replace("Avenue", "Ave")
    name = name.replace("Drive", "Dr")
    name = name.replace("Road", "Rd")

    # Remove extra spaces
    parts = [p for p in name.split(" ") if p]
    name = " ".join(parts)

    return name

def safe_color(value, fallback):
    value = str(value)
    if value.startswith("#"):
        value = value[1:]
    if len(value) != 6:
        return fallback
    for c in value.elems():
        if c not in "0123456789abcdefABCDEF":
            return fallback
    return "#" + value

def fetch_departures(api_key, stop_id, stop_name, route_filter):
    """Fetch departures for a single stop."""
    rep = http.get(
        API_BASE + "/getdeparturesbystop",
        params = {"key": api_key, "stop_id": stop_id, "pt": "30", "count": "20"},
    )

    if rep.status_code != 200 or len(rep.body()) > 512 * 1024:
        return []

    data = rep.json()
    if type(data) != "dict" or type(data.get("departures")) != "list":
        return []
    departures = []

    for dep in data.get("departures", [])[:20]:
        if type(dep) != "dict" or type(dep.get("route")) != "dict":
            continue
        route = dep.get("route", {})
        route_color = safe_color(route.get("route_color", "1E88E5"), MTD_BLUE)
        text_color = safe_color(route.get("route_text_color", "FFFFFF"), "#FFFFFF")

        headsign = str(dep.get("headsign", ""))[:100]
        direction = extract_direction(headsign)
        mins_value = str(dep.get("expected_mins", 0))
        if not mins_value:
            continue
        for c in mins_value.elems():
            if c not in "0123456789":
                mins_value = ""
                break
        if not mins_value:
            continue
        mins = int(mins_value)
        if mins < 0 or mins > 999:
            continue

        departures.append({
            "mins": mins,
            "route": str(route.get("route_short_name", "?"))[:8],
            "direction": direction,
            "color": route_color,
            "text_color": text_color,
            "stop_name": stop_name,
        })

    if route_filter:
        departures = [d for d in departures if d["route"].upper() in route_filter]

    return departures

def extract_direction(headsign):
    """Extract direction (N/S/E/W/U/C) from headsign."""

    # Headsigns look like "22N Illini", "2U Red", "21 Raven" (no dir)
    # Direction is right after route number if present
    for i in range(len(headsign)):
        c = headsign[i]
        if c in "NSEWUC" and i > 0 and headsign[i - 1].isdigit():
            # Check next char is space or end (confirms it's direction)
            if i == len(headsign) - 1 or headsign[i + 1] == " ":
                return c
    return ""

def render_header(address):
    """Render header with CUMTD on left, address on right."""

    # Extract just street address (remove city, state, zip)
    street = address.split(",")[0].strip()

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text(
                content = "CUMTD",
                font = "tom-thumb",
                color = MTD_BLUE,
            ),
            render.Marquee(
                width = 38,
                delay = 30,
                child = render.Text(
                    content = street,
                    font = "tom-thumb",
                    color = "#aaa",
                ),
            ),
        ],
    )

def render_bus_row(departure):
    """Render a single bus departure row."""
    mins = departure["mins"]
    if mins == 0:
        time_text = "NOW"
    else:
        time_text = "%dm" % mins

    # Route with direction
    route_text = departure["route"]
    if departure["direction"]:
        route_text = "%s%s" % (departure["route"], departure["direction"])

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Left side: route badge
            render.Box(
                width = 18,
                height = 9,
                color = departure["color"],
                child = render.Text(
                    content = route_text,
                    font = "tom-thumb",
                    color = departure["text_color"],
                ),
            ),
            # Right side: time and stop
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(
                        content = time_text,
                        font = "tom-thumb",
                        color = "#fff",
                    ),
                    render.Box(width = 2, height = 1),
                    render.Marquee(
                        width = 28,
                        delay = 40,
                        child = render.Text(
                            content = departure["stop_name"],
                            font = "tom-thumb",
                            color = "#888",
                        ),
                    ),
                ],
            ),
        ],
    )

def render_bus_list(departures):
    """Render the list of bus departures with vertical scrolling."""
    if not departures:
        return render.Box(
            height = 20,
            child = render.Text(
                content = "No buses soon",
                font = "tom-thumb",
                color = "#666",
            ),
        )

    # Build rows for each departure
    children = []
    for dep in departures:
        children.append(render_bus_row(dep))
        children.append(render.Box(height = 1))

    bus_column = render.Column(
        main_align = "start",
        children = children,
    )

    # Vertical marquee to scroll through all buses
    return render.Marquee(
        height = 25,
        scroll_direction = "vertical",
        offset_start = 0,
        offset_end = 0,
        delay = 50,
        child = bus_column,
    )

def get_schema():
    """Define the configuration schema for the app."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "CUMTD API Key",
                desc = "Get your key at developer.mtd.org",
                icon = "key",
                secret = True,
            ),
            schema.Location(
                id = "address",
                name = "Location",
                desc = "Location used to find nearby CUMTD stops.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "routes",
                name = "Routes (optional)",
                desc = "Show only these routes (e.g., 22,1,13)",
                icon = "route",
                default = "",
            ),
        ],
    )
