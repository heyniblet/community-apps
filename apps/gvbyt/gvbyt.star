"""
Applet: Gvbyt
Summary: Live tram departures
Description: Displays live tram departures for GVB stops in Amsterdam.
Author: Matt Jones (mattjones0111)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JINA_READER = "https://r.jina.ai/"
GVB_VISITS = "https://gvb.nl/api/gvb-shared-services/travelinformation/api/v1/DepartureTimes/GetVisits?stopType=Cluster&previewInterval=60&passageType=Departure&stopCodes="
DEFAULT_STOP = '{"display":"IJburg","text":"IJburg","value":"9508252"}'
MAX_RESPONSE_BYTES = 512 * 1024

def main(config):
    if not config.bool("live", False):
        return message("Enable live departures")
    stop = stop_code(config.get("stop", DEFAULT_STOP))
    if not stop:
        return message("Invalid GVB stop")
    departures = get_departures(stop)
    if not departures:
        return message("No departures")
    rows = []
    for departure in departures[:2]:
        rows.extend([render.Box(width = 64, height = 1), departure_row(departure)])
    return render.Root(child = render.Column(children = rows), max_age = 30)

def get_departures(stop):
    response = http.get(JINA_READER + GVB_VISITS + stop, ttl_seconds = 60)
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES or "Markdown Content:" not in body:
        return []
    payload = json.decode(body.split("Markdown Content:", 1)[1].strip(), [])
    if type(payload) != "list":
        return []
    departures = []
    now = time.now()
    for item in payload[:100]:
        group = item.get("departureGroup") if type(item) == "dict" else None
        timestamp = group.get("expectedDateTime") if type(group) == "dict" else None
        line = item.get("publishedLineNumber") if type(item) == "dict" else None
        destination = item.get("destinationName") if type(item) == "dict" else None
        if not valid_timestamp(timestamp) or type(line) != "string" or type(destination) != "string":
            continue
        departure_time = time.parse_time(timestamp)
        minutes = int((departure_time - now).minutes)
        if minutes < 0 or minutes > 180:
            continue
        departures.append({"timestamp": timestamp, "line": line[:8], "destination": destination[:80], "minutes": minutes})
    return sorted(departures, key = lambda item: item["timestamp"])

def departure_row(item):
    return render.Row(
        children = [
            render.Marquee(width = 52, height = 7, child = render.Text(content = item["line"] + " " + item["destination"], font = "CG-pixel-3x5-mono")),
            render.Box(width = 1, height = 7),
            render.Text(content = str(item["minutes"]) + "m", font = "CG-pixel-3x5-mono"),
        ],
    )

def stop_code(value):
    decoded = json.decode(value, {}) if type(value) == "string" else {}
    candidate = decoded.get("value") if type(decoded) == "dict" else value
    candidate = value if type(candidate) != "string" and type(value) == "string" else candidate
    if type(candidate) != "string" or not candidate or len(candidate) > 16 or not candidate.isdigit():
        return ""
    return candidate

def valid_timestamp(value):
    if type(value) != "string" or len(value) not in [20, 25] or value[4] != "-" or value[7] != "-" or value[10] != "T" or value[13] != ":" or value[16] != ":":
        return False
    digits = value[:4] + value[5:7] + value[8:10] + value[11:13] + value[14:16] + value[17:19]
    if not digits.isdigit():
        return False
    month, day, hour, minute, second = int(value[5:7]), int(value[8:10]), int(value[11:13]), int(value[14:16]), int(value[17:19])
    if not (month >= 1 and month <= 12 and day >= 1 and day <= 31 and hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 and second >= 0 and second <= 59):
        return False
    return value.endswith("Z") if len(value) == 20 else value[19] in "+-" and value[20:22].isdigit() and value[22] == ":" and value[23:25].isdigit()

def message(text):
    return render.Root(child = render.WrappedText(content = text, width = 62, align = "center"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "stop", name = "Stop", desc = "GVB cluster stop code, such as 9508252 for IJburg.", icon = "gear", default = "9508252"),
            schema.Toggle(id = "live", name = "Live departures", desc = "Use the slower public reader fallback for current departures.", icon = "train", default = False),
        ],
    )
