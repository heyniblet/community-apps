"""
Applet: Flight Radar Feed
Summary: View FR24 Radar Feed
Description: View the flights tracked by a radar on Flightradar24.
Author: kinson
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/plane.png", PLANE_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PLANE_ICON = PLANE_ICON_ASSET.readall()

API_URL = "https://data-cloud.flightradar24.com/zones/fcgi/feed.js"
MAX_FLIGHTS = 50
MAX_RADARS = 5
MAX_RESPONSE_BYTES = 2 * 1024 * 1024

def clean_text(value, maximum = 24):
    if type(value) not in ("string", "int", "float"):
        return ""
    return " ".join(str(value).split())[:maximum]

def valid_radar(value):
    if not value or len(value) > 32:
        return False
    for char in value.codepoints():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return False
    return True

def get_data(url, radar_code):
    res = http.get(url, params = {"radar": radar_code}, ttl_seconds = 60)
    body = res.body()
    if res.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return []
    json_res = json.decode(body, None)
    if type(json_res) != "dict":
        return []

    flight_strings = []

    for _id, flight in json_res.items():
        if len(flight_strings) >= MAX_FLIGHTS or type(flight) != "list" or len(flight) <= 16:
            continue

        callsign = clean_text(flight[16])
        origin = clean_text(flight[11], 8)
        destination = clean_text(flight[12], 8)

        has_route = origin != "" and destination != ""
        has_callsign = callsign != ""
        if has_route or has_callsign:
            flight_strings.append({
                "origin": origin or "???",
                "destination": destination or "???",
                "model": clean_text(flight[8]),
                "registration": clean_text(flight[9]),
                "speed": clean_text(flight[5], 8),
                "altitude": clean_text(flight[4], 8),
                "callsign": callsign or "???",
            })

    return flight_strings

def render_flight_info_screen(flight, radar, show_radar):
    origin = flight.get("origin", "???")
    destination = flight.get("destination", "???")
    model = flight.get("model", "???")
    registration = flight.get("registration", "???")
    speed = str(flight.get("speed", 0))
    alt = str(flight.get("altitude", 0))
    callsign = flight.get("callsign", "???")

    callsign_row = [
        render.Padding(
            pad = (0, 1, 0, 1),
            child = render.Text(content = callsign, font = "tom-thumb", color = "#E00"),
        ),
    ]

    if show_radar:
        callsign_row.append(
            render.Padding(
                child = render.Text(
                    content = radar,
                    font = "CG-pixel-3x5-mono",
                    color = "#811",
                ),
                pad = (0, 0, 0, 0),
            ),
        )

    return render.Padding(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = callsign_row,
                ),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 0, 4, 0),
                            child = render.Image(src = PLANE_ICON),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(
                                content = origin + " -> " + destination,
                                color = "#1111ee",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = model, font = "tom-thumb"),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = registration, font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = speed, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "kts", font = "tom-thumb"),
                                ),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = alt, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "ft", font = "tom-thumb"),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
        pad = (1, 1, 0, 1),
    )

def render_list_of_flights(flights, radar, show_radar):
    if len(flights) > 0:
        return [render_flight_info_screen(f, radar, show_radar) for f in flights]
    else:
        return []

def main(config):
    radars = config.str("radars")

    if not radars:
        return []

    radar_array = []
    for raw_radar in radars.split(",")[:MAX_RADARS]:
        radar = raw_radar.strip()
        if valid_radar(radar):
            radar_array.append(radar)

    if not radar_array:
        return []
    rendered_flights = []

    for radar in radar_array:
        flight_data = get_data(API_URL, radar)
        rendered_screens = render_list_of_flights(
            flight_data,
            radar,
            len(radar_array) > 1,
        )
        rendered_flights.extend(rendered_screens)

    if len(rendered_flights) == 0:
        return []

    return render.Root(
        delay = 3500,
        show_full_animation = True,
        child = render.Animation(children = rendered_flights),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "radars",
                name = "Radar IDs (e.g. T-KSFO10)",
                desc = "Separate multiple with a comma",
                icon = "satelliteDish",
            ),
        ],
    )
