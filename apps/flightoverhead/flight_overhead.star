"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs or OpenSky to find the flight overhead a location.
Author: Kyle Bolstad
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PROVIDERS = {
    "airlabs": {
        "name": "AirLabs",
        "url": "https://airlabs.co/api/v9",
        "display": True,
    },
    "hexdb": {
        "name": "HexDB",
        "url": "https://hexdb.io/api/v1",
        "display": False,
    },
    "opensky": {
        "name": "OpenSky",
        "url": "https://opensky-network.org/api",
        "display": True,
    },
}
OPENSKY_TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"

DEFAULT_AIRLABS_API_KEY = ""
DEFAULT_IGNORE = ""
DEFAULT_LIMIT = 1
DEFAULT_LOCATION = json.encode({
    "lat": "40.6969512",
    "lng": "-73.9538453",
    "description": "Brooklyn, NY, USA",
    "locality": "Tidbyt",
    "place_id": "ChIJr3Hjqu5bwokRmeukysQhFCU",
    "timezone": "America/New_York",
})
DEFAULT_OPENSKY_USERNAME = ""
DEFAULT_OPENSKY_PASSWORD = ""
DEFAULT_PRINT_LOG = False
DEFAULT_PROVIDER = "opensky"
DEFAULT_PROVIDER_BBOX = ""
DEFAULT_PROVIDER_TTL_SECONDS = 60
DEFAULT_RADIUS = 1
DEFAULT_RETURN_MESSAGE_ON_EMPTY = ""
DEFAULT_SHOW_ROUTE = True

KN_RATIO = 1.94
KM_RATIO = 0.54
M_RATIO = 3.28

MAX_AGE = 300
MAX_WIDTH_CHARACTERS = 16
MAX_LIMIT = 5
MAX_RADIUS = 10

def main(config):
    provider = config.get("provider", DEFAULT_PROVIDER)
    if provider not in ["airlabs", "opensky"]:
        provider = DEFAULT_PROVIDER

    airlabs_api_key = config.get("airlabs_api_key", DEFAULT_AIRLABS_API_KEY)
    opensky_username = config.get("opensky_username", DEFAULT_OPENSKY_USERNAME)
    opensky_password = config.get("opensky_password", DEFAULT_OPENSKY_PASSWORD)

    location = json.decode(config.get("location", DEFAULT_LOCATION), {})
    if type(location) != "dict":
        location = {}

    radius = DEFAULT_RADIUS
    if config.get("radius") and re.match("^[0-9]+$", config.get("radius")):
        radius = config.get("radius")
    radius = int(radius)
    radius = max(1, min(MAX_RADIUS, radius))

    provider_ttl_seconds = DEFAULT_PROVIDER_TTL_SECONDS
    if config.get("provider_ttl_seconds") and re.match("^[0-9]+$", config.get("provider_ttl_seconds")):
        provider_ttl_seconds = config.get("provider_ttl_seconds")
    provider_ttl_seconds = int(provider_ttl_seconds)
    provider_ttl_seconds = max(30, min(300, provider_ttl_seconds))

    return_message_on_empty = str(config.get("return_message_on_empty", DEFAULT_RETURN_MESSAGE_ON_EMPTY))[:120]

    ignore = str(config.get("ignore", DEFAULT_IGNORE))[:256]

    show_route = config.bool("show_route", DEFAULT_SHOW_ROUTE)

    limit = DEFAULT_LIMIT
    if config.get("limit") and re.match("^[0-9]+$", config.get("limit")):
        limit = config.get("limit")
    limit = int(limit)
    limit = max(1, min(MAX_LIMIT, limit))

    flights = []

    def check_response_headers(provider, response, ttl_seconds):
        if response.headers.get("Tidbyt-Cache-Status") == "HIT":
            print_log("displaying cached data for %s" % humanize.plural(ttl_seconds, "second"))

        else:
            print_log("calling %s api" % provider)

    def validate_json(response):
        if response.status_code != 200 or len(response.body()) > 2 * 1024 * 1024:
            return {}
        return json.decode(response.body(), {})

    def empty_message():
        if return_message_on_empty:
            print_log("Returning empty message: %s" % return_message_on_empty)

            return render.Root(
                child = render.Box(
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText("%s" % return_message_on_empty),
                        ],
                    ),
                ),
            )

        return []

    def get_aircraft_info(aircraft):
        aircraft_type = ""
        _owners = ""
        owners = ""

        if valid_code(aircraft):
            aircraft_response_url = "%s/aircraft/%s" % (PROVIDERS["hexdb"]["url"], aircraft)
            aircraft_response = http.get(aircraft_response_url, ttl_seconds = provider_ttl_seconds)
            check_response_headers("hexdb", aircraft_response, provider_ttl_seconds)
            aircraft_json = validate_json(aircraft_response)

            if type(aircraft_json) == "dict" and type(aircraft_json.get("ICAOTypeCode")) == "string":
                aircraft_type = aircraft_json.get("ICAOTypeCode")
                _owners = aircraft_json.get("RegisteredOwners")

            if type(_owners) == "string" and _owners:
                if len(_owners) < MAX_WIDTH_CHARACTERS:
                    owners = _owners
                else:
                    owners = _owners[0:MAX_WIDTH_CHARACTERS]

        return {"owners": owners, "type": aircraft_type}

    def is_flying(flight_info):
        return type(flight_info.get("altitude")) in ["int", "float"] and flight_info.get("altitude", 0) > 0

    def should_ignore(flight_info):
        return ignore and type(flight_info.get("callsign")) == "string" and flight_info.get("callsign") in ignore

    def print_log(statement):
        if config.bool("print_log", DEFAULT_PRINT_LOG):
            print(statement)

    def _render(provider, response):
        child = ""
        children = []

        flights_index = 0

        if type(response) != "list":
            return empty_message()
        response = response[:200]

        print_log("found %s" % (humanize.plural(len(response), "flight")))

        for flight in response:
            flight_info = {}

            if flights_index < limit:
                if provider == "airlabs":
                    if type(flight) != "dict" or type(flight.get("alt")) not in ["int", "float"] or type(flight.get("speed")) not in ["int", "float"]:
                        continue
                    flight_info["hex"] = flight.get("hex")
                    flight_info["altitude"] = flight.get("alt") * M_RATIO
                    flight_info["callsign"] = str(flight.get("reg_number") or "")[:16]

                    if is_flying(flight_info) and not should_ignore(flight_info):
                        flight_info["plane"] = flight_info.get("callsign") or "Aircraft"
                        flight_info["location"] = "%dkt %dft" % (flight.get("speed") * KM_RATIO, flight_info.get("altitude"))
                        flight_info["aircraft_info"] = get_aircraft_info(flight_info.get("hex"))
                        flight_info["owners"] = flight_info.get("aircraft_info").get("owners")

                        if flight.get("flight_number"):
                            flight_info["plane"] = "%s %s" % (str(flight.get("airline_iata") or flight.get("airline_icao") or "")[:4], str(flight.get("flight_number"))[:8])

                        if valid_code(flight.get("aircraft_icao")):
                            flight_info["plane"] += " (%s)" % flight.get("aircraft_icao")

                        if show_route:
                            departure = str(flight.get("dep_iata") or "")[:8]
                            arrival = str(flight.get("arr_iata") or "")[:8]
                            if departure or arrival:
                                flight_info["route"] = "%s - %s" % (departure or "?", arrival or "?")

                if provider == "opensky":
                    if type(flight) != "list" or len(flight) < 10:
                        continue
                    flight_info["icao24"] = flight[0]
                    flight_info["altitude"] = (flight[7] or 0) * M_RATIO if type(flight[7]) in ["int", "float"] else 0
                    flight_info["callsign"] = re.sub("\\s", "", flight[1])[:16] if type(flight[1]) == "string" else ""

                    if is_flying(flight_info) and not should_ignore(flight_info):
                        flight_info["plane"] = flight_info.get("callsign")
                        speed = flight[9] if type(flight[9]) in ["int", "float"] else 0
                        flight_info["location"] = "%dkt %dft" % (speed * KN_RATIO, flight_info.get("altitude"))
                        flight_info["aircraft_info"] = get_aircraft_info(flight_info.get("icao24"))
                        flight_info["owners"] = flight_info.get("aircraft_info").get("owners")
                        flight_info["type"] = flight_info.get("aircraft_info").get("type")

                        if show_route and valid_code(flight_info.get("callsign")):
                            route_response_url = "%s/route/icao/%s" % (PROVIDERS["hexdb"]["url"], flight_info.get("callsign"))
                            route_response = http.get(route_response_url, ttl_seconds = provider_ttl_seconds)
                            check_response_headers("hexdb", route_response, provider_ttl_seconds)

                            if route_response.status_code == 200:
                                route_json = validate_json(route_response)
                                route = route_json.get("route") if type(route_json) == "dict" else None
                                if type(route) == "string" and route and len(route) <= 32:
                                    flight_info["route"] = route

                        if flight_info["type"]:
                            flight_info["plane"] += " (%s)" % flight_info.get("type")

                if should_ignore(flight_info):
                    print_log("ignoring %s" % flight_info.get("callsign"))

                elif is_flying(flight_info):
                    second_line_content = flight_info.get("route") or flight_info.get("owners") or "Route unavailable"
                    second_line_font = ""
                    if len(second_line_content) > MAX_WIDTH_CHARACTERS * 0.75:
                        second_line_font = "CG-pixel-3x5-mono"

                    flights.append(
                        render.Box(
                            render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Text(flight_info.get("plane")),
                                    render.Text(
                                        content = second_line_content,
                                        font = second_line_font,
                                    ),
                                    render.Text(flight_info.get("location")),
                                ],
                            ),
                        ),
                    )
                    flights_index += 1

        print_log("showing %s within %dnm of %s" % (humanize.plural(flights_index, "flight"), radius, location))

        if len(flights) > 1:
            for flight in flights:
                children.append(
                    animation.Transformation(
                        direction = "reverse",
                        duration = 150,
                        child = flight,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, -32)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(0, -0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.9,
                                transforms = [animation.Translate(0, -0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, -32)],
                                curve = "ease_in_out",
                            ),
                        ],
                    ),
                )

            child = render.Sequence(
                children = children,
            )
        else:
            child = flights and flights[0]

        if child:
            return render.Root(
                max_age = MAX_AGE,
                show_full_animation = True,
                child = child,
            )

        else:
            return empty_message()

    print_log(time.now())

    lat = valid_coordinate(location.get("lat"), -89.9, 89.9)
    lng = valid_coordinate(location.get("lng"), -180, 180)
    if lat == None or lng == None:
        return render.Root(child = render.WrappedText("Check location", color = "#ff6666"))

    miles_per_deg_lat = 69.1
    miles_per_deg_lng = 69.1 * math.cos(lat / 180 * math.pi)
    lat_pm = radius / miles_per_deg_lat
    lng_pm = radius / miles_per_deg_lng
    la_min = lat - lat_pm
    lo_min = lng - lng_pm
    la_max = lat + lat_pm
    lo_max = lng + lng_pm
    bbox = "%s,%s,%s,%s" % (la_min, lo_min, la_max, lo_max)

    headers = {}
    if provider == "airlabs":
        if not valid_secret(airlabs_api_key):
            return render.Root(child = render.WrappedText("Add AirLabs key", color = "#ff6666"))
        provider_response_url = "%s/flights" % PROVIDERS["airlabs"]["url"]
        params = {"bbox": bbox, "api_key": airlabs_api_key, "_fields": "hex,reg_number,flight_number,airline_iata,airline_icao,aircraft_icao,dep_iata,arr_iata,alt,speed"}
    else:
        provider_response_url = "%s/states/all" % PROVIDERS["opensky"]["url"]
        params = {"lamin": str(la_min), "lomin": str(lo_min), "lamax": str(la_max), "lomax": str(lo_max)}
        if opensky_username or opensky_password:
            if not valid_client_id(opensky_username) or not valid_secret(opensky_password):
                return render.Root(child = render.WrappedText("Check OpenSky API client", color = "#ff6666"))
            token_response = http.post(
                OPENSKY_TOKEN_URL,
                headers = {"Content-Type": "application/x-www-form-urlencoded"},
                form_body = {"grant_type": "client_credentials", "client_id": opensky_username, "client_secret": opensky_password},
            )
            token_payload = validate_json(token_response)
            access_token = token_payload.get("access_token") if type(token_payload) == "dict" else None
            if not valid_secret(access_token):
                return render.Root(child = render.WrappedText("OpenSky login failed", color = "#ff6666"))
            headers = {"Authorization": "Bearer %s" % access_token}

    provider_response = http.get(provider_response_url, params = params, headers = headers, ttl_seconds = provider_ttl_seconds)
    check_response_headers(provider, provider_response, provider_ttl_seconds)
    if provider_response.status_code != 200:
        return render.Root(child = render.WrappedText("Provider API Error: %d" % provider_response.status_code))

    provider_json = validate_json(provider_response)
    if type(provider_json) != "dict":
        return empty_message()

    if provider == "airlabs" and type(provider_json.get("response")) == "list":
        return _render(provider, provider_json.get("response"))
    if provider == "opensky" and type(provider_json.get("states")) == "list":
        return _render(provider, provider_json.get("states"))
    error = provider_json.get("error")
    if type(error) == "dict" and type(error.get("message")) == "string":
        return render.Root(child = render.WrappedText(error.get("message")[:120]))
    return empty_message()

def valid_coordinate(value, minimum, maximum):
    text = str(value or "")
    if len(text) > 24 or not re.match("^-?[0-9]+(\\.[0-9]+)?$", text):
        return None
    number = float(text)
    return number if number >= minimum and number <= maximum else None

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 8192 and "\r" not in value and "\n" not in value

def valid_client_id(value):
    return type(value) == "string" and value and len(value) <= 256 and all([char.isalnum() or char in "-_" for char in value.codepoints()])

def valid_code(value):
    return type(value) == "string" and value and len(value) <= 16 and all([char.isalnum() for char in value.codepoints()])

def get_schema():
    providers = []

    for provider in PROVIDERS:
        if PROVIDERS[provider]["display"]:
            providers.append(
                schema.Option(
                    display = PROVIDERS[provider]["name"],
                    value = provider,
                ),
            )

    limits = []

    for i in range(MAX_LIMIT):
        limits.append(schema.Option(display = "%d" % (i + 1), value = "%d" % (i + 1)))

    radii = []

    for i in range(MAX_RADIUS):
        radii.append(schema.Option(display = "%d" % (i + 1), value = "%d" % (i + 1)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "provider",
                name = "Provider (Required)",
                desc = "The provider for the data",
                icon = "ioxhost",
                default = DEFAULT_PROVIDER,
                options = providers,
            ),
            schema.Text(
                id = "location",
                name = "Location (Required)",
                desc = "Location JSON with lat and lng. Existing Tidbyt location values continue to work.",
                icon = "mapLocationDot",
                default = DEFAULT_LOCATION,
            ),
            schema.Dropdown(
                id = "radius",
                name = "Radius",
                desc = "The radius (in nautical miles) to search",
                icon = "circleDot",
                default = "%s" % DEFAULT_RADIUS,
                options = radii,
            ),
            schema.Text(
                id = "airlabs_api_key",
                name = "AirLabs API Key",
                desc = "An AirLabs API Key is required to use AirLabs as the provider",
                icon = "key",
                default = DEFAULT_AIRLABS_API_KEY,
                secret = True,
            ),
            schema.Text(
                id = "opensky_username",
                name = "OpenSky Client ID",
                desc = "An OpenSky OAuth client can be used to extend the request quota",
                icon = "user",
                default = DEFAULT_OPENSKY_USERNAME,
            ),
            schema.Text(
                id = "opensky_password",
                name = "OpenSky Client Secret",
                desc = "The client secret paired with your OpenSky client ID",
                icon = "key",
                default = DEFAULT_OPENSKY_PASSWORD,
                secret = True,
            ),
            schema.Text(
                id = "provider_ttl_seconds",
                name = "Provider TTL Seconds",
                desc = "The number of seconds to cache results from the provider",
                icon = "clock",
                default = "%s" % DEFAULT_PROVIDER_TTL_SECONDS,
            ),
            schema.Toggle(
                id = "show_route",
                name = "Show Route",
                desc = "Some providers can often display incorrect routes",
                icon = "route",
                default = DEFAULT_SHOW_ROUTE,
            ),
            schema.Dropdown(
                id = "limit",
                name = "Limit",
                desc = "Limit the number of results to display",
                icon = "list",
                default = "%s" % DEFAULT_LIMIT,
                options = limits,
            ),
            schema.Text(
                id = "return_message_on_empty",
                name = "Return Message on Empty",
                desc = "The message to return if no flights are found",
                icon = "message",
                default = DEFAULT_RETURN_MESSAGE_ON_EMPTY,
            ),
        ],
    )
