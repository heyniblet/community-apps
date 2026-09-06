"""
Applet: Fairfax Connector
Summary: Connector bus stop info
Description: Shows when your next bus is arriving. Visit fairfaxconnector.com for more information.
Author: Austin Pearce
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bus_stop_picture.png", BUS_STOP_PICTURE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BUS_STOP_PICTURE = BUS_STOP_PICTURE_ASSET.readall()

BASE_URL = "https://www.fairfaxcounty.gov/bustime/api/v3"
DEFAULT_STOP = "6484"
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_ROUTES = 200

def get_route_colors(api_key):
    payload = api_json("/getroutes", {"key": api_key, "format": "json"})
    routes = payload.get("routes") if type(payload) == "dict" else None
    colors = {}
    for route in routes[:MAX_ROUTES] if type(routes) == "list" else []:
        route_id = safe_route(route.get("rt")) if type(route) == "dict" else None
        color = safe_color(route.get("rtclr")) if type(route) == "dict" else None
        if route_id and color:
            colors[route_id] = color
    return colors

# Gets the list of predicted bus times for an individual bus stop
def get_predictions(stop_id, api_key):
    payload = api_json("/getpredictions", {"key": api_key, "stpid": stop_id, "top": "2", "format": "json"})
    if type(payload) != "dict":
        return None
    errors = payload.get("error")
    if type(errors) == "list" and errors:
        message = errors[0].get("msg") if type(errors[0]) == "dict" else ""
        if message == "No arrival times":
            return []
        return None
    predictions = payload.get("prd")
    if type(predictions) != "list":
        return None
    result = []
    for prediction in predictions[:2]:
        route = safe_route(prediction.get("rt")) if type(prediction) == "dict" else None
        minutes = str(prediction.get("prdctdn") or "") if type(prediction) == "dict" else ""
        stop_name = prediction.get("stpnm") if type(prediction) == "dict" else None
        if route and (minutes == "DUE" or minutes.isdigit()) and type(stop_name) == "string":
            result.append({"rt": route, "prdctdn": minutes[:4], "stpnm": stop_name[:120]})
    return result

def api_json(path, params):
    response = http.get(BASE_URL + path, params = params)
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return data.get("bustime-response") if type(data) == "dict" else None

def renderBusRow(prediction, colors):
    routeColor = colors.get(prediction.get("rt"), "#ffffff")
    minutesRemaining = prediction.get("prdctdn")
    if minutesRemaining != "DUE":
        minutesRemaining = minutesRemaining + " min"
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(
                content = prediction.get("rt"),
                color = routeColor,
            ),
            render.Text(
                content = minutesRemaining,
            ),
        ],
    )

def main(config):
    stop = safe_stop(config.get("stop") or DEFAULT_STOP)
    api_key = safe_api_key(config.get("fairfax_connector_api_key"))
    banner = render.Row(
        children = [
            render.Text(
                content = "FFX",
                color = "#f00",
            ),
            render.Text(
                content = " Connector",
                color = "#ff0",
            ),
        ],
    )
    predictions = get_predictions(stop, api_key) if api_key else None
    if predictions == None:
        return render.Root(
            child = render.Column(
                children = [
                    banner,
                    render.Text(
                        content = "API Error",
                    ),
                ],
            ),
        )
    if len(predictions) == 0:
        return render.Root(
            child = render.Stack(
                children = [
                    render.Padding(
                        pad = (38, 5, 0, 0),
                        child = render.WrappedText(
                            content = "No Buses",
                            width = 24,
                        ),
                    ),
                    render.Image(
                        src = BUS_STOP_PICTURE,
                    ),
                ],
            ),
        )
    rows = [
        banner,
        render.Marquee(
            width = 64,
            child = render.Text(
                content = predictions[0].get("stpnm"),
                color = "#bbb",
            ),
        ),
    ]
    colors = get_route_colors(api_key)
    for prediction in predictions:
        rows.append(renderBusRow(prediction, colors))
    return render.Root(
        child = render.Column(
            children = rows,
        ),
    )

def safe_api_key(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 128 and "\r" not in value and "\n" not in value else ""

def safe_stop(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 12 and value.isdigit() else DEFAULT_STOP

def safe_route(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 12 and all([char.isalnum() or char in "-_" for char in value.codepoints()]) else None

def safe_color(value):
    value = str(value or "").strip().lstrip("#")
    return "#" + value if len(value) == 6 and all([char in "0123456789abcdefABCDEF" for char in value.codepoints()]) else None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fairfax_connector_api_key",
                name = "Fairfax Connector API Key",
                desc = "Your Fairfax Connector API key. See https://www.fairfaxcounty.gov/bustime/api/v3 for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "The ID of the stop, found on the bus stop sign or online at https://www.fairfaxcounty.gov/bustime/map/displaymap.jsp",
                icon = "busSimple",
            ),
        ],
    )
