load("encoding/json.star", "json")
load("http.star", "http")
load("time.star", "time")

MAX_RESPONSE_BYTES = 1024 * 1024
MAX_TEXT_LENGTH = 160

def fetch_server_name(server_id, api_token):
    url = "https://api.battlemetrics.com/servers/" + server_id
    res = http.get(url, headers = {"Authorization": "Bearer " + api_token})
    if res.status_code != 200:
        return None
    raw = res.body()
    if len(raw) > MAX_RESPONSE_BYTES:
        return None
    body = json.decode(raw)
    data = body.get("data") if type(body) == "dict" else None
    attrs = data.get("attributes") if type(data) == "dict" else None
    name = attrs.get("name") if type(attrs) == "dict" else None
    if type(name) != "string":
        return None
    name = name[:MAX_TEXT_LENGTH]
    return name

def fetch_24h_history(server_id, api_token):
    # 30-minute resolution over a 24h window = 48 points.
    # Use UTC so the formatted timestamp's 'Z' is truthful.
    now = time.now().in_location("UTC")

    # Floor to nearest 30-min boundary (e.g. 23:50 → 23:30)
    offset = time.parse_duration(str(now.unix % 1800) + "s")
    stop = now - offset
    start = stop - time.parse_duration("24h")
    stop = stop.format("2006-01-02T15:04:05") + "Z"
    start = start.format("2006-01-02T15:04:05") + "Z"
    url = (
        "https://api.battlemetrics.com/servers/" + server_id +
        "/player-count-history?start=" + start +
        "&stop=" + stop +
        "&resolution=30"
    )
    res = http.get(url, headers = {"Authorization": "Bearer " + api_token})
    if res.status_code != 200:
        return None
    raw = res.body()
    if len(raw) > MAX_RESPONSE_BYTES:
        return None
    body = json.decode(raw)
    data = body.get("data") if type(body) == "dict" else None
    if type(data) != "list":
        return None
    valid = []
    for point in data[:100]:
        attrs = point.get("attributes") if type(point) == "dict" else None
        timestamp = attrs.get("timestamp") if type(attrs) == "dict" else None
        value = attrs.get("value") if type(attrs) == "dict" else None
        if type(timestamp) == "string" and len(timestamp) <= 40 and type(value) in ["int", "float"] and value >= 0:
            valid.append({"attributes": {"timestamp": timestamp, "value": value}})
    if not valid:
        return None
    return valid
