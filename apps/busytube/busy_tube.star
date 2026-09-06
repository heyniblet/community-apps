"""
Applet: Busy Tube
Summary: London station crowding
Description: Tells you how busy a given TfL-operated station in London currently is. Data updated every five minutes.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RED = "#d3212c"
GREEN = "#69b34c"
ORANGE = "#ff980e"
GREY = "#666"
WHITE = "#fff"

DEFAULT_STATION_NAME = "Russell Square"
DEFAULT_NAPTAN_ID = "940GZZLURSQ"

CROWDING_LIVE_URL = "https://api.tfl.gov.uk/Crowding/%s/Live"
CROWDING_TYPICAL_URL = "https://api.tfl.gov.uk/Crowding/%s/%s"
USER_AGENT = "Tidbyt busy_tube"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_TIME_BANDS = 96

CONTAINER_WIDTH = 62
CONTAINER_HEIGHT = 30
GRAPH_WIDTH = 63  # Container is 62 wide, but that leaves an empty column for some reason
GRAPH_HEIGHT = 14
HOURS_PER_DAY = 24
MINUTES_PER_HOUR = 60
MINUTES_PER_DAY = 1440
QUIET_MAX = 0.4
BUSY_MAX = 0.7

def app_key(config):
    return config.get("tfl_app_key") or ""

def request_params(config):
    key = app_key(config)
    return {"app_key": key} if key else {}

def fetch_json(url, config):
    resp = http.get(url, params = request_params(config), headers = {"User-Agent": USER_AGENT})
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        print("TfL crowding request failed with status %d" % resp.status_code)
        return None
    data = json.decode(body, None)
    return data if type(data) == "dict" else None

def station_config(value):
    if not value:
        return DEFAULT_STATION_NAME, DEFAULT_NAPTAN_ID
    raw = str(value).strip()
    data = json.decode(raw, None)
    if type(data) == "dict" and data.get("value"):
        raw = str(data["value"])
        data = json.decode(raw, None)
    if type(data) == "dict":
        station_name = str(data.get("name") or data.get("commonName") or "Tube station").strip()
        naptan_id = str(data.get("naptanId") or data.get("id") or "").strip()
    else:
        station_name = "Tube station"
        naptan_id = raw
    for char in naptan_id.elems():
        if char not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789":
            return DEFAULT_STATION_NAME, DEFAULT_NAPTAN_ID
    return (station_name[:80] or "Tube station", naptan_id if naptan_id and len(naptan_id) <= 32 else DEFAULT_NAPTAN_ID)

# Fetch data about how crowded the station currently is
def fetch_live_crowdedness(naptan_id, config):
    live_url = CROWDING_LIVE_URL % naptan_id
    data = fetch_json(live_url, config)
    if not data or not data.get("dataAvailable"):
        print("TFL live crowdedness data not available")
        return None
    return data

# Extract data about currrent crowdedness from API response
def get_live_crowdedness(naptan_id, config):
    resp = fetch_live_crowdedness(naptan_id, config)
    if not resp:
        return None
    return resp["percentageOfBaseline"]

# Follows same numbering as humanize.day_of_week
def weekday_name(date):
    day_of_week = humanize.day_of_week(date)
    if day_of_week == 0:
        return "SUN"
    if day_of_week == 1:
        return "MON"
    if day_of_week == 2:
        return "TUE"
    if day_of_week == 3:
        return "WED"
    if day_of_week == 4:
        return "THU"
    if day_of_week == 5:
        return "FRI"
    if day_of_week == 6:
        return "SAT"
    fail("Invalid day of the week")

# Fetch data about how crowded the station typically is on a given day
def fetch_typical_crowdedness(naptan_id, now, config):
    typical_url = CROWDING_TYPICAL_URL % (naptan_id, weekday_name(now))
    data = fetch_json(typical_url, config)
    if not data or not data.get("isFound"):
        print("TFL typical crowdedness data not available")
        return None
    return data

# Convert a time period from the API into a float we can use to plot.
# "13:45-14:00" -> 13.75
def extract_time(timeBand):
    hour = int(timeBand[0:2])
    minute = int(timeBand[3:5]) / float(MINUTES_PER_HOUR)
    return hour + minute

# Extract data about typical crowdedness from API response.
def get_typical_crowdedness(naptan_id, now, config):
    resp = fetch_typical_crowdedness(naptan_id, now, config)
    if not resp:
        return []
    data = []
    for band in resp.get("timeBands", [])[:MAX_TIME_BANDS]:
        if type(band) != "dict" or not band.get("timeBand") or type(band.get("percentageOfBaseLine")) not in ["int", "float"]:
            continue
        data.append((extract_time(band["timeBand"]), band["percentageOfBaseLine"]))
    return data

# Using labels suggested by TfL themselves
# https://techforum.tfl.gov.uk/t/data-drop-near-real-time-crowding-data-api/1916
def format(crowdedness):
    if crowdedness == None:
        return "Unknown", GREY, "?%"
    number = "{}%".format(int(100 * crowdedness))
    if crowdedness < QUIET_MAX:
        return "Quiet", GREEN, number
    if crowdedness < BUSY_MAX:
        return "Busy", ORANGE, number
    return "Very busy", RED, number

def main(config):
    station_name, naptan_id = station_config(config.get("station"))

    # Find out how busy things currently are.
    pct_peak_crowdedness = get_live_crowdedness(naptan_id, config)

    # Pick a colour and phrase to convey status.
    status, status_colour, status_number = format(pct_peak_crowdedness)

    # Show where we are in the graph.
    now = time.now().in_location("Europe/London")
    pct_of_day = ((MINUTES_PER_HOUR * now.hour) + now.minute) / float(MINUTES_PER_DAY)
    now_indicator = int(pct_of_day * GRAPH_WIDTH)

    # Get the data to fill the graph of typical busyness.
    typical_crowdedness = get_typical_crowdedness(naptan_id, now, config)

    return render.Root(
        max_age = 300,  # Data updated every 5 mins
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Box(
                width = CONTAINER_WIDTH,
                height = CONTAINER_HEIGHT,
                child = render.Column(
                    children = [
                        # Station name
                        render.Marquee(
                            width = CONTAINER_WIDTH,
                            scroll_direction = "horizontal",
                            align = "center",
                            child = render.Text(station_name),
                        ),
                        # Current crowdedness
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Text(status, color = status_colour),
                                render.Text(status_number, color = status_colour),
                            ],
                        ),
                        # Typical crowdedness for this day of the week
                        render.Stack(
                            children = [
                                render.Plot(
                                    data = typical_crowdedness,
                                    width = GRAPH_WIDTH,
                                    height = GRAPH_HEIGHT,
                                    color = WHITE,
                                    x_lim = (0, HOURS_PER_DAY),
                                    y_lim = (0, 1),
                                    fill = True,
                                ),
                                # Current time of day
                                render.Padding(
                                    pad = (now_indicator, 0, 0, 0),
                                    child = render.Box(
                                        height = GRAPH_HEIGHT,
                                        width = 1,
                                        color = status_colour,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "tfl_app_key",
                name = "TfL App Key",
                desc = "Your Transport for London (TfL) App Key. See https://api.tfl.gov.uk/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "station",
                name = "TfL station ID",
                desc = "NaPTAN station ID; existing saved station selections still work.",
                icon = "trainSubway",
                default = DEFAULT_NAPTAN_ID,
            ),
        ],
    )
