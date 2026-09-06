"""
Applet: Grafana
Summary: Display Grafana Metrics
Description: Show value or graph of various Grafana metrics from your instance.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_GRAFANA_URL = ""
DEFAULT_KEY = ""
DEFAULT_INSTANCE = ""
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_POINTS = 1000
JSON_DUMMY_DATA = """{"status":"success","data":{"resultType":"matrix","result":[{"metric":{"__name__":"node_load1","instance":"default","job":"integrations/node_exporter"},"values":[[1763712213,"0.06"],[1763712228,"0.06"],[1763712243,"0.13"],[1763712258,"0.13"],[1763712273,"0.13"],[1763712288,"0.13"],[1763712303,"0.41"],[1763712318,"0.41"],[1763712333,"0.41"],[1763712348,"0.41"],[1763712363,"0.27"],[1763712378,"0.27"],[1763712393,"0.27"],[1763712408,"0.27"],[1763712423,"0.3"],[1763712438,"0.3"],[1763712453,"0.3"],[1763712468,"0.3"],[1763712483,"0.19"],[1763712498,"0.19"],[1763712513,"0.19"]]}]}}"""
YELLOW = "#ffff00"  # Firefly palette color
GREEN = "#ADFF2F"  # Firefly palette color
ORANGE = "#FF4500"  # Firefly palette color
BLUE = "#0000FF"  # Firefly palette color
RED = "#FF0000"

def main(config):
    grafana_url = config.str("grafana_url", DEFAULT_GRAFANA_URL)
    api_key = config.str("api_key", DEFAULT_KEY)
    instance = config.str("instance", DEFAULT_INSTANCE)
    metric = config.str("metric", "node_load1")
    hours = bounded_int(config.get("hours_history", "24"), 24, 1, 168)
    display_graph = config.bool("display_graph")
    step_interval = config.str("step_interval", "1m")

    # Get the metric data
    metric_data = get_metric_data(grafana_url, api_key, instance, metric, hours, display_graph, step_interval)

    # Parse value range filters
    feed_value_range = parse_range(config.get("feed_value_range", None))
    feed2_value_range = parse_range(config.get("feed2_value_range", None))

    # check for feed2
    feed2 = None
    display_graph2 = config.bool("display_graph2")
    metric2 = config.str("metric2", "")
    step_interval2 = config.str("step_interval2", "1m")
    if metric2:
        feed2 = get_metric_data(grafana_url, api_key, instance, metric2, hours, display_graph2, step_interval2)

    if "error" in metric_data or (feed2 and "error" in feed2):  # if we have error key, then we display an error
        error_dict = dict()
        if ("error" in metric_data):
            error_dict = metric_data
        if (feed2 and "error" in feed2):
            error_dict = feed2
        error_string = error_dict["error"]
        if ("url" in error_string.lower() or "invalid" in error_string.lower()):
            error_message = error_string
        else:
            error_message = "Metric not found"
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Text(
                            content = "Grafana Error",
                            font = "tb-8",
                            color = RED,
                        ),
                        render.WrappedText(
                            content = error_message,
                            font = "tb-8",
                            color = ORANGE,
                        ),
                    ],
                ),
            ),
        )

    else:
        #FEED
        # build the feed_graph
        feed_graph = None

        # print(metric_data)
        if config.bool("display_graph") and len(metric_data["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(metric_data["data"])):
                points.append((i, float(metric_data["data"][i][1])))

            # print("points " + str(points))
            y_lim = (None, None)
            min_max = parse_axis_range(config.get("y_min_max"))
            if min_max:
                y_lim = min_max
            feed_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = safe_color(config.get("graph_color"), "#0000cc"),
                y_lim = y_lim,
            )

        # build feed2_graph
        feed2_graph = None
        if config.bool("display_graph2") and feed2 and len(feed2["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed2["data"])):
                points.append((i, float(feed2["data"][i][1])))

            # print("points " + str(points))
            y2_lim = (None, None)
            min_max = parse_axis_range(config.get("y2_min_max"))
            if min_max:
                y2_lim = min_max
            feed2_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = safe_color(config.get("graph2_color"), "#0000cc"),
                y_lim = y2_lim,
            )

        # Check if feed values are in range - if not, return empty
        feed_value = float(metric_data["data"][-1][1])
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
                                            content = config.str("feed_name", None) or instance,
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

def get_metric_data(grafana_url, api_key, instance, metric, hours, need_time_series, step_interval):
    if not grafana_url or not api_key or not instance:
        dummy = json.decode(JSON_DUMMY_DATA)

        # Parse dummy data into AdafruitIO-compatible format
        if dummy.get("status") == "success" and "data" in dummy:
            result = dummy["data"]["result"][0] if dummy["data"]["result"] else None
            if result and "values" in result:
                return {
                    "feed": {
                        "id": 1,
                        "name": instance,
                        "key": instance,
                    },
                    "data": [[str(v[0]), str(v[1])] for v in result["values"]],
                }
        return {"error": "No dummy data available"}

    origin = grafana_origin(grafana_url)
    if not origin:
        return {"error": "Invalid Grafana URL"}
    if not valid_token(api_key) or not valid_selector(instance) or not valid_metric(metric) or not valid_step(step_interval):
        return {"error": "Invalid Grafana configuration"}

    query = "%s{instance=\"%s\"}" % (metric, instance)

    # If we need time series data (for graphs), use query_range
    # Otherwise use instant query which is faster
    if need_time_series:
        # Calculate time range for query
        now = time.now()
        end_time = int(now.unix)
        start_time = end_time - (hours * 3600)

        # Query range endpoint for time series data
        url = origin + "/api/datasources/proxy/uid/grafanacloud-prom/api/v1/query_range"
        params = {"query": query, "start": str(start_time), "end": str(end_time), "step": step_interval}
    else:
        url = origin + "/api/datasources/proxy/uid/grafanacloud-prom/api/v1/query"
        params = {"query": query}

    res = http.get(
        url,
        params = params,
        headers = {"Authorization": "Bearer " + api_key},
    )

    if res.status_code != 200:
        return {"error": "API returned status %d" % res.status_code}

    body = res.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return {"error": "API response too large"}
    data = json.decode(body, {})

    if data.get("status") == "success" and "data" in data:
        results = data["data"].get("result", [])
        if not results:
            return {"error": "No data returned for query"}

        # Get first result
        result = results[0]

        # Check if this is an instant query (single value) or range query (time series)
        if "value" in result:
            # Instant query returns: {"value": [timestamp, "value"]}
            value = valid_point(result["value"])
            if value == None:
                return {"error": "Invalid value in result"}
            return {
                "feed": {
                    "id": 1,
                    "name": instance,
                    "key": instance,
                },
                "data": [[str(value[0]), str(value[1])]],
            }
        elif "values" in result:
            # Range query returns: {"values": [[timestamp, "value"], ...]}
            values = [point for point in [valid_point(value) for value in result["values"][:MAX_POINTS]] if point != None] if type(result["values"]) == "list" else []
            if not values:
                return {"error": "No values in result"}

            return {
                "feed": {
                    "id": 1,
                    "name": instance,
                    "key": instance,
                },
                "data": [[str(v[0]), str(v[1])] for v in values],
            }
        else:
            return {"error": "Unexpected result format"}

    return {"error": "Invalid response format"}

def parse_range(range_str):
    """Parse a min-max range string like '10-20' into a tuple (min, max).
    Returns None if range_str is empty or invalid."""
    if not range_str:
        return None
    if type(range_str) == "string" and "-" in range_str:
        parts = range_str.split("-")
        if len(parts) == 2:
            low = safe_float(parts[0])
            high = safe_float(parts[1])
            if low != None and high != None and low <= high:
                return (low, high)
    return None

def parse_axis_range(value):
    parts = value.split(",") if type(value) == "string" else []
    if len(parts) != 2:
        return None
    low = safe_float(parts[0])
    high = safe_float(parts[1])
    return (low, high) if low != None and high != None and low < high else None

def safe_float(value):
    if type(value) == "int" or type(value) == "float":
        return float(value)
    if type(value) != "string" or len(value) > 32:
        return None
    cleaned = value.strip()
    unsigned = cleaned[1:] if cleaned.startswith("-") or cleaned.startswith("+") else cleaned
    parts = unsigned.split(".")
    if len(parts) > 2 or not "".join(parts) or any([char not in "0123456789" for char in "".join(parts).elems()]):
        return None
    return float(cleaned)

def bounded_int(value, fallback, minimum, maximum):
    if type(value) == "int":
        parsed = value
    elif type(value) == "string" and value.isdigit():
        parsed = int(value)
    else:
        return fallback
    return parsed if parsed >= minimum and parsed <= maximum else fallback

def grafana_origin(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]]):
        return ""
    parts = value.split("/", 3)
    host = parts[2].lower() if len(parts) >= 3 else ""
    if not host or "@" in host or ":" in host:
        return ""
    path = parts[3].strip("/") if len(parts) == 4 else ""
    return "" if path else "https://" + host

def valid_token(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 2048 and not any([char in value for char in ["\r", "\n"]])

def valid_metric(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 128 and all([char.isalnum() or char in "_:" for char in value.elems()])

def valid_selector(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 256 and not any([char in value for char in ["\"", "\\", "\r", "\n"]])

def valid_step(value):
    if type(value) != "string" or len(value) < 2 or len(value) > 8 or value[-1] not in "smhd":
        return False
    return value[:-1].isdigit() and int(value[:-1]) >= 1 and int(value[:-1]) <= 10000

def valid_point(value):
    if type(value) != "list" or len(value) != 2:
        return None
    timestamp = safe_float(value[0])
    measurement = safe_float(value[1])
    return [str(timestamp), str(measurement)] if timestamp != None and measurement != None else None

def safe_color(value, fallback):
    if type(value) == "string" and len(value) in [4, 7] and value.startswith("#") and all([char.lower() in "0123456789abcdef" for char in value[1:].elems()]):
        return value
    return fallback

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
            id = "grafana_url",
            name = "Grafana Host",
            desc = "Public HTTPS Grafana root URL (e.g., https://example.grafana.net)",
            icon = "server",
        ),
    )
    fields.append(
        schema.Text(
            id = "api_key",
            name = "API Key",
            desc = "Grafana API Key or Service Account Token",
            icon = "key",
            secret = True,
        ),
    )
    fields.append(
        schema.Text(
            id = "instance",
            name = "Instance",
            desc = "Instance name to query",
            icon = "server",
            default = "default",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_name",
            name = "Chart Label",
            icon = "tag",
            desc = "Optional Custom Label",
            default = "",
        ),
    )

    fields.append(
        schema.Text(
            id = "metric",
            name = "Metric",
            desc = "Prometheus metric name (e.g., node_load1, node_memory_MemAvailable_bytes)",
            icon = "chartLine",
            default = "node_load1",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed_color",
            name = "Color",
            desc = "Metric 1 Color",
            icon = "brush",
            default = "#b07f51",
        ),
    )

    fields.append(
        schema.Text(
            id = "feed_units",
            name = "Metric Units",
            icon = "quoteRight",
            desc = "Metric units (e.g., %, MB, req/s)",
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
            default = "#304463",
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
            id = "step_interval",
            name = "Data Point Interval",
            desc = "Time between data points (e.g., 15s, 1m, 5m, 1h)",
            icon = "clock",
            default = "1m",
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

    fields.append(
        schema.Text(
            id = "metric2",
            name = "Metric 2 (Optional)",
            desc = "Second Prometheus metric name (optional)",
            icon = "chartLine",
            default = "",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed2_color",
            name = "Metric 2 Color",
            desc = "Metric Color",
            icon = "brush",
            default = "#5c9949",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_units",
            name = "Metric 2 Units",
            icon = "quoteRight",
            desc = "Metric units preference",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_value_range",
            name = "Metric 2 Value Range Filter",
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
            default = "#5c4796",
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
    fields.append(
        schema.Text(
            id = "step_interval2",
            name = "Graph 2 Data Point Interval",
            desc = "Time between data points for graph 2 (e.g., 15s, 1m, 5m, 1h)",
            icon = "clock",
            default = "1m",
        ),
    )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)
