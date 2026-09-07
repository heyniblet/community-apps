"""
Applet: Prayer Times
Summary: Islamic Prayer Time Display
Description: Displays the prayer times for today's date and also shows the remaining time till the next prayer based on the user's location.
Author: EslamMoh
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/moon_icon.png", MOON_ICON_ASSET = "file")
load("images/sun_icon.png", SUN_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MOON_ICON = MOON_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()

# Adhan prayer API URL
PRAYER_TIME_BASE_URL = "https://api.aladhan.com/v1/timings/"

# Load Moon icon from base64 encoded data

# Load Sun icon from base64 encoded data

# Default location and timezone data for prayer
DEFAULT_LOCATION = """
{
    "timezone": "Asia/Riyadh",
    "lat": "24.7136",
	"lng": "46.6753"
}
"""

# Default method of calculating prayer time
DEFAULT_METHOD = "4"

# Mapping current prayer to the matching icon
PRAYER_ICON = {
    "sunrise": SUN_ICON,
    "duhr": SUN_ICON,
    "asr": SUN_ICON,
    "maghrib": MOON_ICON,
    "isha": MOON_ICON,
    "fajr": MOON_ICON,
}

# Cache prayer times request for one day.
TTL_CACHE = 86400
MAX_RESPONSE_BYTES = 65536
METHODS = ["0", "1", "2", "3", "4", "5", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"]

# Fetch location configs
def get_location(config):
    location = config.get("location", DEFAULT_LOCATION)
    location = location if type(location) == "dict" else json.decode(location, None)
    if type(location) != "dict" or type(location.get("timezone")) != "string":
        return None
    lat = parse_coordinate(location.get("lat"), -90, 90)
    lng = parse_coordinate(location.get("lng"), -180, 180)
    if lat == None or lng == None:
        return None
    return {"timezone": location["timezone"], "lat": lat, "lng": lng}

def parse_coordinate(value, minimum, maximum):
    value = str(value).strip()
    if not value or len(value) > 24:
        return None
    digits = 0
    decimal_points = 0
    for index in range(len(value)):
        character = value[index]
        if character.isdigit():
            digits += 1
        elif character == "." and decimal_points == 0:
            decimal_points += 1
        elif character in ("-", "+") and index == 0:
            pass
        else:
            return None
    if digits == 0:
        return None
    number = float(value)
    return str(number) if number >= minimum and number <= maximum else None

# Fetch method of calculation for prayer time config
def get_method(config):
    method = config.get("method", DEFAULT_METHOD)
    return method if method in METHODS else DEFAULT_METHOD

def main(config):
    location = get_location(config)
    if not location:
        return render_message("Choose a valid location")
    method = get_method(config)
    now = time.now().in_location(location["timezone"])
    date = now.format("2-01-2006")

    # Fetch today prayer times
    prayers = get_prayers(date, location, method)
    if not prayers:
        return render_message("Prayer times unavailable")

    # Calculate the next prayer based on the current time
    next_prayer = next_prayer_time(prayers, now, location, method)

    # Get the current prayer name
    current_prayer = current_prayer_name(next_prayer["prayer"])

    return render.Root(
        delay = 2000,
        max_age = 60,
        child = render.Column(
            children = [
                render.Sequence(children = [
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (7, 17, 0, 0),
                                        child = render.Box(
                                            width = 17,
                                            height = 7,
                                            color = current_prayer_color("fajr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "FAJR",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 15,
                                                color = current_prayer_color("fajr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (5, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Fajr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (30, 17, 0, 0),
                                        child = render.Box(
                                            width = 29,
                                            height = 7,
                                            color = current_prayer_color("sunrise", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "sunrise",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 27,
                                                color = current_prayer_color("sunrise", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (34, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Sunrise"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(0),
                    ),
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (7, 17, 0, 0),
                                        child = render.Box(
                                            width = 17,
                                            height = 7,
                                            color = current_prayer_color("duhr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "Duhr",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 15,
                                                color = current_prayer_color("duhr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (5, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Dhuhr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (38, 17, 0, 0),
                                        child = render.Box(
                                            width = 13,
                                            height = 7,
                                            color = current_prayer_color("asr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "Asr",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 11,
                                                color = current_prayer_color("asr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (34, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Asr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(64),
                    ),
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (5, 17, 0, 0),
                                        child = render.Box(
                                            width = 29,
                                            height = 7,
                                            color = current_prayer_color("maghrib", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "MAGHRIB",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 26,
                                                color = current_prayer_color("maghrib", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (8, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Maghrib"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (42, 17, 0, 0),
                                        child = render.Box(
                                            width = 16,
                                            height = 7,
                                            color = current_prayer_color("isha", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "ISHA",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 16,
                                                color = current_prayer_color("isha", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (40, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Isha"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(64),
                    ),
                ]),
            ],
        ),
    )

def render_time_icon(icon):
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Image(
            src = icon,
        ),
    )

def render_line_separator():
    return render.Padding(
        pad = (0, 16, 0, 0),
        child = render.Box(
            width = 64,
            height = 1,
            color = "#f00",
        ),
    )

def render_next_prayer_time(next_prayer):
    return {
        "name": render.Padding(
            pad = (20, 1, 0, 0),
            child = render.Box(
                width = 28,
                height = 7,
                child = render.WrappedText(
                    content = next_prayer["prayer"],
                    font = "CG-pixel-3x5-mono",
                    color = "#228B22",
                    align = "left",
                ),
            ),
        ),
        "time": render.Padding(
            pad = (12, 5, 0, 0),
            child = render.Box(
                width = 50,
                height = 15,
                child = render.WrappedText(
                    content = next_prayer["time"],
                    font = "CG-pixel-3x5-mono",
                    linespacing = 1,
                    align = "left",
                ),
            ),
        ),
    }

# Format prayer times in DateTime format
def formatted_prayer_times(prayers, now, timezone):
    return {
        "fajr": format_time(prayers["Fajr"], now, timezone),
        "sunrise": format_time(prayers["Sunrise"], now, timezone),
        "duhr": format_time(prayers["Dhuhr"], now, timezone),
        "asr": format_time(prayers["Asr"], now, timezone),
        "maghrib": format_time(prayers["Maghrib"], now, timezone),
        "isha": format_time(prayers["Isha"], now, timezone),
    }

# Format time from "HH:MM" to DateTime format
def format_time(prayer, now, timezone):
    p = prayer.partition(":")

    return time.time(year = now.year, month = now.month, day = now.day, hour = int(p[0]), minute = int(p[2]), second = 0o0, location = timezone)

# Calculate next prayer time based on the current time
def next_prayer_time(prayers, now, location, method):
    pt = formatted_prayer_times(prayers, now, location["timezone"])

    if now < pt["fajr"]:
        return {"prayer": "fajr", "time": time_till_next_prayer(now, pt["fajr"])}

    elif now < pt["sunrise"]:
        return {"prayer": "sunrise", "time": time_till_next_prayer(now, pt["sunrise"])}

    elif now < pt["duhr"]:
        return {"prayer": "duhr", "time": time_till_next_prayer(now, pt["duhr"])}

    elif now < pt["asr"]:
        return {"prayer": "asr", "time": time_till_next_prayer(now, pt["asr"])}

    elif now < pt["maghrib"]:
        return {"prayer": "maghrib", "time": time_till_next_prayer(now, pt["maghrib"])}

    elif now < pt["isha"]:
        return {"prayer": "isha", "time": time_till_next_prayer(now, pt["isha"])}

    else:
        tomorrow_fajr = get_tomorrow_fajr(now, location, method)
        if tomorrow_fajr == None:
            tomorrow_fajr = pt["fajr"] + 24 * time.hour

        return {"prayer": "fajr", "time": time_till_next_prayer(now, tomorrow_fajr)}

# Get Fajr prayer time for tomorrow date.
def get_tomorrow_fajr(now, location, method):
    tomorrow = now + 24 * time.hour
    tomorrow_date = tomorrow.format("2-01-2006")
    tomorrow_prayers = get_prayers(tomorrow_date, location, method)
    return format_time(tomorrow_prayers["Fajr"], tomorrow, location["timezone"]) if tomorrow_prayers else None

# Send API request to get prayer times according to location and date.
def get_prayers(date, location, method):
    url = PRAYER_TIME_BASE_URL + date + "?latitude=%s" % humanize.url_encode(location["lat"]) + "&longitude=%s" % humanize.url_encode(location["lng"]) + "&method=%s" % humanize.url_encode(method)
    rep = http.get(url, ttl_seconds = TTL_CACHE)
    body = rep.body()

    if rep.status_code != 200 or len(body) > MAX_RESPONSE_BYTES or not body.startswith("{") or not body.endswith("}"):
        return None

    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Prayer Times API.")

    response = json.decode(body, None)
    data = response.get("data", {}) if type(response) == "dict" else {}
    timings = data.get("timings", {}) if type(data) == "dict" else {}
    if type(timings) != "dict":
        return None
    normalized = {}
    for prayer in ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]:
        value = timings.get(prayer)
        value = value[:5] if type(value) == "string" else ""
        parts = value.split(":")
        if len(parts) != 2 or len(parts[0]) != 2 or len(parts[1]) != 2 or not parts[0].isdigit() or not parts[1].isdigit() or int(parts[0]) > 23 or int(parts[1]) > 59:
            return None
        normalized[prayer] = value
    return normalized

def render_message(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("PRAYER TIMES", font = "tb-8"),
                render.WrappedText(message, align = "center"),
            ],
        ),
    )

# Render time icon, next prayer times data and separation line.
def render_meta_data(icon, next_prayer):
    return [
        render_time_icon(icon),
        render_line_separator(),
        render_next_prayer_time(next_prayer)["name"],
        render_next_prayer_time(next_prayer)["time"],
    ]

# Animate prayers frames based on x axis input.
def keyframes(x):
    return [
        animation.Keyframe(
            percentage = 0.0,
            transforms = [animation.Translate(x, 0)],
            curve = "linear",
        ),
        animation.Keyframe(
            percentage = 1.0,
            transforms = [animation.Translate(-64, 0)],
            curve = "linear",
        ),
    ]

# Pick the highlight color for the current prayer.
def current_prayer_color(prayer_name, current_prayer):
    if current_prayer == prayer_name:
        return {"box_color": "#F4C430", "font_color": "#000000"}
    else:
        return {"box_color": "#000000", "font_color": "#FFFFFF"}

# Calculate the remaining time till the next prayer time.
def time_till_next_prayer(now, nxt_pryr_time):
    remaining_time = nxt_pryr_time - now
    hours = int(remaining_time.hours)
    mins = int(remaining_time.minutes) % 60

    return "%shrs %smins" % (hours, mins)

# Get the current prayer time based on the next prayer time name.
def current_prayer_name(next_prayer):
    return {
        "sunrise": "fajr",
        "duhr": "sunrise",
        "asr": "duhr",
        "maghrib": "asr",
        "isha": "maghrib",
        "fajr": "isha",
    }[next_prayer]

def get_schema():
    method_options = [
        schema.Option(
            display = "Shia Ithna-Ansari",
            value = "0",
        ),
        schema.Option(
            display = "University of Islamic Sciences, Karachi",
            value = "1",
        ),
        schema.Option(
            display = "Islamic Society of North America",
            value = "2",
        ),
        schema.Option(
            display = "Muslim World League",
            value = "3",
        ),
        schema.Option(
            display = "Umm Al-Qura University, Makkah",
            value = "4",
        ),
        schema.Option(
            display = "Egyptian General Authority of Survey",
            value = "5",
        ),
        schema.Option(
            display = "Institute of Geophysics, University of Tehran",
            value = "7",
        ),
        schema.Option(
            display = "Gulf Region",
            value = "8",
        ),
        schema.Option(
            display = "Kuwait",
            value = "9",
        ),
        schema.Option(
            display = "Qatar",
            value = "10",
        ),
        schema.Option(
            display = "Majlis Ugama Islam Singapura, Singapore",
            value = "11",
        ),
        schema.Option(
            display = "Union Organization islamic de France",
            value = "12",
        ),
        schema.Option(
            display = "Diyanet İşleri Başkanlığı, Turkey",
            value = "13",
        ),
        schema.Option(
            display = "Spiritual Administration of Muslims of Russia",
            value = "14",
        ),
        schema.Option(
            display = "Moonsighting Committee Worldwide (also requires shafaq parameter)",
            value = "15",
        ),
        schema.Option(
            display = "Dubai (unofficial)",
            value = "16",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display prayer times",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "method",
                name = "Prayer Calculation Method",
                desc = "A prayer times calculation method. Methods identify various schools of thought about how to compute the timings. If not specified, it defaults to Umm Al-Qura University, Makkah",
                icon = "mosque",
                default = "4",
                options = method_options,
            ),
        ],
    )
