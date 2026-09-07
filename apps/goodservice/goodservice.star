"""
Applet: Subway Now
Summary: Subway Now - NYC Subway
Description: More accurate realtime New York City Subway arrival times for a selected station, as seen on Subway Now app. Shows actual train destinations including overnight and weekend service changes.
Author: blahblahblah-
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/diamond_green.png", DIAMOND_GREEN_ASSET = "file")
load("images/diamond_orange.png", DIAMOND_ORANGE_ASSET = "file")
load("images/diamond_purple.png", DIAMOND_PURPLE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_STOP_ID = "M16"
DEFAULT_DIRECTION = "both"
DEFAULT_TRAVEL_TIME = '{"display": "0", "value": "0", "text": "0"}'
SUBWAY_NOW_STOPS_URL_BASE = "https://api.subwaynow.app/stops/"
SUBWAY_NOW_ROUTES_URL = "https://api.subwaynow.app/routes/"

DISPLAY_ORDER_ETA = "eta"
DISPLAY_ORDER_ALPHABETICAL = "alphabetical"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_TRIPS = 100

NAME_OVERRIDE = {
    "Grand Central-42 St": "Grand Cntrl",
    "Times Sq-42 St": "Times Sq",
    "Coney Island-Stillwell Av": "Coney Is",
    "South Ferry": "S Ferry",
    "Mets-Willets Point": "Willets Pt",
}

STREET_ABBREVIATIONS = [
    "St",
    "Av",
    "Sq",
    "Blvd",
    "Rd",
    "Yards",
]

ABBREVIATIONS = {
    "World Trade Center": "WTC",
    "Center": "Ctr",
    "Metropolitan": "Metrop",
    "Blvd": "Bl",
    "Park": "Pk",
    "Beach": "Bch",
    "Rockaway": "Rckwy",
    "Channel": "Chnl",
    "Green": "Grn",
    "Broadway": "Bway",
    "Queensboro": "Q Boro",
    "Plaza": "Plz",
    "Whitehall": "Whthall",
}

DIAMONDS = {
    "#00933c": DIAMOND_GREEN_ASSET.readall(),
    "#b933ad": DIAMOND_PURPLE_ASSET.readall(),
    "#ff6319": DIAMOND_ORANGE_ASSET.readall(),
}

def main(config):
    stop_id = config.get("stop_id", DEFAULT_STOP_ID)
    if not valid_stop_id(stop_id):
        return error("Invalid subway stop")
    travel_time_min = travel_minutes(config.get("travel_time", DEFAULT_TRAVEL_TIME))
    if travel_time_min == None:
        return error("Invalid travel time")
    direction = config.get("direction", DEFAULT_DIRECTION)
    directions = ["north", "south"] if direction == "both" else [direction] if direction in ["north", "south"] else []
    if not directions:
        return error("Invalid direction")
    ordering = config.get("order_by", DISPLAY_ORDER_ETA)
    ordering = ordering if ordering in [DISPLAY_ORDER_ETA, DISPLAY_ORDER_ALPHABETICAL] else DISPLAY_ORDER_ETA
    third_threshold = config.get("third_time", "0")
    third_threshold = int(third_threshold) if type(third_threshold) == "string" and third_threshold in ["0", "3", "5", "7", "10", "1000"] else 0
    include_lines = config.get("include_lines", "")
    if type(include_lines) != "string" or len(include_lines) > 200:
        return error("Invalid line filter")
    included = [line.strip().upper() for line in include_lines.split(",")[:20] if line.strip()]

    routes = fetch_json(SUBWAY_NOW_ROUTES_URL)
    stop = fetch_json(SUBWAY_NOW_STOPS_URL_BASE + stop_id + "?agent=tidbyt")
    stops = fetch_json(SUBWAY_NOW_STOPS_URL_BASE)
    if type(routes) != "dict" or type(routes.get("routes")) != "dict" or type(stop) != "dict" or type(stops) != "dict":
        return error("Subway Now unavailable")
    stop_names = {}
    for item in stops.get("stops", [])[:600]:
        if type(item) == "dict" and type(item.get("id")) == "string" and type(item.get("name")) == "string":
            stop_names[item["id"]] = condense_name(item["name"][:100])

    now = time.now().unix
    minimum = now + travel_time_min * 60
    blocks = []
    upcoming = stop.get("upcoming_trips", {})
    for direction in directions:
        groups = group_trips(upcoming.get(direction, []) if type(upcoming) == "dict" else [], minimum)
        if ordering == DISPLAY_ORDER_ALPHABETICAL:
            groups = sorted(groups, key = lambda item: route_name(routes["routes"], item["route_id"]))
        for group in groups:
            selected_route = routes["routes"].get(group["route_id"])
            if type(selected_route) != "dict":
                continue
            name = selected_route.get("name")
            if type(name) != "string" or not name or len(name) > 16:
                continue
            route_label = name.upper()
            if included and route_label not in included:
                continue
            destination = stop_names.get(group["destination_stop"], group["destination_stop"][:20])
            route_color = valid_color(selected_route.get("color"), "#666666")
            text_color = valid_color(selected_route.get("text_color"), "#ffffff")
            if blocks:
                blocks.append(render.Box(width = 64, height = 1, color = "#aaa" if direction == "south" else "#333"))
            blocks.append(render.Padding(
                pad = (0, 0, 0, 1),
                child = render.Row(
                    cross_align = "center",
                    children = [
                        render.Padding(pad = (1, 0, 1, 0), child = route_bullet(name, route_color, text_color)),
                        render.Column(children = [
                            render.Text(destination[:24]),
                            render.Text(content = eta_text(group, now, third_threshold), font = "tom-thumb", color = "#f2711c"),
                        ]),
                    ],
                ),
            ))

    if len(blocks) == 0:
        return []

    return render.Root(
        child = render.Marquee(
            height = 32,
            offset_start = 16,
            offset_end = 16,
            scroll_direction = "vertical",
            child = render.Column(
                children = blocks,
            ),
        ),
        max_age = 60,
    )

def fetch_json(url):
    response = http.get(url, ttl_seconds = 30)
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return None
    return json.decode(body, None)

def valid_stop_id(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 12 and all([char.isalnum() or char in "-_" for char in value.elems()])

def travel_minutes(value):
    decoded = json.decode(value, {}) if type(value) == "string" else {}
    raw = decoded.get("value") if type(decoded) == "dict" else value
    raw = value if type(raw) != "string" and type(value) == "string" else raw
    if type(raw) != "string" or not raw.isdigit():
        return None
    minutes = int(raw)
    return minutes if minutes >= 0 and minutes <= 60 else None

def group_trips(trips, minimum):
    groups = []
    if type(trips) != "list":
        return groups
    for trip in trips[:MAX_TRIPS]:
        if type(trip) != "dict":
            continue
        route_id = trip.get("route_id")
        destination = trip.get("destination_stop")
        arrival = trip.get("estimated_current_stop_arrival_time")
        delayed = trip.get("is_delayed") == True
        if not valid_stop_id(route_id) or not valid_stop_id(destination) or type(arrival) != "int" or arrival < minimum or arrival > minimum + 6 * 3600:
            continue
        match = None
        for group in groups:
            if group["route_id"] == route_id and group["destination_stop"] == destination:
                match = group
                break
        if match == None:
            match = {"route_id": route_id, "destination_stop": destination, "times": [], "delayed": []}
            groups.append(match)
        if len(match["times"]) < 3:
            match["times"].append(arrival)
            match["delayed"].append(delayed)
    return groups

def route_name(routes, route_id):
    route = routes.get(route_id)
    return route.get("name", route_id) if type(route) == "dict" else route_id

def eta_text(group, now, third_threshold):
    labels = []
    limit = 2
    first = int((group["times"][0] - now) / 60)
    second = int((group["times"][1] - now) / 60) if len(group["times"]) > 1 else None
    if len(group["times"]) > 2 and second != None and second - first < third_threshold:
        limit = 3
    for i in range(min(limit, len(group["times"]))):
        eta = int((group["times"][i] - now) / 60)
        labels.append("delay" if group["delayed"][i] else "due" if eta < 1 else str(eta))
    suffix = " min" if len(labels) == 1 and labels[0] not in ["due", "delay"] else ""
    return ", ".join(labels) + suffix

def valid_color(value, fallback):
    if type(value) == "string" and len(value) == 7 and value.startswith("#") and all([char.lower() in "0123456789abcdef" for char in value[1:].elems()]):
        return value
    return fallback

def route_bullet(name, route_color, text_color):
    if len(name) > 1 and name[1] == "X" and DIAMONDS.get(route_color):
        return render.Stack(children = [
            render.Image(src = DIAMONDS[route_color]),
            render.Padding(pad = (4, 2, 0, 0), child = render.Text(content = name[0], color = text_color, height = 8)),
        ])
    return render.Circle(
        color = route_color,
        diameter = 11,
        child = render.Box(padding = 1, height = 11, width = 11, child = render.Text(content = name[0] if name != "SIR" else "SI", color = text_color, height = 8)),
    )

def error(message):
    return render.Root(child = render.WrappedText(content = message, width = 62, align = "center"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "Station",
                desc = "NYC Subway stop ID, such as M16 for Marcy Av.",
                icon = "trainSubway",
                default = "M16",
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Direction(s) of train depatures to be included",
                icon = "compass",
                default = "both",
                options = [
                    schema.Option(
                        display = "Both",
                        value = "both",
                    ),
                    schema.Option(
                        display = "Northbound",
                        value = "north",
                    ),
                    schema.Option(
                        display = "Southbound",
                        value = "south",
                    ),
                ],
            ),
            schema.Text(
                id = "travel_time",
                name = "Travel Time to Station",
                desc = "Whole minutes from 0 to 60; earlier trains are hidden.",
                icon = "hourglass",
                default = "0",
            ),
            schema.Dropdown(
                id = "third_time",
                name = "Show Third Time Threshold",
                desc = "Minimum difference in first and second arrival times to show 3rd arrival time.",
                icon = "hourglass",
                default = "0",
                options = [
                    schema.Option(
                        display = "Never",
                        value = "0",
                    ),
                    schema.Option(
                        display = "3 mins",
                        value = "3",
                    ),
                    schema.Option(
                        display = "5 mins",
                        value = "5",
                    ),
                    schema.Option(
                        display = "7 mins",
                        value = "7",
                    ),
                    schema.Option(
                        display = "10 mins",
                        value = "10",
                    ),
                    schema.Option(
                        display = "Always",
                        value = "1000",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "order_by",
                name = "Order By",
                desc = "The display order of train routes",
                icon = "sort",
                default = DISPLAY_ORDER_ETA,
                options = [
                    schema.Option(
                        display = "Next Train ETA",
                        value = DISPLAY_ORDER_ETA,
                    ),
                    schema.Option(
                        display = "Alphabetical Order",
                        value = DISPLAY_ORDER_ALPHABETICAL,
                    ),
                ],
            ),
            schema.Text(
                id = "include_lines",
                name = "Filter Lines",
                desc = "Only show certain lines (comma separated)",
                icon = "route",
                default = "",
            ),
        ],
    )

def condense_name(name):
    name = name.replace(" - ", "-")
    if len(name) < 11:
        return name

    if NAME_OVERRIDE.get(name):
        return NAME_OVERRIDE[name]

    if "-" in name:
        modified_name = name
        for abrv in STREET_ABBREVIATIONS:
            abbreviated_array = modified_name.split(abrv)
            modified_name = ""
            for a in abbreviated_array:
                modified_name = modified_name + a.strip()
        modified_name = modified_name.strip()
        if len(modified_name) < 11:
            return modified_name

    for key in ABBREVIATIONS:
        name = name.replace(key, ABBREVIATIONS[key])
    split_name = name.split("-")
    if len(split_name) > 1 and ("St" in split_name[1] or "Av" in split_name[1] or "Sq" in split_name[1] or "Bl" in split_name[1]) and (split_name[0] != "Far Rckwy"):
        if "Sts" in split_name[1]:
            return split_name[0] + " St"
        if "Avs" in split_name[1]:
            return split_name[0] + " Av"
        return split_name[1]
    return split_name[0]
