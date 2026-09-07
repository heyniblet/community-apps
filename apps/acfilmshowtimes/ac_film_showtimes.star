"""
Applet: AC Film Showtimes
Summary: Movie showtimes
Description: Displays movie showtimes for American Cinematheque theaters in Los Angeles.
Author: Platt Thompson & Jim Cummings
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/camera_icon.png", CAMERA_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CAMERA_ICON = CAMERA_ICON_ASSET.readall()

# ---------------------------------------------------------------------------- #
#                                   CONSTANTS                                  #
# ---------------------------------------------------------------------------- #

CINEMATHEQUE_SHOWTIMES_URL = "https://www.americancinematheque.com/wp-json/wp/v2/algolia_get_events?environment=production_2026&startDate={start_time}&endDate={end_time}"

THEATER_CODES = {
    "los feliz 3": 102,
    "aero theatre": 54,
    "egyption theatre": 55,
    "other": 68,
}

THEATER_TITLES = {
    "los feliz 3": "Los Feliz 3",
    "aero theatre": "Aero Theatre",
    # Preserve the original saved option value while fixing its display label.
    "egyption theatre": "Egyptian Theatre",
}

# Showtimes will change color as they approach and gradually become more red.
# Once the time has passed, they will be grayed out.
# This also gives a more implicit understanding of AM and PM since the times are in twelve hour format
# and there's no room for an AM/PM suffix.
SHOWTIME_COLORS = {
    1: "#FF3333",
    2: "#FF4444",
    3: "#FF5555",
    4: "#FF6666",
    5: "#FF7777",
    6: "#FF8888",
    7: "#FF9999",
    8: "#FFAAAA",
    9: "#FFBBBB",
    10: "#FFCCCC",
    11: "#FFDDDD",
    12: "#FFEEEE",
    13: "#FFFFFF",
    14: "#FFFFFF",
    15: "#FFFFFF",
    16: "#FFFFFF",
    17: "#FFFFFF",
    18: "#FFFFFF",
    19: "#FFFFFF",
    20: "#FFFFFF",
    21: "#FFFFFF",
    22: "#FFFFFF",
    23: "#FFFFFF",
    24: "#FFFFFF",
}

DAY_IN_SECONDS = 86400
HOUR_IN_SECONDS = 3600
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_HITS = 500
MAX_TITLE_LENGTH = 240

# ---------------------------------------------------------------------------- #
#                                    HELPERS                                   #
# ---------------------------------------------------------------------------- #

def get_showtime_color(movie_start_time, current_time):
    minutes_until_movie = showtime_minutes(movie_start_time) - current_time.hour * 60 - current_time.minute
    if minutes_until_movie < 0:
        return "#222222"
    hours_until_movie = (minutes_until_movie + 59) // 60
    return SHOWTIME_COLORS.get(hours_until_movie, "#222222")

def showtime_minutes(value):
    parts = value.split(" ")
    if len(parts) != 2 or parts[1] not in ["AM", "PM"] or ":" not in parts[0]:
        return -1
    clock = parts[0].split(":", 1)
    if len(clock) != 2 or not clock[0].isdigit() or not clock[1].isdigit():
        return -1
    hour = int(clock[0])
    minute = int(clock[1])
    if hour < 1 or hour > 12 or minute > 59:
        return -1
    return (hour % 12 + (12 if parts[1] == "PM" else 0)) * 60 + minute

def calculate_time_query_params(current_time, timezone):
    beginning = time.time(
        year = current_time.year,
        month = current_time.month,
        day = current_time.day,
        location = timezone,
    ).unix
    return [beginning, beginning + DAY_IN_SECONDS - 1]

def show_error_fetching_data(message = "WE CAN'T CONNECT TO"):
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            child = render.Image(src = CAMERA_ICON),
                            pad = 1,
                        ),
                        render.Column(
                            children = [
                                render.Text("Sorry -", font = "tb-8", color = "#FF2222"),
                                render.Text(message, font = "tom-thumb", color = "#FF2222"),
                                render.Text("American", font = "tom-thumb", color = "#FF2222"),
                            ],
                            cross_align = "end",
                        ),
                    ],
                ),
                render.Padding(
                    child = render.Text("Cinematheque :(", font = "tom-thumb", color = "#FF2222"),
                    pad = (3, 0, 0, 0),
                ),
            ],
        ),
    )

# ---------------------------------------------------------------------------- #
#                                     MAIN                                     #
# ---------------------------------------------------------------------------- #

def main(config):
    local_theater = config.get("theater") or "Los Feliz 3"
    theater_key = local_theater.lower() if type(local_theater) == "string" else ""
    if theater_key not in THEATER_CODES:
        theater_key = "los feliz 3"
    local_theater_code = THEATER_CODES[theater_key]

    timezone = config.get("timezone") or config.get("$tz") or "America/Los_Angeles"
    if not time.is_valid_timezone(timezone):
        timezone = "America/Los_Angeles"
    current_time = time.now().in_location(timezone)

    beginning_of_current_day_unix, end_of_current_day_unix = calculate_time_query_params(current_time, timezone)

    showtimes_url = CINEMATHEQUE_SHOWTIMES_URL.format(
        start_time = str(beginning_of_current_day_unix),
        end_time = str(end_of_current_day_unix),
    )

    res = http.get(showtimes_url, ttl_seconds = HOUR_IN_SECONDS)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return show_error_fetching_data()
    data = json.decode(body, None)
    hits = data.get("hits") if type(data) == "dict" else None
    if type(hits) != "list" or len(hits) > MAX_HITS:
        return show_error_fetching_data("BAD SHOWTIME DATA")

    # Exclude showtimes from other AC theaters as well as those with incomplete data
    today = current_time.format("20060102")
    movie_list = []
    for movie in hits:
        if type(movie) != "dict":
            continue
        title = movie.get("title")
        showtime = movie.get("event_start_time")
        locations = movie.get("event_location")
        if (
            type(title) == "string" and title and len(title) <= MAX_TITLE_LENGTH and
            type(showtime) == "string" and len(showtime) <= 8 and showtime_minutes(showtime) >= 0 and
            type(locations) == "list" and local_theater_code in locations and
            str(movie.get("event_start_date", "")) == today
        ):
            movie_list.append(movie)

    # Sort movie list by showtime and truncate (the device can only display four showtimes before running out of screen space)
    movie_list = sorted(movie_list, key = lambda movie: showtime_minutes(movie["event_start_time"]))[:4]

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "end",
                            children = [
                                render.Marquee(
                                    width = 45,
                                    child = render.Text(movie["title"], font = "tom-thumb", color = "#89ACD4"),
                                    offset_start = 0,
                                    offset_end = 0,
                                    align = "start",
                                )
                                for movie in movie_list
                            ],
                        ),
                        render.Column(
                            main_align = "end",
                            cross_align = "end",
                            children = [
                                render.Text(
                                    # time.parse_time(movie["event_start_time"], "15:04:05").format("3:04"),
                                    time.parse_time(movie["event_start_time"], "3:04 PM").format("3:04"),
                                    font = "tom-thumb",
                                    color = get_showtime_color(movie["event_start_time"], current_time),
                                )
                                for movie in movie_list
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "end",
                            expanded = True,
                            children = [
                                render.Padding(
                                    child = render.Text(THEATER_TITLES[theater_key].upper(), font = "CG-pixel-4x5-mono", color = "#FFDD48"),
                                    pad = 1,
                                    color = "#222",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Los Feliz 3",
            value = "Los Feliz 3",
        ),
        schema.Option(
            display = "Aero Theatre",
            value = "Aero Theatre",
        ),
        schema.Option(
            display = "Egyption Theatre",
            value = "Egyption Theatre",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theater",
                name = "Theater",
                desc = "Theater for which to display showtimes.",
                icon = "film",
                default = options[0].value,
                options = options,
            ),
        ],
    )
