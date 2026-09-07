"""
Applet: FlightTracker
Summary: FlightAware API + Tidbyt
Description: Tracks flights via given Flight Number or airport code.
Author: samuelsagarino
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

OUTPUT_FORMATS = ["departures", "arrivals", "flight"]
API_ROOT = "https://aeroapi.flightaware.com/aeroapi"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "displayMode",
                name = "Display Mode",
                desc = "What should be displayed?",
                icon = "list",
                default = "arrivals",
                options = [schema.Option(display = value.capitalize(), value = value) for value in OUTPUT_FORMATS],
            ),
            schema.Text(
                id = "airportCode",
                name = "Airport Code",
                desc = "Airport Code to Track",
                icon = "planeArrival",
            ),
            schema.Text(
                id = "flightNumber",
                name = "Flight Number",
                desc = "Flight Number to Track",
                icon = "planeLock",
            ),
            schema.Text(
                id = "apiKey",
                name = "FA API Key",
                desc = "FlightAware AeroAPI key",
                icon = "code",
                secret = True,
            ),
        ],
    )

def main(config):
    api_key = config.get("apiKey")
    if not valid_secret(api_key):
        return message("Add FlightAware API key", "#ff6666")

    mode = str(config.get("displayMode") or "arrivals").lower()
    if mode not in OUTPUT_FORMATS:
        mode = "arrivals"

    if mode == "flight":
        identifier = valid_identifier(config.get("flightNumber"), 16)
        if not identifier:
            return message("Add a flight number", "#ffcc66")
        url = "%s/flights/%s" % (API_ROOT, identifier)
        params = {"max_pages": "1"}
        response_key = "flights"
    else:
        identifier = valid_identifier(config.get("airportCode") or "KATL", 8)
        if not identifier:
            return message("Check airport code", "#ffcc66")
        url = "%s/airports/%s/flights/%s" % (API_ROOT, identifier, mode)
        params = {"type": "Airline", "max_pages": "1"}
        response_key = mode

    response = http.get(url, params = params, headers = {"x-apikey": api_key})
    if response.status_code != 200 or len(response.body()) > 2 * 1024 * 1024:
        return message("FlightAware unavailable (%d)" % response.status_code, "#ff6666")

    payload = json.decode(response.body(), {})
    flights = payload.get(response_key, []) if type(payload) == "dict" else []
    if type(flights) != "list" or not flights or type(flights[0]) != "dict":
        return message("No matching flights", "#ffcc66")

    return render_flight(flights[0])

def render_flight(flight):
    origin = flight.get("origin", {})
    destination = flight.get("destination", {})
    origin = origin if type(origin) == "dict" else {}
    destination = destination if type(destination) == "dict" else {}

    origin_code = safe_text(origin.get("code"), "?")
    destination_code = safe_text(destination.get("code"), "?")
    origin_city = safe_text(origin.get("city"), origin_code)
    destination_city = safe_text(destination.get("city"), destination_code)
    flight_number = safe_text(flight.get("ident"), "Flight")
    aircraft = safe_text(flight.get("aircraft_type"), "?")
    status = safe_text(flight.get("status"), "Status unavailable", 80)
    progress = flight.get("progress_percent", 0)
    progress = int(progress) if type(progress) in ["int", "float"] else 0
    progress = max(1, min(64, progress * 64 // 100))

    departure = display_time(flight.get("actual_off") or flight.get("estimated_off") or flight.get("scheduled_off"))
    arrival = display_time(flight.get("actual_on") or flight.get("estimated_on") or flight.get("scheduled_on"))
    color = status_color(status)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(width = progress, height = 2, color = color),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(children = [render.Text(origin_code), render.Text(departure, font = "tom-thumb")]),
                        render.Text("→", color = "#8CADA7"),
                        render.Column(cross_align = "end", children = [render.Text(destination_code), render.Text(arrival, font = "tom-thumb")]),
                    ],
                ),
                render.Marquee(width = 64, child = render.Text("%s | %s → %s" % (status, origin_city, destination_city), color = color, font = "tom-thumb")),
                render.Marquee(width = 64, child = render.Text("%s | %s" % (flight_number, aircraft), color = "#8CADA7", font = "tom-thumb")),
            ],
        ),
    )

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 2048 and "\r" not in value and "\n" not in value

def valid_identifier(value, maximum):
    if type(value) != "string":
        return None
    value = value.strip().upper()
    if not value or len(value) > maximum or not all([char.isalnum() or char in "-_" for char in value.codepoints()]):
        return None
    return value

def safe_text(value, fallback, maximum = 32):
    return value[:maximum] if type(value) == "string" and value else fallback

def display_time(value):
    if type(value) == "string" and len(value) >= 16 and value[11:13].isdigit() and value[14:16].isdigit():
        return value[11:16]
    return "--:--"

def status_color(status):
    lowered = status.lower()
    if "cancel" in lowered or "divert" in lowered:
        return "#C5283D"
    if "delay" in lowered or "taxi" in lowered:
        return "#FFC857"
    return "#19d172"

def message(text, color):
    return render.Root(child = render.WrappedText(text, color = color))
