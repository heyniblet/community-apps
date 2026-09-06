"""
Applet: Norway Transit
Summary: Check departures in Norway
Description: Check your favourite stop in real time, anywhre in Norway.
Author: Mats Grosvik
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TRAM_BLUE = "#6fe9ff"
RUTER_RED = "#E60000"
WHITE = "#FFFFFF"
YELLOW = "#f9C66b"
BLACK = "#000000"
DEFAULT_STOP = "NSR:StopPlace:5900"

def parse_stop(raw):
    if type(raw) != "string" or not raw.strip():
        return struct(id = DEFAULT_STOP, display = "Ryen")
    raw = raw.strip()
    if raw.startswith("{"):
        ids = re.findall('"value"\\s*:\\s*"([^"]+)"', raw)
        names = re.findall('"display"\\s*:\\s*"([^"]+)"', raw)
        if len(ids) == 0:
            return None
        return struct(id = ids[0][0], display = names[0][0] if len(names) > 0 else ids[0][0])
    return struct(id = raw, display = raw)

def main(config):
    direction = config.get("directionId", "outbound")
    search = config.get("searchId", '{"display": "Ryen", "value": "NSR:StopPlace:5900"}')
    search_hit = parse_stop(search)
    if search_hit == None or len(re.findall("^NSR:StopPlace:[A-Za-z0-9:_-]+$", search_hit.id)) == 0:
        return render.Root(child = render.Text("Invalid stop ID", color = "#F00"))
    if direction not in ["inbound", "outbound"]:
        direction = "outbound"

    selected_modes = []
    for mode, default in [("air", True), ("bus", True), ("cableway", True), ("water", False), ("funicular", True), ("lift", True), ("rail", True), ("metro", True), ("tram", True), ("coach", True)]:
        if config.bool("show" + mode.capitalize(), default):
            selected_modes.append(mode)

    graphql_query = """\r
    query ($id: String!) {\r
      stopPlace(id: $id) {\r
        name\r
         id\r
    estimatedCalls {\r
      expectedArrivalTime\r
      destinationDisplay {\r
        frontText\r
      }\r
      serviceJourney {\r
        line {\r
          publicCode\r
          transportMode\r
          presentation {\r
            colour\r
          }\r
        }\r
        journeyPattern {\r
          directionType\r
        }\r
      }\r
    }\r
      }\r
    }\r
    """

    graphql_payload = json.encode({"query": graphql_query, "variables": {"id": search_hit.id}})

    headers = {
        "Content-Type": "application/json",
        "ET-Client-Name": "niblet-norway-transit",
    }

    rep = http.post(
        "https://api.entur.io/journey-planner/v3/graphql",
        body = graphql_payload,
        headers = headers,
    )

    if rep.status_code != 200:
        print("ENTUR request failed with status %d" % rep.status_code)
        return render.Root(
            child = render.Box(
                child = render.Text("API Error", color = "#F00"),
            ),
        )

    response_json = rep.json()
    data = response_json.get("data", {}) if type(response_json) == "dict" else {}
    stop_place = data.get("stopPlace") if type(data) == "dict" else None
    stop_place = stop_place if type(stop_place) == "dict" else {}
    estimated_calls = stop_place.get("estimatedCalls", [])
    estimated_calls = estimated_calls if type(estimated_calls) == "list" else []

    filtered_calls = [call for call in estimated_calls if type(call) == "dict" and call.get("serviceJourney", {}).get("journeyPattern", {}).get("directionType") == direction and call.get("serviceJourney", {}).get("line", {}).get("transportMode") in selected_modes]
    fall_back = ""
    first_arrival_time = ""
    first_destination = ""
    first_line_info = ""
    first_color = ""
    first_public_code = ""
    first_transport_mode = ""
    first_countdown = ""
    second_countdown = ""
    second_arrival_time = ""
    second_destination = ""
    second_line_info = ""
    second_color = ""
    second_public_code = ""
    second_transport_mode = ""

    def format_time_difference(diff_seconds):
        if diff_seconds < 30:
            return "Nå"
        if diff_seconds < 90:
            return "1 min"
        if diff_seconds > 7199:
            return "{} hours".format(int(diff_seconds // 3600))
        if diff_seconds > 3599:
            return "{} hour".format(int(diff_seconds // 3600))
        else:
            return "{} min".format(int(diff_seconds // 60))

    def getColor(transport, color):
        if color == "000000":
            return WHITE
        if color:
            return "#" + color if len(color) == 6 else WHITE
        if transport == "tram":
            return TRAM_BLUE
        if transport == "bus":
            return RUTER_RED
        if transport == "metro":
            return YELLOW
        else:
            return WHITE

    now = time.now().in_location("Europe/Oslo")

    if (filtered_calls == []):
        fall_back = "Found no calls @ " + search_hit.display
    elif (len(filtered_calls) == 1):
        first_call = filtered_calls[0]

        first_arrival_time = first_call.get("expectedArrivalTime", "")
        first_destination = first_call.get("destinationDisplay", {}).get("frontText", "")
        first_line_info = first_call.get("serviceJourney", {}).get("line", {})
        first_color = first_line_info.get("presentation", {}).get("colour", "")
        first_public_code = first_line_info.get("publicCode", "")
        first_transport_mode = first_line_info.get("transportMode", "")

        first_arrival_time_obj = time.parse_time(first_arrival_time, location = "Europe/Oslo")
        first_time_difference = (first_arrival_time_obj - now).seconds
        first_countdown = format_time_difference(first_time_difference)
    else:
        first_call = filtered_calls[0]
        second_call = filtered_calls[1]

        first_arrival_time = first_call.get("expectedArrivalTime", "")
        first_destination = first_call.get("destinationDisplay", {}).get("frontText", "")
        first_line_info = first_call.get("serviceJourney", {}).get("line", {})
        first_color = first_line_info.get("presentation", {}).get("colour", "")
        first_public_code = first_line_info.get("publicCode", "")
        first_transport_mode = first_line_info.get("transportMode", "")

        second_arrival_time = second_call.get("expectedArrivalTime", "")
        second_destination = second_call.get("destinationDisplay", {}).get("frontText", "")
        second_line_info = second_call.get("serviceJourney", {}).get("line", {})
        second_color = second_line_info.get("presentation", {}).get("colour", "")
        second_public_code = second_line_info.get("publicCode", "")
        second_transport_mode = second_line_info.get("transportMode", "")

        first_arrival_time_obj = time.parse_time(first_arrival_time, location = "Europe/Oslo")
        second_arrival_time_obj = time.parse_time(second_arrival_time, location = "Europe/Oslo")

        first_time_difference = (first_arrival_time_obj - now).seconds
        second_time_difference = (second_arrival_time_obj - now).seconds

        first_countdown = format_time_difference(first_time_difference)
        second_countdown = format_time_difference(second_time_difference)

    if (fall_back == ""):
        if (len(filtered_calls) == 1):
            return render.Root(
                max_age = 15,
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(first_public_code, color = getColor(first_transport_mode, first_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(first_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(first_countdown, color = YELLOW, font = "tb-8"),
                        ),
                    ],
                ),
            )
        else:
            return render.Root(
                max_age = 15,
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(first_public_code, color = getColor(first_transport_mode, first_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(first_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(first_countdown, color = YELLOW, font = "tb-8"),
                        ),
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(second_public_code, color = getColor(second_transport_mode, second_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(second_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(second_countdown, font = "tb-8", color = YELLOW),
                        ),
                    ],
                ),
            )
    else:
        return render.Root(
            max_age = 15,
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.Padding(
                                        pad = (2, 0, 2, 0),
                                        child = render.WrappedText(content = fall_back, color = WHITE, font = "tb-8"),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    directionOptions = [
        schema.Option(
            display = "Outbound",
            value = "outbound",
        ),
        schema.Option(
            display = "Inbound",
            value = "inbound",
        ),
    ]

    transport_modes = ["metro", "bus", "rail", "tram", "cableway", "water", "funicular", "lift", "air", "coach"]
    transportOptions = []
    for mode in transport_modes:
        option = schema.Toggle(
            id = "show" + mode.capitalize(),
            name = mode.capitalize(),
            desc = "Do you want to display " + mode + " departures?",
            icon = "",
            default = True,
        )
        transportOptions.append(option)
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "searchId",
                name = "Stop place ID",
                desc = "Entur NSR stop ID, for example NSR:StopPlace:5900",
                icon = "bus",
            ),
            schema.Dropdown(
                id = "directionId",
                name = "Direction",
                desc = "Wich direction do you want to display",
                icon = "compass",
                default = directionOptions[0].value,
                options = directionOptions,
            ),
        ] + transportOptions,
    )
