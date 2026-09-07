load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Entur API endpoint for real-time departures
ENTUR_API_URL = "https://api.entur.io/journey-planner/v3/graphql"
DISPLAY_WIDTH = 64
DISPLAY_HEIGHT = 32
HEADER_HEIGHT = 6
HEADER_FONT_WIDTH = 5
HEADER_INDICATOR_WIDTH = 6
HEADER_INDICATOR_PADDING = 2
HEADER_TEXT_WIDTH = DISPLAY_WIDTH - HEADER_INDICATOR_WIDTH - HEADER_INDICATOR_PADDING
HEADER_MAX_CHARS = HEADER_TEXT_WIDTH // HEADER_FONT_WIDTH
SEPARATOR_HEIGHT = 1
ROW_HEIGHT = 8
MAX_VISIBLE_ROWS = (DISPLAY_HEIGHT - HEADER_HEIGHT - SEPARATOR_HEIGHT) // ROW_HEIGHT
MAX_RESPONSE_BYTES = 512 * 1024
MAX_TEXT_LENGTH = 80
DEPARTURES_QUERY = """query($id: String!, $departures: Int!) {
  stopPlace(id: $id) {
    name
    quays {
      id
      estimatedCalls(timeRange: 72000, numberOfDepartures: $departures) {
        expectedDepartureTime
        serviceJourney { line { publicCode } }
      }
    }
  }
}"""

def truncate_text(text, max_len):
    if not text:
        return ""
    if len(text) <= max_len:
        return text
    if max_len <= 1:
        return text[:max_len]
    return text[:max_len - 1] + "."

def abbreviate_stop_words(text):
    if not text:
        return ""

    abbreviations = {
        "gate": "gt.",
        "vei": "v.",
        "veg": "vg.",
        "terminal": "Term.",
        "bussterminal": "Bst.",
    }

    words_to_skip = ["stasjon"]

    words = text.split(" ")
    short_words = []

    for word in words:
        lower_word = word.lower()
        if lower_word in abbreviations:
            short_words.append(abbreviations[lower_word])
        elif lower_word not in words_to_skip:
            short_words.append(word)

    return " ".join(short_words)

def display_stop_name(name):
    return truncate_text(abbreviate_stop_words(name), HEADER_MAX_CHARS)

def minutes_until_departure(current_time, departure_time):
    # Extract HH:MM from ISO format strings
    if type(current_time) != "string" or type(departure_time) != "string" or len(current_time) < 16 or len(departure_time) < 16:
        return None
    current_hhmm = current_time[11:13] + current_time[14:16]
    departure_hhmm = departure_time[11:13] + departure_time[14:16]
    if not current_hhmm.isdigit() or not departure_hhmm.isdigit():
        return None
    current_hours = int(current_time[11:13])
    current_minutes = int(current_time[14:16])
    departure_hours = int(departure_time[11:13])
    departure_minutes = int(departure_time[14:16])
    if current_hours > 23 or departure_hours > 23 or current_minutes > 59 or departure_minutes > 59:
        return None

    # Convert to total minutes
    current_total = current_hours * 60 + current_minutes
    departure_total = departure_hours * 60 + departure_minutes

    # Calculate difference
    minutes_until = departure_total - current_total

    # Handle next day case
    if minutes_until < 0:
        minutes_until = minutes_until + (24 * 60)

    return minutes_until

def departure_time_style(minutes_left):
    if minutes_left <= 1:
        return ("NÅ", "#ff6b6b")
    if minutes_left <= 5:
        return (str(minutes_left) + "m", "#a95200ff")
    return (str(minutes_left) + "m", "#519de9ff")

def live_indicator():
    return render.Box(
        width = 6,
        height = HEADER_HEIGHT,
        child = render.Animation(
            children = [
                render.Circle(diameter = 2, color = "#2f9e4418"),
                render.Circle(diameter = 2, color = "#2f9e4470"),
                render.Circle(diameter = 3, color = "#2f9e44b0"),
                render.Circle(diameter = 2, color = "#2f9e4470"),
            ],
        ),
    )

def header_box(stop_name, text_color):
    return render.Box(
        width = DISPLAY_WIDTH,
        height = HEADER_HEIGHT,
        child = render.Stack(
            children = [
                render.Box(
                    width = HEADER_TEXT_WIDTH,
                    height = HEADER_HEIGHT,
                    child = render.Text(
                        content = display_stop_name(stop_name),
                        font = "CG-pixel-4x5-mono",
                        color = text_color,
                    ),
                ),
                render.Box(
                    width = DISPLAY_WIDTH,
                    height = HEADER_HEIGHT,
                    child = render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "center",
                        children = [
                            live_indicator(),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "Stopp-ID",
                desc = "Stopp-ID fra Entur, for eksempel NSR:StopPlace:6286. Finn det på stoppested.entur.org.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "quay_id",
                name = "Plattform-ID",
                desc = "Plattform-ID fra Entur, for eksempel NSR:Quay:11544. Finn det på stoppested.entur.org.",
                icon = "bus",
            ),
            schema.Text(
                id = "stop_name",
                name = "Stoppnavn",
                desc = "Valgfritt visningsnavn. La stå tomt for å bruke standardvalg",
                icon = "signature",
            ),
            schema.Dropdown(
                id = "num_departures",
                name = "Avganger",
                desc = "Antall avganger som skal vises.",
                icon = "list",
                default = "3",
                options = [
                    schema.Option(display = str(i), value = str(i))
                    for i in range(1, 4)
                ],
            ),
        ],
    )

def main(config):
    # Get stop IDs from config
    stop_id = config.get("stop_id")
    quay_id = config.get("quay_id")
    stop_name = config.get("stop_name", "")

    if not stop_id or not quay_id:
        return render.Root(
            child = render.Box(
                width = DISPLAY_WIDTH,
                height = DISPLAY_HEIGHT,
                child = render.WrappedText(
                    content = "Legg inn stopp- og plattform-ID i oppsettet",
                    font = "CG-pixel-4x5-mono",
                    color = "#b0b0b0",
                ),
            ),
        )
    if not valid_entur_id(stop_id, "NSR:StopPlace:") or not valid_entur_id(quay_id, "NSR:Quay:"):
        return error_root("Ugyldig stopp-ID")
    stop_name = str(stop_name or "")[:MAX_TEXT_LENGTH]
    requested_departures = str(config.get("num_departures", "3"))
    num_departures = int(requested_departures) if requested_departures in ["1", "2", "3"] else 3

    # Set up headers
    headers = {
        "ET-Client-Name": "heyniblet-entur-departures",
        "Content-Type": "application/json",
    }

    # Make the request to Entur API
    rep = http.post(
        ENTUR_API_URL,
        json_body = {
            "query": DEPARTURES_QUERY,
            "variables": {"id": stop_id, "departures": num_departures},
        },
        headers = headers,
    )

    if rep.status_code != 200:
        return render.Root(
            delay = 350,
            child = render.Column(
                children = [
                    header_box(stop_name or "Stopp", "#b0b0b0"),
                    render.Text(
                        "Ingen sanntidsdata",
                        font = "CG-pixel-4x5-mono",
                        color = "#ff6b6b",
                    ),
                    render.Text(
                        "Prøv igjen snart",
                        font = "CG-pixel-4x5-mono",
                        color = "#6c757d",
                    ),
                ],
            ),
        )

    # Parse the JSON response
    body = rep.body()
    response_data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    departures = []
    header = header_box(stop_name or "Stopp", "#b0b0b0")
    separator = render.Box(
        width = DISPLAY_WIDTH,
        height = SEPARATOR_HEIGHT,
        color = "#a7d6ebff",
    )

    # Extract departure information
    data = response_data.get("data") if type(response_data) == "dict" else None
    stop_place = data.get("stopPlace") if type(data) == "dict" else None
    if type(stop_place) == "dict":
        if not stop_name:
            stop_name = str(stop_place.get("name") or "Ukjent stopp")[:MAX_TEXT_LENGTH]

        # Create the header box
        header = header_box(stop_name, "#62cfebff")

        quays = stop_place.get("quays")
        if type(quays) == "list":
            for quay in quays[:100]:
                calls = quay.get("estimatedCalls") if type(quay) == "dict" and quay.get("id") == quay_id else None
                if type(calls) == "list":
                    for call in calls[:num_departures]:
                        if len(departures) >= MAX_VISIBLE_ROWS:
                            break

                        journey = call.get("serviceJourney") if type(call) == "dict" else None
                        line_data = journey.get("line") if type(journey) == "dict" else None
                        line = line_data.get("publicCode") if type(line_data) == "dict" else None
                        departure_time = call.get("expectedDepartureTime") if type(call) == "dict" else None
                        if type(line) not in ["string", "int"] or type(departure_time) != "string" or len(departure_time) > 40:
                            continue

                        # Get current time in the same format as departure_time
                        current_time = time.now().format("2006-01-02T15:04:05-07:00")
                        minutes_left = minutes_until_departure(current_time, departure_time)
                        if minutes_left == None:
                            continue
                        time_str, time_color = departure_time_style(minutes_left)

                        departures.append(
                            render.Box(
                                width = DISPLAY_WIDTH,
                                height = ROW_HEIGHT,
                                child = render.Row(
                                    main_align = "space_between",
                                    children = [
                                        render.Box(
                                            width = 26,
                                            child = render.Text(
                                                content = truncate_text(str(line), 6),
                                                font = "CG-pixel-4x5-mono",
                                                color = "#ffd166",
                                            ),
                                        ),
                                        render.Box(
                                            width = 24,
                                            child = render.Text(
                                                content = time_str,
                                                font = "CG-pixel-4x5-mono",
                                                color = time_color,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        )

                    break
    else:
        print("No stop place data found")

    if not departures:
        departures = [
            render.Text(
                "Ingen avganger",
                font = "CG-pixel-4x5-mono",
                color = "#ced4da",
            ),
        ]

    return render.Root(
        delay = 350,
        child = render.Column(
            children = [header, separator] + departures,
        ),
    )

def valid_entur_id(value, prefix):
    return type(value) == "string" and len(value) <= 80 and value.startswith(prefix) and value[len(prefix):].isdigit()

def error_root(message):
    return render.Root(child = render.Box(render.WrappedText(message, font = "CG-pixel-4x5-mono", color = "#ff6b6b")))
