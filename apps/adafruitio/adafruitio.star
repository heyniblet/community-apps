"""
Applet: AdafruitIO
Summary: Display AdafruitIO Feed
Description: Show value or graph of various Adafruit IO Feeds.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

TTL_SECONDS = 300  # 5 minutes
DEFAULT_USER = ""
DEFAULT_KEY = ""
DEFAULT_FEED_ID = ""
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_POINTS = 120
MAX_LABEL_LENGTH = 120
MAX_PATH_PART_LENGTH = 128
PATH_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_."
YELLOW = "#ffff00"  # Firefly palette color
GREEN = "#ADFF2F"  # Firefly palette color
ORANGE = "#FF4500"  # Firefly palette color
BLUE = "#0000FF"  # Firefly palette color
RED = "#FF0000"

def main(config):
    username = config.str("username", DEFAULT_USER)
    key = config.str("key", DEFAULT_KEY)
    feed_id = config.str("feed_id", DEFAULT_FEED_ID)
    hours_value = str(config.get("hours_history", "24"))
    hours = int(hours_value) if hours_value.isdigit() else 24
    hours = min(max(hours, 1), 720)
    feed = get_feed(username, key, feed_id, hours)

    # Parse value range filters
    feed_value_range = parse_range(config.get("feed_value_range", None))
    feed2_value_range = parse_range(config.get("feed2_value_range", None))

    # check for feed2
    feed2 = None
    feed2_id = config.get("feed2_id", None)
    if feed2_id:
        feed2 = get_feed(username, key, feed2_id, hours)

    if "error" in feed or (feed2 and "error" in feed2):  # if we have error key, then we display an error
        #debug_print("buoy_id: " + str(buoy_id))
        error_dict = dict()
        if ("error" in feed):
            error_dict = feed
        if (feed2 and "error" in feed2):
            error_dict = feed2
        error_string = error_dict.get("error", "Feed unavailable")
        error_message = error_string[:80]
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Text(
                            content = "AIO Error",
                            font = "tb-8",
                            color = RED,
                        ),
                        render.WrappedText(
                            content = error_message,
                            font = "tb-8",
                            color = ORANGE,
                        ),
                        # render.Text(
                        #     content = "not found",
                        #     color = ORANGE,
                        # ),
                    ],
                ),
            ),
        )

    else:
        #FEED
        # build the feed_graph
        feed_graph = None
        if config.bool("display_graph") and len(feed["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed["data"])):
                points.append((i, float(feed["data"][i][1])))
            y_lim = (None, None)
            limits = parse_range(config.get("y_min_max", None))
            if limits:
                y_lim = limits
            feed_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph_color", "#00c"),
                y_lim = y_lim,
            )

        # build feed2_graph
        feed2_graph = None
        if config.bool("display_graph2") and feed2 and len(feed2["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed2["data"])):
                points.append((i, float(feed2["data"][i][1])))
            y2_lim = (None, None)
            limits = parse_range(config.get("y2_min_max", None))
            if limits:
                y2_lim = limits
            feed2_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph2_color", "#00c"),
                y_lim = y2_lim,
            )

        # Check if feed values are in range - if not, return empty
        feed_value = float(feed["data"][-1][1])
        if not is_in_range(feed_value, feed_value_range):
            return []

        # Check if feed2 exists and is in range
        if feed2:
            feed2_value = float(feed2["data"][-1][1])
            if not is_in_range(feed2_value, feed2_value_range):
                return []

            # Both feeds in range - show both values
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(feed_value, 1)) + config.get("feed_units", "") + " ",
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                    render.Text(
                        content = str(round(feed2_value, 1)) + config.get("feed2_units", ""),
                        font = "6x13",
                        color = config.str("feed2_color", None) or BLUE,
                    ),
                ],
            )
        else:
            # Only feed1 and it's in range
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(feed_value, 2)) + config.get("feed_units", ""),
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                ],
            )

        return render.Root(
            child = render.Stack(
                children = [
                    feed_graph,
                    feed2_graph,
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_around",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    children = [
                                        render.WrappedText(
                                            content = (config.str("feed_name", None) or feed["feed"]["name"])[:MAX_LABEL_LENGTH],
                                            font = "tb-8",
                                            color = config.str("feed_color", None) or GREEN,
                                        ),
                                    ],
                                ),
                                data_line,
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_feed(username, key, feed_id, hours):
    if not username or not key or not feed_id:
        return {"error": "Enter username, key, and feed"}
    if not valid_path_part(username) or not valid_path_part(feed_id):
        return {"error": "Invalid username or feed"}

    # load the feed from adafruit io
    # curl -H "X-AIO-Key: {io_key}" 'https://io.adafruit.com/api/v2/{username}/feeds/{feed_key}/data/chart?hours=1'

    url = "https://io.adafruit.com/api/v2/%s/feeds/%s/data/chart?hours=%s" % (username, feed_id, hours)
    res = http.get(url, headers = {"X-AIO-Key": key}, ttl_seconds = TTL_SECONDS)
    body = res.body()
    feed = json.decode(body, None) if len(body) <= MAX_RESPONSE_BYTES else None
    if res.status_code != 200 or type(feed) != "dict":
        return {"error": "Adafruit IO request failed"}
    if "data" in feed and type(feed["data"]) == "list" and len(feed["data"]) == 0:
        url = "https://io.adafruit.com/api/v2/%s/feeds/%s/data?limit=1" % (username, feed_id)
        res = http.get(url, headers = {"X-AIO-Key": key}, ttl_seconds = TTL_SECONDS)
        body = res.body()
        dfeed = json.decode(body, None) if len(body) <= MAX_RESPONSE_BYTES else None
        if res.status_code == 200 and type(dfeed) == "list" and len(dfeed) > 0 and type(dfeed[-1]) == "dict":
            feed["data"] = [["0", dfeed[-1].get("value")]]

    if not valid_feed(feed):
        return {"error": "Feed returned invalid data"}
    feed["data"] = feed["data"][-MAX_POINTS:]

    return feed

def valid_path_part(value):
    return type(value) == "string" and 0 < len(value) and len(value) <= MAX_PATH_PART_LENGTH and all([char in PATH_CHARS for char in value.codepoints()])

def valid_feed(feed):
    if type(feed.get("feed")) != "dict" or type(feed["feed"].get("name")) != "string" or type(feed.get("data")) != "list" or len(feed["data"]) == 0:
        return False
    for point in feed["data"][-MAX_POINTS:]:
        if type(point) != "list" or len(point) < 2 or not valid_number(point[1]):
            return False
    return True

def valid_number(value):
    text = str(value)
    if len(text) == 0 or len(text) > 32 or text.count(".") > 1 or text.count("-") > 1 or ("-" in text and not text.startswith("-")):
        return False
    return all([char in "0123456789.-" for char in text.codepoints()]) and any([char.isdigit() for char in text.codepoints()])

def parse_range(range_str):
    """Parse a min-max range string like '10-20' into a tuple (min, max).
    Returns None if range_str is empty or invalid."""
    if not range_str:
        return None
    separator = "," if "," in range_str else "-"
    parts = range_str.split(separator, 1)
    if len(parts) == 2 and valid_number(parts[0].strip()) and valid_number(parts[1].strip()):
        lower = float(parts[0].strip())
        upper = float(parts[1].strip())
        return (lower, upper) if lower <= upper else None
    return None

def is_in_range(value, range_tuple):
    """Check if a value is within the specified range.
    If range_tuple is None, always returns True (no filtering)."""
    if not range_tuple:
        return True
    min_val = range_tuple[0]
    max_val = range_tuple[1]
    return value >= min_val and value <= max_val

def get_schema():
    fields = []
    fields.append(
        schema.Text(
            id = "username",
            name = "Username",
            desc = "AIO username",
            icon = "user",
        ),
    )
    fields.append(
        schema.Text(
            id = "key",
            name = "AIO Key",
            desc = "AIO Acess Key",
            icon = "key",
            secret = True,
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_id",
            name = "Feed",
            desc = "AIO Feed",
            icon = "user",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed_color",
            name = "Color",
            desc = "Feed Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_name",
            name = "Feed Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )

    fields.append(
        schema.Text(
            id = "feed_units",
            name = "Feed Units",
            icon = "quoteRight",
            desc = "Feed height units preference",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_value_range",
            name = "Value Range Filter",
            icon = "filter",
            desc = "Only show app if in range (e.g., '10-20'). Leave blank to always show.",
            default = "",
        ),
    )
    fields.append(
        schema.Toggle(
            id = "display_graph",
            name = "Display Graph",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = True,
        ),
    )
    fields.append(
        schema.Color(
            id = "graph_color",
            name = "Graph Color",
            desc = "Graph Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )

    fields.append(
        schema.Text(
            id = "hours_history",
            name = "Graph history hours",
            desc = "",
            icon = "compress",
            default = "",
        ),
    )
    fields.append(
        schema.Text(
            id = "y_min_max",
            name = "Graph min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )

    # fields.append(
    #     schema.Text(
    #         id = "y_min",
    #         name = "Graph min",
    #         desc = "Scale the graph by setting a minimum. Leave blank to disable",
    #         icon = "compress",
    #         default = "",
    #     ),
    #)
    fields.append(
        schema.Text(
            id = "feed2_id",
            name = "Feed 2",
            desc = "AIO Feed",
            icon = "user",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed2_color",
            name = "Feed 2 Color",
            desc = "Feed Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_name",
            name = "Feed 2 Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_units",
            name = "Feed 2 Units",
            icon = "quoteRight",
            desc = "Feed height units preference",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_value_range",
            name = "Feed 2 Value Range Filter",
            icon = "filter",
            desc = "Only show app if in range (e.g., '10-20'). Leave blank to always show.",
            default = "",
        ),
    )
    fields.append(
        schema.Toggle(
            id = "display_graph2",
            name = "Show Graph 2",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = False,
        ),
    )
    fields.append(
        schema.Color(
            id = "graph2_color",
            name = "Graph 2 Color",
            desc = "Graph 2 Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "y2_min_max",
            name = "Graph 2 min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)
