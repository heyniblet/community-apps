"""
Applet: Hashrate
Summary: Bitcoin's hashrate
Description: Plotting the hashrate of Bitcoin.
Author: PMK (@pmk)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

URL_HASHRATE = "https://r.jina.ai/https://mempool.space/api/v1/mining/hashrate"
PERIODS = ["3y", "2y", "1y", "6m", "3m", "1m"]
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_POINTS = 1200

def main(config):
    timeperiod = config.str("timeperiod", "3y")
    if timeperiod not in PERIODS:
        timeperiod = "3y"
    show_label = config.bool("showlabel", True)

    response_hashrate = http.get(url = "{}/{}".format(URL_HASHRATE, timeperiod), ttl_seconds = 60 * 60)
    body = response_hashrate.body()
    if response_hashrate.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return error_message("Hashrate unavailable (%d)" % response_hashrate.status_code)
    json_start = body.find("{")
    hashrate = json.decode(body[json_start:], {}) if json_start >= 0 else {}
    if type(hashrate) != "dict" or not positive_number(hashrate.get("currentHashrate")):
        return error_message("Invalid hashrate data")

    points = []
    values = hashrate.get("hashrates", [])
    if type(values) == "list":
        for item in values[-MAX_POINTS:]:
            if type(item) == "dict" and positive_number(item.get("timestamp")) and positive_number(item.get("avgHashrate")):
                points.append((int(item["timestamp"]), int(item["avgHashrate"])))
    if len(points) < 2:
        return error_message("No hashrate history")

    label = "{}EH/s".format(int(float(hashrate["currentHashrate"]) / 10E17 * 10) / 10.0) if show_label else ""

    plot = render.Plot(
        data = points,
        width = 64,
        height = 32,
        color = "#0f0",
        fill = True,
    )

    return render.Root(
        max_age = 60 * 60,
        child = render.Stack(
            children = [
                plot,
                render.Padding(
                    pad = (1, 0, 1, 0),
                    child = render.Text(
                        content = str(label),
                        color = "#fff",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def error_message(text):
    return render.Root(child = render.WrappedText(content = text, width = 64, color = "#f00"))

def positive_number(value):
    return type(value) in ["int", "float"] and value > 0

def get_schema():
    options = [
        schema.Option(
            display = "Three years to date",
            value = "3y",
        ),
        schema.Option(
            display = "Two years to date",
            value = "2y",
        ),
        schema.Option(
            display = "Year to date",
            value = "1y",
        ),
        schema.Option(
            display = "Half a year to date",
            value = "6m",
        ),
        schema.Option(
            display = "Season to date",
            value = "3m",
        ),
        schema.Option(
            display = "Month to date",
            value = "1m",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "timeperiod",
                name = "Time period",
                desc = "Choose a time period",
                icon = "clock",
                default = options[0].value,
                options = options,
            ),
            schema.Toggle(
                id = "showlabel",
                name = "Show label",
                desc = "Show the label?",
                icon = "tag",
                default = True,
            ),
        ],
    )
