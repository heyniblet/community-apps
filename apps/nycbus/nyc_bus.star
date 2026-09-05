"""
Applet: NYC Bus
Summary: NYC Bus departures
Description: Real time bus departures for your preferred stop.
Author: samandmoore
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

EXAMPLE_STOP_CODE = "550685"
BUSTIME_STOP_TIMES_URL = "https://bustime.mta.info/api/siri/stop-monitoring.json"
BUSTIME_STOP_INFO_URL = "https://bustime.mta.info/api/where/stop/%s.json"
PREVIEW_DATA = [{"line_color": "FAA61A", "line_name": "Q100", "destination_name": "LIMITED LI CITY QUEENS PLZ", "eta_text": "15 min"}, {"line_color": "00AEEF", "line_name": "Q69", "destination_name": "LI CITY QUEENS PLZ via DITMARS BL via 21 ST", "eta_text": "45 min"}]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "MTA BusTime API Key",
                desc = "Your MTA BusTime API key. See https://bustime.mta.info/wiki/Developers/Index for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "stop_code",
                name = "Bus Stop",
                desc = "MTA BusTime stop code, for example 550685.",
                icon = "bus",
                default = EXAMPLE_STOP_CODE,
            ),
        ],
    )

def main(config):
    api_key = config.str("api_key", "")
    widgetMode = config.bool("$widget")
    stop_code = parse_stop_code(config.str("stop_code", EXAMPLE_STOP_CODE))

    if api_key:
        journeys = get_journeys(api_key, stop_code)
    else:
        journeys = PREVIEW_DATA

    if journeys == None or len(journeys) == 0:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("No buses found"),
                    ),
                ],
            ),
        )

    if len(journeys) == 1:
        return render.Root(
            child = render.Column(
                expanded = True,
                children = [
                    build_row(journeys[0], widgetMode),
                ],
            ),
        )

    return render.Root(
        delay = 75,
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                build_row(journeys[0], widgetMode),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                build_row(journeys[1], widgetMode),
            ],
        ),
    )

def parse_stop_code(value):
    value = value.strip()
    if value.startswith("{"):
        decoded = json.decode(value)
        value = decoded.get("value", "") if type(decoded) == "dict" else ""
    value = value.strip() if type(value) == "string" else ""
    if not value or len(value) > 32 or not all([char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for char in value.codepoints()]):
        return EXAMPLE_STOP_CODE
    return value

def build_row(journey, widgetMode = False):
    # Only match names of bus lines that we know won't fit
    multi_line = re.compile("([A-Za-z]+)([0-9]+)([\\/ -])([A-Za-z0-9]+)")
    match = multi_line.match(journey["line_name"])
    if len(journey["line_name"]) > 4 and len(match):
        _, borough, first, sep, second = match[0]

        # Lines like "M55/56" should translate to -> M55, M56
        if sep in ("\\", "/"):
            parts = [borough + first, borough + second]
        elif sep == "-":
            # Lines like "Bx41-SBS"
            parts = journey["line_name"].split("-")
        else:
            # Lines like "M44 Ltd"
            parts = journey["line_name"].split(sep)

        # Add 20 frames for each part, * 75ms root delay = 1.5 seconds each
        anim = []
        for part in parts:
            anim.extend(
                [render.Text(part, color = "#000", font = "CG-pixel-4x5-mono")] * 20,
            )

        line_name = render.Animation(children = anim)
    else:
        line_name = render.Text(journey["line_name"], color = "#000", font = "CG-pixel-4x5-mono")

    destination = render.Text(
        journey["destination_name"],
        font = "Dina_r400-6",
        offset = -2,
        height = 7,
    )
    if widgetMode:
        destination = render.Box(
            width = 36,
            height = 7,
            child = render.Row(
                expanded = True,
                main_align = "start",
                children = [destination],
            ),
        )
    else:
        destination = render.Marquee(
            width = 36,
            child = destination,
        )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(children = [
                render.Box(
                    color = "#%s" % journey["line_color"],
                    width = 22,
                    height = 11,
                ),
                render.Box(
                    color = "#0000",
                    width = 22,
                    height = 11,
                    child = line_name,
                ),
            ]),
            render.Column(
                children = [
                    destination,
                    render.Text(journey["eta_text"], color = "#f3ab3f"),
                ],
            ),
        ],
    )

def get_journeys(api_key, stop_code):
    rep = http.get(
        BUSTIME_STOP_TIMES_URL,
        params = {
            "version": "2",
            "key": api_key,
            "MonitoringRef": stop_code,
        },
        ttl_seconds = 30,
    )
    if rep.status_code != 200:
        return []

    body = rep.body()
    if not body or len(body) > 1048576:
        return []
    payload = json.decode(body)
    siri = payload.get("Siri", {}) if type(payload) == "dict" else {}
    service = siri.get("ServiceDelivery", {}) if type(siri) == "dict" else {}
    deliveries = service.get("StopMonitoringDelivery", []) if type(service) == "dict" else []
    delivery = deliveries[0] if type(deliveries) == "list" and deliveries and type(deliveries[0]) == "dict" else {}
    visits = delivery.get("MonitoredStopVisit", []) if type(delivery) == "dict" else []
    visits = visits if type(visits) == "list" else []
    result = []
    for visit in visits[:2]:
        raw = visit.get("MonitoredVehicleJourney", {}) if type(visit) == "dict" else {}
        journey = build_journey(raw, api_key)
        if journey:
            result.append(journey)
    return result

def build_journey(raw_journey, api_key):
    if type(raw_journey) != "dict":
        return None
    call = raw_journey.get("MonitoredCall", {})
    line_ref = raw_journey.get("LineRef", "")
    stop_id = call.get("StopPointRef", "") if type(call) == "dict" else ""
    if not line_ref or not stop_id:
        return None
    line_info = get_line_info(stop_id, line_ref, api_key)
    line_color = line_info["color"]
    line_names = raw_journey.get("PublishedLineName", [])
    destination_names = raw_journey.get("DestinationName", [])
    eta = call.get("ExpectedArrivalTime", "")
    if type(line_names) != "list" or not line_names or type(destination_names) != "list" or not destination_names or not eta:
        return None
    line_name = str(line_names[0])[:20]
    destination_name = str(destination_names[0])[:120]
    now = time.now().in_location("America/New_York")
    eta_time = time.parse_time(eta)
    diff = eta_time - now
    diff_minutes = int(diff.minutes)
    eta_text = "%d min" % diff_minutes if diff_minutes > 0 else "now"
    return {
        "line_color": line_color,
        "line_name": line_name,
        "destination_name": destination_name,
        "eta_text": eta_text,
    }

def get_line_info(stop_id, line_ref, api_key):
    res = http.get(
        BUSTIME_STOP_INFO_URL % stop_id,
        params = {
            "key": api_key,
        },
        ttl_seconds = 3600,
    )
    if res.status_code != 200:
        return {"color": "666666"}

    body = res.body()
    if not body or len(body) > 1048576:
        return {"color": "666666"}
    payload = json.decode(body)
    data = payload.get("data", {}) if type(payload) == "dict" else {}
    routes = data.get("routes", []) if type(data) == "dict" else []
    matching = [route for route in routes if type(route) == "dict" and route.get("id") == line_ref]
    color = matching[0].get("color", "666666") if matching else "666666"
    return {"color": color if type(color) == "string" else "666666"}
