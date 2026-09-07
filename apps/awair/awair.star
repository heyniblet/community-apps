"""
Applet: Awair
Summary: Awair air quality data
Description: Display air quality data for an Awair device.
Author: tabrindle, flavorjones
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_RESPONSE_BYTES = 256 * 1024

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "celsius",
                name = "Display in Celsius?",
                desc = "Display in Celsius (default is Fahrenheit).",
                icon = "temperatureLow",
                default = False,
            ),
            schema.Toggle(
                id = "bar_chart",
                name = "Display bar chart?",
                desc = "Display a bar chart (default is to display a data table).",
                icon = "chartSimple",
                default = False,
            ),
            schema.Dropdown(
                id = "api_connection_type",
                name = "Awair API",
                desc = "The method used to fetch Awair data.",
                icon = "houseSignal",
                default = API_CONNECTION_TYPE_OPTIONS[0].value,
                options = API_CONNECTION_TYPE_OPTIONS,
            ),
            schema.Text(
                id = "ip_address",
                name = "Awair Local API HTTPS URL",
                desc = "Optional public HTTPS relay for an Awair Local API. Private LAN addresses cannot be reached by Niblet Cloud.",
                icon = "computer",
                default = "",
            ),
            schema.Text(
                id = "bearer_token",
                name = "Access token for Awair Developer API",
                desc = "Used only with the Cloud API option. Create a token at https://developer.getawair.com/.",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "device_id",
                name = "Awair device id",
                desc = "Used only with the Cloud API option. Find deviceID with the official GET Devices endpoint.",
                icon = "server",
                default = "",
            ),
            schema.Dropdown(
                id = "device_type",
                name = "Awair device type",
                desc = "Used only with the Cloud API option.",
                icon = "shapes",
                default = API_DEVICE_TYPE_OPTIONS[0].value,
                options = API_DEVICE_TYPE_OPTIONS,
            ),
        ],
    )

API_CONNECTION_TYPE_OPTIONS = [
    schema.Option(display = "Awair Local API", value = "local"),
    schema.Option(display = "Awair Cloud API (Token)", value = "cloud_token"),
]

API_DEVICE_TYPE_OPTIONS = [
    schema.Option(display = "awair-element", value = "awair-element"),
    schema.Option(display = "awair-r2", value = "awair-r2"),
]

def main(config):
    return render_display(config, fetch_data(config))

#
#  data fetching functions
#
def fetch_data(config):
    if config.str("api_connection_type") == "cloud_token":
        data = fetch_cloud_data_by_token(config)
        if "error" in data:
            return data

        rows = data.get("data", [])
        row = rows[0] if type(rows) == "list" and rows and type(rows[0]) == "dict" else {}
        sensors = row.get("sensors", [])
        reading = {
            "temp": sensor_value(sensors, "temp"),
            "humid": sensor_value(sensors, "humid"),
            "co2": sensor_value(sensors, "co2"),
            "pm25": sensor_value(sensors, "pm25"),
            "voc": sensor_value(sensors, "voc"),
            "score": row.get("score"),
        }
        return reading if valid_reading(reading) else {"error": "Invalid Awair response."}

    else:  # local API
        base_url = config.str("ip_address", "").strip().rstrip("/")
        if not base_url:
            return {
                "error": "Please configure the Awair Local API HTTPS URL or select Cloud API.",
                "mock": True,
            }
        if len(base_url) > 2048 or not base_url.startswith("https://") or "@" in base_url.split("/")[2]:
            return {"error": "Local API requires a public HTTPS relay."}

        url = base_url if base_url.endswith("/air-data/latest") else base_url + "/air-data/latest"
        reading = read_json(http.get(url))
        return reading if valid_reading(reading) else {"error": reading.get("error", "Invalid Awair response.")}

def fetch_cloud_data_by_token(config):
    bearer_token = config.get("bearer_token")
    if type(bearer_token) != "string" or not bearer_token or len(bearer_token) > 2048 or "\r" in bearer_token or "\n" in bearer_token:
        return {"error": "No token. Get one at developer.getawair.com"}

    device_id = config.get("device_id")
    if type(device_id) != "string" or not device_id.isdigit() or len(device_id) > 20:
        return {"error": "No device ID. See how to look yours up at developer.getawair.com"}

    device_type = config.get("device_type")
    if device_type not in [option.value for option in API_DEVICE_TYPE_OPTIONS]:
        return {"error": "No device type. See how to look yours up at developer.getawair.com"}

    url = "https://developer-apis.awair.is/v1/users/self/devices/{}/{}/air-data/latest".format(
        device_type,
        device_id,
    )
    headers = {"authorization": "Bearer {}".format(bearer_token)}

    response = http.get(url = url, headers = headers)
    return read_json(response)

def read_json(response):
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return data if type(data) == "dict" else {"error": "status {}".format(response.status_code)}

def valid_reading(reading):
    return type(reading) == "dict" and all([type(reading.get(key)) in ["int", "float"] for key in ["temp", "humid", "co2", "pm25", "voc", "score"]])

def fetch_mock_data():
    return {
        "score": 77,
        "temp": 25,
        "humid": 77,
        "co2": 777,
        "pm25": 7,
        "voc": 777,
    }

def sensor_value(sensors, key):
    if type(sensors) != "list":
        return None
    for sensor in sensors[:50]:
        if type(sensor) == "dict" and sensor.get("comp") == key:
            return sensor.get("value")
    return None

#
#  rendering functions
#
def render_display(config, data):
    error = data.get("error")
    if error:
        return render_error(config, data)

    return render.Root(child = render_data(config, data))

def render_data(config, data, bar_chart = None):
    table_width = 38
    children = []
    if bar_chart == None:
        bar_chart = config.bool("bar_chart", False)

    if bar_chart:
        children.append(render_bar_chart(config, data, width = table_width))
    else:
        children.append(render_table(config, data, width = table_width))
    children.append(render_score(config, data, width = 64 - table_width))

    return render.Box(
        padding = 0,
        child = render.Row(
            children = children,
        ),
    )

def render_table(config, data, width):
    celsius = config.bool("celsius", False)

    if celsius:
        temperature = data["temp"]
    else:
        temperature = data["temp"] * 9 / 5 + 32

    return render.Box(
        height = 32,
        width = width,
        child = render.Padding(
            pad = (2, 0, 0, 0),
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Text(
                                content = "Temp",
                                font = "tb-8",
                                color = get_color(data["temp"], TEMP_INDEX_MAP),
                            ),
                            render.Text(
                                content = str(int(temperature)),
                                font = "tb-8",
                                color = get_color(data["temp"], TEMP_INDEX_MAP),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Text(
                                content = "RH%",
                                font = "tb-8",
                                color = get_color(data["humid"], RH_INDEX_MAP),
                            ),
                            render.Text(
                                content = str(int(data["humid"])),
                                font = "tb-8",
                                color = get_color(data["humid"], RH_INDEX_MAP),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Row(
                                children = [
                                    render.Text(
                                        content = "CO",
                                        font = "tb-8",
                                        color = get_color(data["co2"], CO2_INDEX_MAP),
                                    ),
                                    render.Text(
                                        content = "2",
                                        height = 8,
                                        font = "CG-pixel-3x5-mono",
                                        color = get_color(data["co2"], CO2_INDEX_MAP),
                                    ),
                                ],
                            ),
                            render.Text(
                                content = str(int(data["co2"])),
                                font = "tb-8",
                                color = get_color(data["co2"], CO2_INDEX_MAP),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Row(
                                children = [
                                    render.Text(
                                        content = "PM",
                                        font = "tb-8",
                                        color = get_color(data["pm25"], PM_INDEX_MAP),
                                    ),
                                    render.Text(
                                        content = "2",
                                        height = 7,
                                        font = "CG-pixel-3x5-mono",
                                        color = get_color(data["pm25"], PM_INDEX_MAP),
                                    ),
                                    render.Text(
                                        content = ".",
                                        height = 8,
                                        font = "tb-8",
                                        color = get_color(data["pm25"], PM_INDEX_MAP),
                                    ),
                                    render.Text(
                                        content = "5",
                                        height = 7,
                                        font = "CG-pixel-3x5-mono",
                                        color = get_color(data["pm25"], PM_INDEX_MAP),
                                    ),
                                ],
                            ),
                            render.Text(
                                content = str(int(data["pm25"])),
                                font = "tb-8",
                                color = get_color(data["pm25"], PM_INDEX_MAP),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_bar_chart_dot(color):
    return render.Padding(
        pad = (0, 1, 0, 1),
        child = render.Box(width = 2, height = 2, color = color),
    )

def render_bar_chart_bar(index, label):
    children = []
    for j in [4, 3, 2, 1, 0]:
        if j <= abs(index):
            children.append(render_bar_chart_dot(INDEX_COLOR_MAP[j]))
        else:
            children.append(render_bar_chart_dot(BLACK))
    children.append(
        render.Padding(
            pad = (0, 2, 0, 2),
            child = render.Text(
                content = label,
                font = "CG-pixel-3x5-mono",
                color = GREY,
            ),
        ),
    )

    return render.Column(
        expanded = True,
        main_align = "end",
        children = children,
    )

def render_bar_chart(_config, data, width):
    return render.Box(
        height = 32,
        width = width,
        child = render.Padding(
            pad = (2, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render_bar_chart_bar(get_index(data["temp"], TEMP_INDEX_MAP), "T"),
                    render_bar_chart_bar(get_index(data["humid"], RH_INDEX_MAP), "H"),
                    render_bar_chart_bar(get_index(data["co2"], CO2_INDEX_MAP), "C"),
                    render_bar_chart_bar(get_index(data["voc"], VOC_INDEX_MAP), "V"),
                    render_bar_chart_bar(get_index(data["pm25"], PM_INDEX_MAP), "P"),
                ],
            ),
        ),
    )

def render_score(_config, data, width):
    return render.Box(
        height = 32,
        width = width,
        child = render.Column(
            main_align = "center",
            children = [
                render.Stack(
                    children = [
                        render.Box(
                            child = render.Circle(
                                diameter = 20,
                                color = get_color(
                                    data["score"],
                                    SCORE_INDEX_MAP,
                                ),
                            ),
                        ),
                        render.Box(
                            child = render.Text(
                                content = str(int(data["score"])),
                                font = "6x13",
                                color = WHITE,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

# Renders a (possibly quite long) error message, splitting into 16-char lines.
# To ensure we have a good screenshot in the app store, if data["mock"] is True, also render mock data.
def render_error(config, data):
    message = data.get("error")
    if data.get("message"):
        message += ": " + data["message"]

    n_lines = len(message) // 16 + 1
    messages = []
    for _ in range(n_lines):
        messages.append(
            render.Text(
                content = message[:16],
                font = "tom-thumb",
                color = RED,
            ),
        )
        message = message[16:]

    children = []
    if data.get("mock"):
        children.append(render_data(config, fetch_mock_data(), bar_chart = False))
        children.append(render_data(config, fetch_mock_data(), bar_chart = True))

    children.append(render.Column(children = messages))

    return render.Root(
        delay = 3000,  # milliseconds to show each frame
        child = render.Animation(children = children),
    )

GREEN = "#41b942"
YELLOW = "#fcd026"
YELLOW_ORANGE = "#fba905"
ORANGE = "f78703"
RED = "#e8333a"
WHITE = "#ffffff"
GREY = "#888888"
BLACK = "#000000"

INDEX_COLOR_MAP = {
    -4: RED,
    -3: ORANGE,
    -2: YELLOW_ORANGE,
    -1: YELLOW,
    0: GREEN,
    1: YELLOW,
    2: YELLOW_ORANGE,
    3: ORANGE,
    4: RED,
}

SCORE_INDEX_MAP = [
    {"range": 80, "index": 0},
    {"range": 60, "index": 2},
    {"range": 0, "index": 4},
]

RH_INDEX_MAP = [
    {"range": 80.5, "index": 4},
    {"range": 64.5, "index": 3},
    {"range": 60.5, "index": 2},
    {"range": 50.5, "index": 1},
    {"range": 39.5, "index": 0},
    {"range": 34.5, "index": -1},
    {"range": 19.5, "index": -2},
    {"range": 14.5, "index": -3},
    {"range": 0, "index": -4},
]

CO2_INDEX_MAP = [
    {"range": 2500.5, "index": 4},
    {"range": 1500.5, "index": 3},
    {"range": 1000.5, "index": 2},
    {"range": 600.5, "index": 1},
    {"range": 400, "index": 0},
]

TEMP_INDEX_MAP = [
    {"range": 33.5, "index": 4},
    {"range": 31.5, "index": 3},
    {"range": 26.5, "index": 2},
    {"range": 25.5, "index": 1},
    {"range": 17.5, "index": 0},
    {"range": 16.5, "index": -1},
    {"range": 10.5, "index": -2},
    {"range": 8.5, "index": -3},
    {"range": 0, "index": -4},
]

PM_INDEX_MAP = [
    {"range": 75.5, "index": 4},
    {"range": 55.5, "index": 3},
    {"range": 35.5, "index": 2},
    {"range": 15.5, "index": 1},
    {"range": 0, "index": 0},
]

VOC_INDEX_MAP = [
    {"range": 8332.5, "index": 4},
    {"range": 3333.5, "index": 3},
    {"range": 1000.5, "index": 2},
    {"range": 333.5, "index": 1},
    {"range": 0, "index": 0},
]

def get_index(score, index_map):
    for item in index_map:
        if score >= item["range"]:
            return item["index"]
    return None

def get_color(score, index_map):
    default = WHITE

    for item in index_map:
        if score >= item["range"]:
            return INDEX_COLOR_MAP[item["index"]]

    return default
