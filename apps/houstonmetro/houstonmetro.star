load("http.star", "http")
load("images/metro_icon.png", METRO_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

METRO_ICON = METRO_ICON_ASSET.readall()

DEFAULT_STOP = "Ho414_4620_12308"

ROUTE_INFO_CACHE_TTL = 604800  #1 Week

ARRIVALS_CACHE_KEY = "arrivals"
ARRIVALS_CACHE_TTL = 60  # 1 minute

def main(config):
    stop_id = config.str("station_id", DEFAULT_STOP)
    api_key = config.str("api_key", "")
    time_toggle = "true" if config.bool("time", False) else "false"

    render_elements = []
    if api_key and valid_stop_id(stop_id):
        params = {"subscription-key": api_key}
        endpoint = "https://api.ridemetro.org/data/Stops('" + stop_id + "')"
        stop_response = http.get(endpoint, params = params, ttl_seconds = ROUTE_INFO_CACHE_TTL)
        stop_data = stop_response.json() if stop_response.status_code == 200 else {}
        stops = stop_data.get("value", []) if type(stop_data) == "dict" else []
        stop_name = stops[0].get("Name", "Houston Metro") if len(stops) > 0 and type(stops[0]) == "dict" else "Houston Metro"

        arrivals_response = http.get(endpoint + "/Arrivals", params = params, ttl_seconds = ARRIVALS_CACHE_TTL)
        arrivals_data = arrivals_response.json() if arrivals_response.status_code == 200 else {}
        arrivals = arrivals_data.get("value", []) if type(arrivals_data) == "dict" else []
        arrivals = arrivals[0:4]
        if not arrivals:
            render_elements.append(
                render.Row(
                    children = [
                        render.Box(
                            color = "#0000",
                            child = render.Text("No arrivals", color = "#f3ab3f"),
                        ),
                    ],
                ),
            )
        else:
            for arrival in arrivals:
                if type(arrival) == "dict":
                    route_number = str(arrival.get("RouteName", ""))[0:8]
                    arrival_time = str(arrival.get("LocalArrivalTime", ""))
                    direction = str(arrival.get("DestinationName", "?"))
                    arrival_time = time_string(arrival_time, time_toggle)
                    route_color = "004080"
                    render_element = render.Row(
                        children = [
                            render.Stack(children = [
                                render.Box(
                                    color = "#" + route_color,
                                    width = 30,
                                    height = 10,
                                ),
                                render.Box(
                                    color = "#0000",
                                    width = 30,
                                    height = 10,
                                    child = render.Text(route_number + " " + direction[0:1], color = "#000", font = "CG-pixel-4x5-mono"),
                                ),
                            ]),
                            render.Column(
                                children = [
                                    render.Text(" " + arrival_time, color = "#f3ab3f"),
                                ],
                            ),
                        ],
                        main_align = "center",
                        cross_align = "center",
                    )
                    render_elements.append(render_element)
    else:
        stop_name = "Houston Metro"
        render_elements.append(
            render.Row(
                children = [
                    render.Box(
                        color = "#0000",
                        child = render.Text("Setup required", color = "#f3ab3f"),
                    ),
                ],
            ),
        )

    #Create animation frames of the stop info
    animation_children = []
    if len(render_elements) == 1:
        frame_1 = render.Column(
            children = [
                render_elements[0],
            ],
        )
        for i in range(0, 160):
            animation_children.append(frame_1)
    if len(render_elements) == 2:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        for i in range(0, 160):
            animation_children.append(frame_1)
    if len(render_elements) == 3:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        frame_2 = render.Column(
            children = [
                render_elements[2],
            ],
        )
        for i in range(0, 160):
            if i <= 80:
                animation_children.append(frame_1)
            else:
                animation_children.append(frame_2)
    if len(render_elements) == 4:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        frame_2 = render.Column(
            children = [
                render_elements[2],
                render_elements[3],
            ],
        )
        for i in range(0, 160):
            if i <= 80:
                animation_children.append(frame_1)
            else:
                animation_children.append(frame_2)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(
                            src = METRO_ICON,
                        ),
                        render.Marquee(
                            child =
                                render.Text(
                                    stop_name,
                                    font = "tb-8",
                                    height = 12,
                                ),
                            align = "center",
                            width = 45,
                            offset_start = 5,
                            offset_end = 32,
                        ),
                    ],
                ),
                render.Sequence(
                    children = [
                        render.Animation(
                            children = animation_children,
                        ),
                    ],
                ),
            ],
        ),
    )

def time_string(full_string, time_toggle):
    time_index = full_string.find("T")
    if time_index < 0 or len(full_string) < time_index + 6:
        return "--:--"
    hours = full_string[time_index + 1:len(full_string) - 7]
    minutes = full_string[len(full_string) - 6:len(full_string) - 4]
    if not hours.isdigit() or not minutes.isdigit():
        return "--:--"
    if time_toggle.lower() == "false" and int(hours) > 12:
        hours = int(hours) - 12
    return str(hours) + ":" + minutes

def valid_stop_id(value):
    if not value or len(value) > 64:
        return False
    for ch in value.elems():
        if ch not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
            return False
    return True

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "METRO API key",
                desc = "Your Houston METRO developer subscription key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "station_id",
                name = "Bus/Train Station",
                desc = "METRO stop ID (for example 3527).",
                icon = "train",
                default = DEFAULT_STOP,
            ),
            schema.Toggle(
                id = "time",
                name = "24-hour time",
                desc = "A toggle to display 24-hour time.",
                icon = "clock",
                default = False,
            ),
        ],
    )
