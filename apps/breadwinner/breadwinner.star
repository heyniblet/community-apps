load("encoding/json.star", "json")

# breadwinner.star
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_RESPONSE_BYTES = 512 * 1024
MAX_POINTS = 64

def error(message):
    return render.Root(child = render.Text(message, font = "tom-thumb"))

def path_part(value):
    value = str(value or "").strip()
    for char in value.elems():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return ""
    return value if len(value) <= 80 else ""

def get_height_color(height):
    # Return color based on height thresholds
    if height < 1.25:
        return "#ff0000"  # red
    elif height <= 2.0:
        return "#ffff00"  # yellow
    return "#00ff00"  # green

def main(config):
    # Get user and starter from config
    user_id = path_part(config.get("user_id", "fred"))
    starter_id = path_part(config.get("starter_id", "breadberry"))
    if not user_id or not starter_id:
        return error("Invalid Breadwinner ID")

    # Fetch data from Breadwinner API
    url = "https://breadwinner.life/api/v3/%s/starters/%s/tidbyt" % (user_id, starter_id)

    res = http.get(url)
    body = res.body()
    data = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "dict":
        return error("Breadwinner unavailable")

    if "error" in data:
        return error("No starter data")

    # Create height graph points and get max height
    raw_points = data.get("points", [])
    heights = [p["height"] for p in raw_points[-MAX_POINTS:] if type(p) == "dict" and type(p.get("height")) in ["int", "float"]]
    max_height = max(heights) if heights else 0

    if heights:
        min_height = min(heights)

        # Scale heights to fit in 16 pixels to leave room for text and separator
        height_range = max_height - min_height
        scaled_heights = [int(((h - min_height) / height_range) * 16) if height_range else 8 for h in heights]
    else:
        scaled_heights = []

    # Create graph points
    points = []
    for i, height in enumerate(scaled_heights):
        points.append((i, height))

    # Convert and format time
    if not data.get("fed_at") or not data.get("starter_name") or type(data.get("temperature")) not in ["int", "float"]:
        return error("Incomplete starter data")
    fed_time = time.parse_time(data["fed_at"])
    now = time.now().in_location("America/New_York")
    relative_time = humanize.relative_time(fed_time, now)

    # Format temperature and max height
    temp_text = "%s°" % (math.round(data["temperature"] * 10) / 10)

    # Format max height to 2 decimal places using math.round
    max_height_text = "%sx" % (math.round(max_height * 100) / 100)

    # Get color for max height display
    height_color = get_height_color(max_height)

    # Combine name (capitalized) and feeding time for marquee
    status_text = "%s Fed %s ago" % (data["starter_name"].upper(), relative_time.strip())

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                # Graph section with temperature and max height overlay
                render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            children = [
                                # Temperature and max height display at top
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 0, 0),
                                            child = render.Text(
                                                content = temp_text,
                                                font = "tom-thumb",
                                            ),
                                        ),
                                        render.Padding(
                                            pad = (0, 0, 2, 0),
                                            child = render.Text(
                                                content = max_height_text,
                                                font = "tom-thumb",
                                                color = height_color,
                                            ),
                                        ),
                                    ],
                                ),

                                # Graph below the separator
                                render.Box(
                                    height = 16,
                                    child = render.Plot(
                                        data = points,
                                        width = 64,
                                        height = 16,
                                        color = "#00ff00",
                                    ),
                                ),
                            ],
                        ),
                        # Scrolling status bar at bottom
                        render.Box(
                            height = 8,
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = status_text,
                                    font = "tom-thumb",
                                    color = "#FFA500",
                                ),
                                offset_start = 32,
                                offset_end = 32,
                            ),
                        ),
                    ],
                ),
                # Scrolling status bar
                render.Box(
                    height = 8,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = status_text,
                            font = "tom-thumb",
                        ),
                        offset_start = 32,
                        offset_end = 32,
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
                id = "starter_id",
                name = "Starter Name",
                desc = "Name of the Breadwinner starter.",
                icon = "gear",
                default = "breadberry",
            ),
            schema.Text(
                id = "user_id",
                name = "Breadwinner ID",
                desc = "Breadwinner User ID.",
                icon = "gear",
                default = "fred",
            ),
        ],
    )
