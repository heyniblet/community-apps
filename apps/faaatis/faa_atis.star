"""
Applet: FAA ATIS
Summary: ATIS runway information
Description: Display FAA ATIS information (runways in use) for a given airport.
Author: Connick Shields
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Theme
TEXT_COLOR = "#FFFFFF"
INFO_COLOR = "#4CAF50"
ARR_COLOR = "#2196F3"  # Blue for arrivals
DEP_COLOR = "#FFC107"  # Amber for departures
DEFAULT_FONT = "tom-thumb"

API_URL = "https://atis.info/api/"
AIRPORT_DB_URL = "https://airportdb.io/api/v1/airport/{}"
MAX_ATIS_BYTES = 256 * 1024
MAX_AIRPORT_BYTES = 1024 * 1024
MAX_RUNWAYS = 100

def get_airport_runways(icao, api_token):
    """Fetch runway information from airport database."""
    response = http.get(AIRPORT_DB_URL.format(icao), params = {"apiToken": api_token})
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_AIRPORT_BYTES:
        return []
    data = json.decode(body, None)
    runways_data = data.get("runways") if type(data) == "dict" else None
    if type(runways_data) != "list":
        return []

    runways = []
    for rwy in runways_data[:MAX_RUNWAYS]:
        if type(rwy) != "dict":
            continue

        # Skip closed runways
        if str(rwy.get("closed") or "") == "1":
            continue

        # Get both ends of the runway
        le_ident = valid_runway_ident(rwy.get("le_ident"))
        he_ident = valid_runway_ident(rwy.get("he_ident"))

        # Add both ends to our runway list
        if le_ident:
            runways.append(le_ident)
        if he_ident:
            runways.append(he_ident)
    return runways

def valid_runway_ident(value):
    value = str(value or "").strip().upper()
    numeric = value[:-1] if value and value[-1] in ["L", "R", "C"] else value
    return value if numeric and len(numeric) <= 2 and numeric.isdigit() else None

def extract_number(runway):
    """Extract the numeric part of a runway designator."""
    if runway.isdigit():
        return int(runway)

    # For runways like "28R", take just the numeric part
    num = runway[:-1] if runway[-1] in ["L", "R", "C"] else runway
    return int(num)

def extract_runways(text, icao, api_token):
    # Get valid runways for this airport
    valid_runways = get_airport_runways(icao, api_token)
    if not valid_runways:
        return [], []

    # Split on NOTAM and take only the first part
    main_atis = text.split("NOTAM")[0].split("...ADVS")[0]
    runways = {}  # Use dict to track runway usage
    state = {
        "processed_arrivals": False,
        "processed_departures": False,
    }

    def is_valid_runway(word):
        """Check if a word is a valid runway number for this airport."""
        word = word.strip(",.").replace(",", "")

        # First check if it's a valid runway format
        if not ((word.isdigit() and (len(word) == 1 or len(word) == 2)) or
                (len(word) == 2 and word[0].isdigit() and word[1] in ["L", "R", "C"]) or
                (len(word) == 3 and word[0:2].isdigit() and word[2] in ["L", "R", "C"])):
            return False

        if len(word) == 1:
            word = "0" + word

        if len(word) == 2 and word[1] in ["L", "R", "C"]:
            word = "0" + word

        # Then check if it exists at this airport
        if word in valid_runways:
            return True
        return False

    def process_sentence(sentence):
        # Skip LAHSO and equipment information
        if "HOLD SHORT" in sentence or "PAPIS" in sentence or "EQUIPMENT" in sentence or "CONDITION" in sentence:
            return

        # Skip closures
        if "CLSD" in sentence or "CLOSED" in sentence or "OTS" in sentence:
            return

        sentence_upper = sentence.upper()

        # Track current state
        current_mode = None  # None, "ARR", or "DEP"
        arrival_runways = []
        departure_runways = []

        arrival_sentence = (
            "APCH" in sentence_upper or
            "APP" in sentence_upper or
            "APPROACH" in sentence_upper or
            "LNDG" in sentence_upper or
            "LAND" in sentence_upper or
            "ARR" in sentence_upper or
            "VISUAL" in sentence_upper or
            "VA" == sentence_upper or
            "ILS" in sentence_upper
        )

        current_mode = "ARR" if arrival_sentence else None

        # Process each word
        words = sentence.split()
        for word in words:
            word_upper = word.upper()

            # Check for mode changes
            is_arrival = (
                "APCH" in word_upper or
                "APP" in word_upper or
                "APPROACH" in word_upper or
                "LNDG" in word_upper or
                "LAND" in word_upper or
                "ARR" in word_upper or
                "VISUAL" in word_upper or
                "VA" == word_upper or
                "ILS" in word_upper
            )

            is_departure = (
                "DEP" in word_upper or
                "DEPG" in word_upper or
                "DEPS" in word_upper or
                "DEPART" in word_upper or
                "DEPARTURE" in word_upper
            )

            if is_arrival:
                current_mode = "ARR"
                continue

            if is_departure:
                current_mode = "DEP"
                continue

            if is_valid_runway(word):
                if current_mode == "ARR":
                    arrival_runways.append(word.strip(",.").replace(",", ""))
                elif current_mode == "DEP":
                    departure_runways.append(word.strip(",.").replace(",", ""))
                else:
                    # If no previous mode, mark for both
                    arrival_runways.append(word.strip(",.").replace(",", ""))
                    departure_runways.append(word.strip(",.").replace(",", ""))

        if len(arrival_runways) > 0:
            state["processed_arrivals"] = True
            for rwy in arrival_runways:
                if rwy not in runways:
                    runways[rwy] = {"A": True, "D": False}
                else:
                    runways[rwy]["A"] = True

        if len(departure_runways) > 0:
            state["processed_departures"] = True
            for rwy in departure_runways:
                if rwy not in runways:
                    runways[rwy] = {"A": False, "D": True}
                else:
                    runways[rwy]["D"] = True

    # Split into sentences and clean them
    sentences = []
    for s in main_atis.split("."):
        if s.strip():
            sentences.append(s.strip())

    # Process each sentence
    for sentence in sentences:
        process_sentence(sentence)

        # If we've processed both arrivals and departures, we can stop
        if state["processed_arrivals"] and state["processed_departures"]:
            break

    # Separate arrivals and departures
    arrivals = []
    departures = []

    # Sort runways by number first
    sorted_runways = sorted(runways.items(), key = lambda x: extract_number(x[0]))

    for rwy, usage in sorted_runways:
        if usage["A"]:
            arrivals.append(rwy)
        if usage["D"]:
            departures.append(rwy)

    return arrivals, departures

def main(config):
    # Load config settings from mobile app, or set default
    config_airport = safe_icao(config.str("airport", "KDCA"))
    api_token = safe_token(config.str("airport_db_api_token", ""))
    if not api_token:
        return api_error()

    api_url = "{api}{airport}".format(
        api = API_URL,
        airport = config_airport,
    )

    # Get data from API
    response = http.get(api_url)
    body = response.body()
    payload = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_ATIS_BYTES else None
    if type(payload) != "list" or not payload or type(payload[0]) != "dict":
        return api_error()
    atis_data = payload[0]

    # Extract key information
    airport = safe_icao(atis_data.get("airport"))
    atis_code = safe_text(atis_data.get("code"), 8)
    datis = safe_text(atis_data.get("datis"), 8192)
    if not airport or not datis:
        return api_error()

    # Extract active runways
    arrivals, departures = extract_runways(datis, airport, api_token)
    if len(departures) == 0:
        departures = arrivals

    # Format runway lists
    arr_runways = " ".join(arrivals) if arrivals else "NONE"
    dep_runways = " ".join(departures) if departures else "NONE"

    # Format header with right-aligned INFO code
    info_text = "%s" % atis_code

    return render.Root(
        child = render.Box(
            padding = 1,  # Add 1 pixel padding around all content
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Text(" ", font = DEFAULT_FONT),
                            render.Text(airport, color = TEXT_COLOR, font = DEFAULT_FONT),
                            render.Text("   INFO ", font = DEFAULT_FONT),  # Space between parts
                            render.Text(info_text, color = INFO_COLOR, font = DEFAULT_FONT),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text(" ARR: ", color = ARR_COLOR, font = DEFAULT_FONT, height = 8),
                            render.Marquee(
                                width = 36,
                                child = render.Text(arr_runways, color = ARR_COLOR, font = DEFAULT_FONT, height = 8),
                                offset_start = 0,  # Start from right edge
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text(" DEP: ", color = DEP_COLOR, font = DEFAULT_FONT, height = 8),
                            render.Marquee(
                                width = 36,
                                child = render.Text(dep_runways, color = DEP_COLOR, font = DEFAULT_FONT, height = 8),
                                offset_start = 0,  # Start from right edge
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def safe_icao(value):
    value = str(value or "").strip().upper()
    return value if len(value) == 4 and value.isalnum() else "KDCA"

def safe_token(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 4096 and "\r" not in value and "\n" not in value else ""

def safe_text(value, max_length):
    return value[:max_length] if type(value) == "string" else ""

def api_error():
    return render.Root(child = render.Text("API Error", font = DEFAULT_FONT))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airport_db_api_token",
                name = "AirportDB API Token",
                desc = "Your AirportDB.io API token. See https://airportdb.io/api/v1/docs for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "airport",
                name = "Airport",
                desc = "4-letter ICAO airport code",
                icon = "plane",
                default = "KDCA",
            ),
        ],
    )
