"""
Applet: LA Metro Stop
Summary: LA metro times for stop
Description: Get departure times for LA metro train stop.
Author: connorwashere
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_STOP_ID = "METRRCA:2806"
DEFAULT_LINE_NAME = "A"
SHORTENED_NAMES = {
    "Union Station": "Union",
    "APU / Citrus College": "Azuza",
}

def main(config):
    transit_stop_id = config.get("stop_id", DEFAULT_STOP_ID)
    transit_line = config.get("metro_line", DEFAULT_LINE_NAME)
    api_key = config.get("transit_api_key")
    if not api_key:
        return render.Root(
            child = render.Text("No Transit App API Key provided.", font = "5x8"),
        )
    if not transit_stop_id or len(transit_stop_id) > 40 or any([c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:_-" for c in transit_stop_id.elems()]):
        return render.Root(child = render.Text("Invalid stop ID", font = "5x8"))
    route_info = parse_api_response(get_times(transit_stop_id, api_key))
    if not route_info:
        return render.Root(child = render.Text("No departures", font = "5x8"))
    stop_renders = []
    for stop_name in route_info:
        stop_renders.append(render_stop_info(route_info, stop_name, transit_line))
        stop_renders.append(render.Box(
            height = 1,
            width = 62,
            color = "#fff",
        ))
    stop_renders.pop()
    return render.Root(
        delay = 120,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                main_align = "start",
                cross_align = "center",
                children = stop_renders,
            ),
        ),
    )

def render_stop_info(route_info, stop_name, transit_line):
    display_name = SHORTENED_NAMES.get(stop_name, stop_name)
    return render.Box(
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
                    width = 8,
                    child = render.Text(transit_line, color = "#fff"),
                    color = "0073bd",
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
                            child = render.Text(display_name),
                        ),
                        render.Text(get_displayed_times(route_info[stop_name], 2), font = "5x8", offset = 1, color = "FFB033"),
                    ],
                ),
            ],
        ),
    )

def get_times(stop_id, api_key):
    rep = http.get(
        "https://external.transitapp.com/v3/public/stop_departures",
        params = {
            "global_stop_id": stop_id,
        },
        headers = {
            "apiKey": api_key,
        },
    )
    if rep.status_code != 200:
        return {}
    return rep.json()

def parse_api_response(depts):
    departures_dict = {}
    routes = depts.get("route_departures", [])
    if not routes:
        return departures_dict
    for direction in routes[0].get("itineraries", [])[:4]:
        departures_dict[direction.get("headsign", "Metro")] = [
            int((time.from_timestamp(int(dept_time["departure_time"])) - time.now()).minutes)
            for dept_time in direction.get("schedule_items", [])[:8]
            if not dept_time.get("is_cancelled", False) and dept_time.get("departure_time") != None
        ]
    return departures_dict

def get_displayed_times(times, predictions_max):
    return "%s min" % ",".join([str(t) for t in times[:predictions_max]])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "Global stop ID",
                desc = "Global stop id for metro station in transitapp.",
                icon = "train",
                default = "METRRCA:2806",
            ),
            schema.Text(
                id = "metro_line",
                name = "Metro line letter",
                desc = "The metro stops line name using LA metro letter designations.",
                icon = "l",
                default = "A",
            ),
            schema.Text(
                id = "transit_api_key",
                name = "Transit App API Key",
                desc = "A Transit App API key to access the Transit App API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
