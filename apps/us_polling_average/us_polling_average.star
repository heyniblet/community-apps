# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: US PollingAverage
Summary: Election polls from 538
Description: Shows archived 2024 polling averages from FiveThirtyEight
Author: jwoglom
"""

load("animation.star", "animation")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CSV_URL = "https://cdn.jsdelivr.net/gh/fivethirtyeight/data@e6bbbb2d35310b5c63c2995a0d03d582d0c7b2e6/polls/2024-averages/presidential_general_averages_2024-09-12_uncorrected.csv"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024

POLL_TYPES = [
    "president-general",
]

POLL_STATES = [
    "national",
    "alabama",
    "alaska",
    "american-samoa",
    "arizona",
    "arkansas",
    "california",
    "colorado",
    "connecticut",
    "delaware",
    "district-of-columbia",
    "florida",
    "georgia",
    "guam",
    "hawaii",
    "idaho",
    "illinois",
    "indiana",
    "iowa",
    "kansas",
    "kentucky",
    "louisiana",
    "maine",
    "maryland",
    "massachusetts",
    "michigan",
    "minnesota",
    "mississippi",
    "missouri",
    "montana",
    "nebraska",
    "nevada",
    "new-hampshire",
    "new-jersey",
    "new-mexico",
    "new-york",
    "north-carolina",
    "north-dakota",
    "northern-mariana-islands",
    "ohio",
    "oklahoma",
    "oregon",
    "pennsylvania",
    "puerto-rico",
    "rhode-island",
    "south-carolina",
    "south-dakota",
    "tennessee",
    "texas",
    "us-virgin-islands",
    "utah",
    "vermont",
    "virginia",
    "washington",
    "west-virginia",
    "wisconsin",
    "wyoming",
]

POLL_CYCLES = [
    "2024",
]

FONT = "tom-thumb"

PERIOD = "period"
DEFAULT_PERIOD = "30"

POLL_TYPE = "poll_type"
DEFAULT_POLL_TYPE = "president-general"

POLL_STATE = "poll_state"
DEFAULT_POLL_STATE = "national"

POLL_CYCLE = "poll_cycle"
DEFAULT_POLL_CYCLE = "2024"

PARTY_COLORS = {
    "REP": "#eb4034",
    "DEM": "#1018eb",
    "OTHER": "#e7eb10",
}

def main(config):
    period = config.get(PERIOD, DEFAULT_PERIOD)
    poll_type = config.get(POLL_TYPE, DEFAULT_POLL_TYPE)
    poll_state = config.get(POLL_STATE, DEFAULT_POLL_STATE)
    poll_cycle = config.get(POLL_CYCLE, DEFAULT_POLL_CYCLE)

    results = http.get(CSV_URL, ttl_seconds = 86400)
    if results.status_code != 200 or len(results.body()) > MAX_RESPONSE_BYTES:
        return render.Root(
            child = render.WrappedText("Error loading " + poll_type + " " + poll_state + " " + poll_cycle),
        )

    data = postprocess(csv.read_all(results.body()), poll_state, poll_cycle)
    if "Harris" not in data or "Trump" not in data:
        return render.Root(child = render.WrappedText("No archived polling average"))

    latest_dem = [data[c][0] for c in data.keys() if data[c][0]["party"] == "DEM"][0]
    latest_rep = [data[c][0] for c in data.keys() if data[c][0]["party"] == "REP"][0]
    dem_leading_rep = latest_dem["pct_estimate"] >= latest_rep["pct_estimate"]

    def print_num(num):
        return "%s" % (math.round(10 * num) / 10) + "%"

    WIDTH = 26

    row = render.Stack(
        children = [
            render.Row(
                children = [
                    render.Box(
                        width = 63,
                        height = 32,
                        color = "#000",
                    ),
                    render.Box(
                        width = WIDTH,
                        height = 32,
                        padding = 0,
                        child =
                            render.Column(
                                main_align = "start",
                                children = [
                                    render.Text(latest_dem["candidate"], font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text(print_num(latest_dem["pct_estimate"]), font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text(print_num(latest_rep["pct_estimate"]), font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text(latest_rep["candidate"], font = FONT, color = PARTY_COLORS["REP"]),
                                ] if dem_leading_rep else [
                                    render.Text(latest_rep["candidate"], font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text(print_num(latest_rep["pct_estimate"]), font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text(print_num(latest_dem["pct_estimate"]), font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text(latest_dem["candidate"], font = FONT, color = PARTY_COLORS["DEM"]),
                                ],
                            ),
                    ),
                ],
            ),
            render.Stack(
                children = [
                    draw_chart(data, int(period)),
                    draw_title(poll_state, poll_cycle),
                ],
            ),
        ],
    )

    return render.Root(
        child = animation.Transformation(
            child = row,
            duration = 100,
            delay = 50,
            origin = animation.Origin(0, 0),
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(0, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(-1 * WIDTH, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-1 * WIDTH, 0)],
                ),
            ],
        ),
    )

def postprocess(rows, poll_state, poll_cycle):
    candidates = {}
    for row in rows[1:]:
        if len(row) < 9 or row[4] != poll_cycle or row[3].lower().replace(" ", "-") != poll_state:
            continue
        candidate = row[0]
        if candidate not in ["Harris", "Trump"] or not row[6]:
            continue
        if candidate not in candidates:
            candidates[candidate] = []
        candidates[candidate].append({
            "candidate": candidate,
            "date_parsed": time.parse_time(row[1], "2006-01-02"),
            "party": row[5],
            "pct_estimate": float(row[6]),
        })

    return candidates

def draw_chart(data, days):
    return render.Stack(
        children = [
            draw_series(data[candidate], data[candidate][0]["party"], days)
            for candidate in data.keys()
        ],
    )

# Plot the polling average for a given party over the given time period
def draw_series(data, party, days):
    newest_date = data[0]["date_parsed"]
    series = sorted([((row["date_parsed"] - newest_date) // (24 * time.hour), row) for row in data if row], reverse = True)

    newest_day = series[0][0]
    oldest_day = max(series[-1][0], -days)
    days = newest_day - oldest_day
    days_per_pixel = max(1, days // 32)
    newest = newest_day // days_per_pixel
    oldest = oldest_day // days_per_pixel

    polls_by_pixel = {}
    for day, poll in series:
        pixel = day // days_per_pixel
        if pixel in polls_by_pixel:
            polls_by_pixel[pixel].append(poll["pct_estimate"])
            continue
        polls_by_pixel[pixel] = [poll["pct_estimate"]]
    averages = [(pixel, sum(polls) / len(polls)) for pixel, polls in polls_by_pixel.items()]

    return render.Plot(
        data = averages,
        chart_type = "line",
        width = 64,
        height = 32,
        x_lim = (oldest, newest),
        y_lim = (40, 55),
        color = PARTY_COLORS.get(party, PARTY_COLORS["OTHER"]),
    )

def pretty_fmt(txt):
    p = " ".join([i[0].upper() + i[1:] for i in txt.split("-")])
    p = p.replace(" General", "")
    return p

def draw_title(poll_state, poll_cycle):
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Marquee(
            width = 64,
            child = render.Row(
                children = [
                    render.Text(
                        content = "{poll_cycle} 538 archive ({poll_state})  ".format(
                            poll_cycle = poll_cycle,
                            poll_state = pretty_fmt(poll_state),
                        ),
                        font = FONT,
                    ),
                ] * 3,
            ),
            offset_start = 8,
        ),
    )

def sum(list):
    total = 0
    for item in list:
        total += item
    return total

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = PERIOD,
                name = "Period",
                desc = "Show polls from the most recent",
                icon = "calendar",
                default = "30",
                options = [
                    schema.Option(
                        display = "One week",
                        value = "7",
                    ),
                    schema.Option(
                        display = "Two weeks",
                        value = "14",
                    ),
                    schema.Option(
                        display = "30 days",
                        value = "30",
                    ),
                    schema.Option(
                        display = "90 days",
                        value = "90",
                    ),
                    schema.Option(
                        display = "Full archive",
                        value = "365",
                    ),
                ],
            ),
            schema.Dropdown(
                id = POLL_TYPE,
                name = "Poll Type",
                desc = "Type for which polls are shown",
                icon = "pencil",
                default = DEFAULT_POLL_TYPE,
                options = [
                    schema.Option(
                        display = pretty_fmt(item),
                        value = item,
                    )
                    for item in POLL_TYPES
                ],
            ),
            schema.Dropdown(
                id = POLL_STATE,
                name = "Poll State",
                desc = "State for which polls are shown",
                icon = "flagUsa",
                default = DEFAULT_POLL_STATE,
                options = [
                    schema.Option(
                        display = pretty_fmt(item),
                        value = item,
                    )
                    for item in POLL_STATES
                ],
            ),
            schema.Dropdown(
                id = POLL_CYCLE,
                name = "Poll Cycle",
                desc = "Election cycle",
                icon = "calendarDays",
                default = DEFAULT_POLL_CYCLE,
                options = [
                    schema.Option(
                        display = item,
                        value = item,
                    )
                    for item in POLL_CYCLES
                ],
            ),
        ],
    )
