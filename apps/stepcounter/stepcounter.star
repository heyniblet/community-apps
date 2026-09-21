# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""Applet: Step Counter
Author: Matt-Pesce
Summary: Tracks Daily Step Progress
Description: Displays step totals from a user-owned HTTPS relay.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STEP_GOAL = 10000

def main(config):
    url = config.str("endpoint_url")
    token = config.str("relay_token")
    if not valid_url(url) or not token:
        return render_steps(5843, 16525, 22, -16, "Add relay URL", "#ff0")
    response = http.get(url, headers = {"Authorization": "Bearer " + token})
    if response.status_code != 200 or len(response.body()) > 64 * 1024:
        return render_steps(0, 0, 0, 0, "Relay unavailable", "#f00")
    data = json.decode(response.body(), {})
    if type(data) != "dict":
        return render_steps(0, 0, 0, 0, "Invalid response", "#f00")

    today = number(data.get("today"))
    yesterday = number(data.get("yesterday"))
    this_week = number(data.get("this_week"))
    last_week = number(data.get("last_week"))
    day_percent = percent(today, yesterday)
    week_percent = percent(this_week, last_week)
    hour = time.now().hour
    expected = STEP_GOAL * ((hour - 8) / 16.0 if hour > 8 else 0)
    delta = today - expected
    if delta > 2000:
        message, message_color = "Rock Star!", "#0f0"
    elif delta > 0:
        message, message_color = "Very Good", "#fff"
    elif delta <= -2000:
        message, message_color = "Get Moving", "#f00"
    else:
        message, message_color = "Keep Going", "#ff0"
    return render_steps(today, this_week, day_percent, week_percent, message, message_color)

def valid_url(value):
    return type(value) == "string" and value.startswith("https://") and len(value) <= 4096 and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def number(value):
    return min(max(int(value), 0), 10000000) if type(value) in ["int", "float"] else 0

def percent(current, previous):
    return int((current - previous) * 100 / previous) if previous > 0 else 0 if current == 0 else 100

def render_steps(today, this_week, day_percent, week_percent, message, message_color):
    day_delta = ("+" if day_percent >= 0 else "") + str(day_percent) + "%"
    week_delta = ("+" if week_percent >= 0 else "") + str(week_percent) + "%"
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(main_align = "center", expanded = True, children = [render.Text("Step Count")]),
                render.Row(
                    children = [
                        render.Column(children = [render.Text("D:%d" % today, font = "tom-thumb"), render.Text("W:%d" % this_week, font = "tom-thumb")]),
                        render.Column(
                            cross_align = "end",
                            children = [
                                render.Text(" " + day_delta, color = "#0f0" if day_percent >= 0 else "#f00", font = "tom-thumb"),
                                render.Text(" " + week_delta, color = "#0f0" if week_percent >= 0 else "#f00", font = "tom-thumb"),
                            ],
                        ),
                    ],
                ),
                render.Row(expanded = True, main_align = "center", children = [render.Text(message, color = message_color)]),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                name = "Step data relay URL",
                desc = "A user-owned HTTPS endpoint returning today, yesterday, this_week, and last_week step totals as JSON.",
                icon = "link",
            ),
            schema.Text(
                id = "relay_token",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                icon = "key",
                secret = True,
            ),
        ],
    )
