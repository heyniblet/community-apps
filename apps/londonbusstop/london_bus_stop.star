"""Show upcoming arrivals at a London bus stop."""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOP_ID = "490020255S"
API_URL = "https://api.tfl.gov.uk/StopPoint"
USER_AGENT = "Niblet london-bus-stop"
RED = "#DA291C"
ORANGE = "#FFA500"
FONT = "tom-thumb"

def config_value(value, default):
    if type(value) != "string" or not value.strip():
        return default
    value = value.strip()
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value") if type(option) == "dict" else None
    return value.strip() if type(value) == "string" and value.strip() else default

def valid_stop(value):
    return len(value) <= 64 and all([value[i].isalnum() or value[i] in ["-", "_"] for i in range(len(value))])

def request_json(path, params):
    response = http.get(API_URL + path, params = params, headers = {"Accept": "application/json", "User-Agent": USER_AGENT})
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 1048576:
        return None
    return json.decode(body, None)

def extract_child(stop_id, children, depth = 0):
    if depth >= 8 or type(children) != "list":
        return None
    for child in children[:100]:
        if type(child) != "dict":
            continue
        if child.get("naptanId") == stop_id and type(child.get("commonName")) == "string":
            return {"name": child["commonName"][:120], "code": str(child.get("stopLetter") or "?")[:3]}
        found = extract_child(stop_id, child.get("children"), depth + 1)
        if found:
            return found
    return None

def get_stop(stop_id, api_key):
    data = request_json("/" + stop_id, {"app_key": api_key})
    if type(data) != "dict":
        return None
    child = extract_child(stop_id, data.get("children"))
    if child:
        return child
    name = data.get("commonName")
    if type(name) != "string" or not name:
        return None
    return {"name": name[:120], "code": str(data.get("stopLetter") or "?")[:3]}

def get_arrivals(stop_id, api_key):
    data = request_json("/%s/Arrivals" % stop_id, {"serviceTypes": "bus,night", "app_key": api_key})
    if type(data) != "list":
        return []
    arrivals = []
    for item in data[:200]:
        if type(item) != "dict":
            continue
        seconds = item.get("timeToStation")
        line = item.get("lineName")
        if type(seconds) not in ["int", "float"] or seconds < 0 or seconds > 21600 or type(line) != "string":
            continue
        arrivals.append({
            "line": line[:12],
            "seconds": seconds,
            "destination": str(item.get("destinationName") or "Unknown destination")[:120],
        })
    arrivals = sorted(arrivals, key = lambda item: item["seconds"])[:12]
    for index in range(len(arrivals)):
        arrivals[index]["index"] = index + 1
    return arrivals

def due_row(item):
    due = "due" if item["seconds"] < 30 else "%d min" % math.round(item["seconds"] / 60.0)
    return render.Row(expanded = True, children = [
        render.WrappedText(str(item["index"]), width = 12, color = ORANGE, font = FONT),
        render.WrappedText(item["line"], width = 20, color = ORANGE, font = FONT),
        render.Row(main_align = "end", expanded = True, children = [render.Text(due, color = ORANGE, font = FONT)]),
    ])

def destination_row(item):
    return render.Row(expanded = True, children = [
        render.WrappedText(str(item["index"]), width = 12, color = ORANGE, font = FONT),
        render.Text(item["destination"], color = ORANGE, font = FONT),
    ])

def arrivals_view(arrivals):
    if not arrivals:
        return render.Box(height = 24, child = render.WrappedText("No upcoming arrivals", width = 64, align = "center", color = ORANGE))
    frames = []
    for start in range(0, len(arrivals), 4):
        section = arrivals[start:start + 4]
        frames.append(render.Box(height = 24, child = render.Column(children = [due_row(item) for item in section])))
        frames.append(render.Box(height = 24, child = render.Column(children = [destination_row(item) for item in section])))
    return render.Animation(children = frames)

def stop_header(stop):
    return render.Row(expanded = True, main_align = "space_between", children = [
        render.Padding(pad = (1, 1, 1, 0), child = render.Marquee(width = 50, height = 6, child = render.Text(stop["name"], font = FONT))),
        render.Box(width = 13, height = 7, color = RED, child = render.Padding(pad = (1, 1, 0, 0), child = render.Text(stop["code"], font = FONT))),
    ])

def main(config):
    stop_id = config_value(config.get("stop_id"), DEFAULT_STOP_ID)
    api_key = config.str("tfl_app_key", "")
    if not valid_stop(stop_id) or len(api_key) > 512:
        return render.Root(child = render.WrappedText("Configure a valid TfL stop", width = 64, align = "center"))
    stop = get_stop(stop_id, api_key)
    if stop == None:
        return render.Root(child = render.WrappedText("TfL stop unavailable", width = 64, align = "center"))
    return render.Root(
        max_age = 60,
        delay = 2000,
        show_full_animation = True,
        child = render.Column(children = [
            stop_header(stop),
            render.Box(height = 1, color = ORANGE),
            arrivals_view(get_arrivals(stop_id, api_key)),
        ]),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "tfl_app_key", name = "TfL App Key", desc = "Optional key from api.tfl.gov.uk; anonymous quota is supported.", icon = "key", secret = True),
        schema.Text(id = "stop_id", name = "Bus Stop", desc = "TfL NaPTAN stop ID, such as 490020255S.", icon = "bus", default = DEFAULT_STOP_ID),
    ])
