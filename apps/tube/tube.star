"""Show London rail arrivals from Transport for London's Unified API."""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

ARRIVALS_URL = "https://api.tfl.gov.uk/StopPoint/%s/Arrivals"
DEFAULT_STATION = "940GZZLUHBN|Holborn|central"
USER_AGENT = "Niblet tube"
ORANGE = "#FFA500"
FONT = "tom-thumb"

LINES = {
    "bakerloo": {"display": "Bakerloo", "colour": "#894E24", "textColour": "#FFF"},
    "central": {"display": "Central", "colour": "#DC241F", "textColour": "#FFF"},
    "circle": {"display": "Circle", "colour": "#FFCC00", "textColour": "#000"},
    "district": {"display": "District", "colour": "#007229", "textColour": "#FFF"},
    "dlr": {"display": "Docklands", "colour": "#00AFAD", "textColour": "#000"},
    "elizabeth": {"display": "Elizabeth", "colour": "#6950A1", "textColour": "#FFF"},
    "hammersmith-city": {"display": "H'smith & City", "colour": "#D799AF", "textColour": "#000"},
    "jubilee": {"display": "Jubilee", "colour": "#6A7278", "textColour": "#FFF"},
    "london-overground": {"display": "Overground", "colour": "#D05F0E", "textColour": "#000"},
    "metropolitan": {"display": "Metropolitan", "colour": "#751056", "textColour": "#FFF"},
    "northern": {"display": "Northern", "colour": "#000", "textColour": "#FFF"},
    "piccadilly": {"display": "Piccadilly", "colour": "#0019A8", "textColour": "#FFF"},
    "tram": {"display": "Tram", "colour": "#66CC00", "textColour": "#FFF"},
    "victoria": {"display": "Victoria", "colour": "#00A0E2", "textColour": "#000"},
    "waterloo-city": {"display": "W'loo & City", "colour": "#76D0BD", "textColour": "#000"},
}

def station_config(value):
    """Read the direct value and the nested option JSON saved by the old picker."""
    value = value.strip() if type(value) == "string" else ""
    if not value:
        value = DEFAULT_STATION

    decoded = json.decode(value, None) if value.startswith("{") else None
    if type(decoded) == "dict" and type(decoded.get("value")) == "string":
        value = decoded["value"].strip()
        decoded = json.decode(value, None) if value.startswith("{") else None

    if type(decoded) == "dict":
        station_id = decoded.get("station_id")
        station_name = decoded.get("station_name")
        line_id = decoded.get("line_id")
    else:
        parts = value.split("|")
        if len(parts) != 3:
            return None
        station_id, station_name, line_id = parts

    if type(station_id) != "string" or not station_id or len(station_id) > 80:
        return None
    if not all([station_id[i].isalnum() or station_id[i] in ["-", "_"] for i in range(len(station_id))]):
        return None
    if type(station_name) != "string" or not station_name.strip() or len(station_name) > 120:
        return None
    if line_id not in LINES:
        return None
    return station_id, station_name.strip(), line_id

def short_station(name):
    for suffix in [" Underground Station", " DLR Station", " Rail Station", " (London)", " Tram Stop"]:
        name = name.removesuffix(suffix)
    if name != "London Bridge":
        name = name.removeprefix("London ")
    replacements = {"Street": "St", "Road": "Rd", "Great": "Gt", "Square": "Sq"}
    return " ".join([replacements.get(word, word) for word in name.split(" ")])[:120]

def short_destination(name):
    name = short_station(name)
    replacements = {
        "Central": "C",
        "Court": "Ct",
        "East": "E",
        "Green": "Grn",
        "Junction": "Jct",
        "Lane": "Ln",
        "North": "N",
        "Palace": "P",
        "Park": "Pk",
        "South": "S",
        "Station": "Stn",
        "West": "W",
    }
    return " ".join([replacements.get(word, word) for word in name.split(" ")])[:120]

def request_arrivals(station_id, api_key):
    params = {"app_key": api_key} if api_key else {}
    response = http.get(
        ARRIVALS_URL % station_id,
        params = params,
        headers = {"Accept": "application/json", "User-Agent": USER_AGENT},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 1048576:
        return []
    data = json.decode(body, None)
    return data[:200] if type(data) == "list" else []

def arrival_groups(station_id, line_id, api_key):
    groups = {}
    for item in request_arrivals(station_id, api_key):
        if type(item) != "dict" or item.get("lineId") != line_id or item.get("destinationNaptanId") == station_id:
            continue
        seconds = item.get("timeToStation")
        destination = item.get("destinationName")
        if type(seconds) not in ["int", "float"] or seconds < 0 or seconds > 21600 or type(destination) != "string" or not destination:
            continue
        direction = short_destination(destination)
        groups.setdefault(direction, []).append(seconds)

    result = []
    for direction, seconds in sorted(groups.items()):
        minutes = []
        for value in sorted(seconds)[:4]:
            proposed = ",".join(minutes + [str(int(math.round(value / 60.0)))])
            if len(proposed) > 4:
                break
            minutes.append(str(int(math.round(value / 60.0))))
        if minutes:
            result.append((direction, ",".join(minutes)))
    return result[:6]

def arrivals_view(arrivals):
    if not arrivals:
        return render.Box(width = 64, child = render.WrappedText("No arrivals data", width = 62, align = "center", color = ORANGE, font = FONT))
    frames = []
    for start in range(0, len(arrivals), 3):
        rows = []
        for direction, times in arrivals[start:start + 3]:
            rows.append(render.Row(expanded = True, main_align = "space_between", children = [
                render.WrappedText(direction, color = ORANGE, font = FONT, width = 44, height = 6),
                render.WrappedText(times, color = ORANGE, font = FONT, width = 17, height = 6, align = "right"),
            ]))
        frames.append(render.Column(main_align = "space_evenly", expanded = True, children = rows))
    return render.Animation(children = frames)

def message(text):
    return render.Root(child = render.WrappedText(text, width = 62, align = "center", font = FONT))

def main(config):
    station = station_config(config.get("station_and_line"))
    api_key = config.str("tfl_api_key", "").strip()
    if not station or len(api_key) > 512:
        return message("Configure station ID, name and line")
    station_id, station_name, line_id = station
    line = LINES[line_id]
    return render.Root(
        max_age = 60,
        delay = 2000,
        show_full_animation = True,
        child = render.Column(children = [
            render.Box(width = 64, height = 13, color = line["colour"], child = render.Column(children = [
                render.Marquee(width = 62, align = "center", child = render.Text(short_station(station_name), color = line["textColour"], font = FONT)),
                render.WrappedText(line["display"], color = line["textColour"], font = FONT, align = "center", width = 62, height = 8),
            ])),
            render.Box(height = 1, width = 1),
            arrivals_view(arrival_groups(station_id, line_id, api_key)),
        ]),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(
            id = "station_and_line",
            name = "Station and line",
            desc = "TfL station ID, display name and line ID separated by |, for example 940GZZLUHBN|Holborn|central. Existing picker selections continue to work.",
            icon = "trainSubway",
            default = DEFAULT_STATION,
        ),
        schema.Text(
            id = "tfl_api_key",
            name = "TfL API Key",
            desc = "Optional key from api.tfl.gov.uk; anonymous quota is supported.",
            icon = "key",
            secret = True,
        ),
    ])
