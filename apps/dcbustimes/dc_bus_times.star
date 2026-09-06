"""
Applet: DC Bus Times
Summary: DC (WMATA) Bus Arrival Times
Description: Displays the predicted arrival times for next buses at specified DC Metro bus stops.
Author: Steven Pressnall
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NEXTBUS_URL = "https://api.wmata.com/NextBusService.svc/json/jPredictions"
DEFAULT_STOPID1 = "1001155"

def render_message(message):
    return render.Root(
        child = render.WrappedText(content = message, width = 64, align = "center", color = "#ff0"),
    )

def valid_stop_id(stop_id):
    return type(stop_id) == "string" and len(stop_id) == 7 and stop_id.isdigit()

def get_predictions(stop_id, api_key, color):
    response = http.get(NEXTBUS_URL, params = {"StopID": stop_id}, headers = {"api_key": api_key})
    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return None
    payload = json.decode(response.body(), None)
    predictions = payload.get("Predictions") if type(payload) == "dict" else None
    if type(predictions) != "list":
        return None

    result = []
    for prediction in predictions[:50]:
        if type(prediction) != "dict":
            continue
        route = prediction.get("RouteID")
        direction = prediction.get("DirectionText")
        minutes = prediction.get("Minutes")
        if type(route) != "string" or not route or type(direction) != "string" or type(minutes) != "int" or minutes < 0 or minutes > 1440:
            continue
        result.append({
            "route": route[:16],
            "direction": direction[:160],
            "minutes": minutes,
            "color": color,
        })
        if len(result) == 4:
            break
    return result

def main(config):
    api_key = config.get("apiKey")
    if type(api_key) != "string" or not api_key:
        return render_message("Configure WMATA key")
    if len(api_key) > 512 or "\r" in api_key or "\n" in api_key:
        return render_message("Invalid WMATA key")

    stop_id_1 = config.get("StopID_1") or DEFAULT_STOPID1
    stop_id_2 = config.get("StopID_2") or ""
    if not valid_stop_id(stop_id_1) or (stop_id_2 and not valid_stop_id(stop_id_2)):
        return render_message("Use a 7-digit stop ID")

    predictions = get_predictions(stop_id_1, api_key, "#0f0")
    if predictions == None:
        return render_message("WMATA unavailable")
    if stop_id_2:
        second = get_predictions(stop_id_2, api_key, "#f00")
        if second == None:
            return render_message("WMATA unavailable")
        predictions.extend(second)
    if not predictions:
        return render_message("No predictions available")

    show_details = config.bool("DetailMode", False)
    children = []
    divider = render.Box(height = 1, width = 64, color = "#a0d")
    for prediction in predictions:
        if show_details:
            children.append(divider)
        children.append(render.Row(
            children = [
                render.Text(prediction["route"] + " ", font = "5x8", color = prediction["color"]),
                render.Text("%d min" % prediction["minutes"], font = "5x8", color = "#ff0"),
            ],
        ))
        if show_details:
            children.append(render.WrappedText(content = prediction["direction"], width = 64, font = "tom-thumb", color = "#0ff", linespacing = 0))
    if show_details:
        children.append(divider)

    return render.Root(
        delay = 200 if show_details else 500,
        show_full_animation = show_details,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            align = "start",
            offset_start = 3 if show_details else 2,
            offset_end = 32,
            child = render.Column(children = children),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "Your WMATA API key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "StopID_1",
                name = "Stop ID #1 (e.g. 1001155)",
                desc = "Bus Stop ID Number (7 digit number located on Bus Stop sign)",
                icon = "busSimple",
            ),
            schema.Text(
                id = "StopID_2",
                name = "Stop ID #2 (optional)",
                desc = "Bus Stop ID Number (leave blank if 2nd stop not desired)",
                icon = "busSimple",
            ),
            schema.Toggle(
                id = "DetailMode",
                name = "Show Details",
                desc = "Enable display of detailed bus route information",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )
