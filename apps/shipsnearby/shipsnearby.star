"""
Applet: Ships Nearby
Summary: Display ships from Marinesia API or other json data source.
Description: Shows vessels near Indonesia using Marinesia API.
Author: tavdog
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Container ship icon (32x10 pixels)
CONTAINER_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAKCAYAAADVTVykAAAAWElEQVR4nGNgoAO4c+fOfxCmh104LSfbESdsbP6DsE3KFgheEADGJ7bYQDAO+aHvAJiBMIvgFqNZSEg+ICAKBQ9+B6BroAXG7Wsbt//0wgPqCOLSAJ0sBgABdYfIAQVTYgAAAABJRU5ErkJggg==")

# Cargo/bulk carrier ship icon (32x10 pixels)
CARGO_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAKCAYAAADVTVykAAAAkElEQVR4nGNgoAMwMrL5D8LY5JgYBhgw0tqCO3fuoPhcRUWFcVCFAAsuiby8CqxxRiqYNGkOaVGQB7X4EZcNRRZXHOlA4S8zQpg3aVIHI9YQ0LBJ+b/r3Bsom4GqAGYuzJ4bR+YwYg0BkCQDjQHMcqwOQHaEiAbC1ZSANzdEMCzG6wAYsEkJoDg0jszZgNcOAESuLXbaOFrzAAAAAElFTkSuQmCC")

# Tugboat icon (24x10 pixels)
TUG_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAKCAYAAACuaZ5oAAAASklEQVR4nGNgoAAYGdn8B2FKzBgYC+7cufMfG6aqBXJyGnCDYWyqWkCxDzQ0jP6Ti3EamhJg8x+EtxgZUYwHxgJkQDODybUIl34AGGjZ9C3FCkUAAAAASUVORK5CYII=")

API_URL = "https://api.marinesia.com/api/v1/vessel/nearby"

DEFAULT_BBOX = "105,-7.5,107,-5"

DISPLAY_OPTIONS = [
    schema.Option(display = "Auto", value = "auto"),
    schema.Option(display = "Speed & Course", value = "speed_course"),
    schema.Option(display = "Nav Status", value = "nav_status"),
    schema.Option(display = "Vessel Type", value = "vessel_type"),
    schema.Option(display = "Flag", value = "flag"),
    schema.Option(display = "IMO", value = "imo"),
    schema.Option(display = "MMSI", value = "mmsi"),
    schema.Option(display = "Dimensions", value = "dimensions"),
    schema.Option(display = "Coordinates", value = "coordinates"),
    schema.Option(display = "Heading", value = "heading"),
    schema.Option(display = "Draft", value = "draught"),
    schema.Option(display = "Destination", value = "destination"),
    schema.Option(display = "ETA", value = "eta"),
    schema.Option(display = "None", value = "none"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your API key from marinesia.com",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "bbox",
                name = "Bounding Box",
                desc = "Use https://boundingbox.klokantech.com/",
                icon = "mapPin",
                default = DEFAULT_BBOX,
            ),
            schema.Toggle(
                id = "use_custom",
                name = "Use Custom URL",
                desc = "Whether to use a custom JSON URL instead of Marinesia API",
                icon = "link",
                default = False,
            ),
            schema.Text(
                id = "data_url",
                name = "AIS Stream Data URL",
                desc = "URL to a JSON format data source",
                icon = "link",
            ),
            schema.Text(
                id = "timeout",
                name = "Display Timeout",
                desc = "Hide ship if data is older than this many minutes (0 to disable)",
                icon = "clock",
                default = "60",
            ),
            schema.Dropdown(
                id = "line2",
                name = "Line 2 Info",
                desc = "Information to display on the second line",
                icon = "alignLeft",
                default = "speed_course",
                options = DISPLAY_OPTIONS,
            ),
            schema.Dropdown(
                id = "line3",
                name = "Line 3 Info",
                desc = "Information to display on the third line",
                icon = "alignLeft",
                default = "nav_status",
                options = DISPLAY_OPTIONS,
            ),
        ],
    )

def fetch_vessels(bbox, api_key):
    parts = bbox.strip().split(",")
    if len(parts) != 4 or any([not valid_decimal(value) for value in parts]):
        return None, "Invalid bbox: need 4 values (long_min,lat_min,long_max,lat_max)"
    values = [float(value) for value in parts]
    if values[0] < -180 or values[0] > 180 or values[2] < -180 or values[2] > 180 or values[1] < -90 or values[1] > 90 or values[3] < -90 or values[3] > 90 or values[0] >= values[2] or values[1] >= values[3]:
        return None, "Invalid bounding box"
    params = {
        "key": api_key,
        "long_min": parts[0],
        "lat_min": parts[1],
        "long_max": parts[2],
        "lat_max": parts[3],
    }
    response = http.get(API_URL, params = params, headers = {"Accept": "application/json"})
    body = response.body()
    if response.status_code == 404:
        return [], None
    if response.status_code != 200 or not body or len(body) > 2097152:
        return None, "API error: " + str(response.status_code)
    data = json.decode(body, None)
    if type(data) != "dict":
        return None, "Invalid API response"
    if data.get("error", True):
        message = data.get("message")
        return None, (message[:120] if type(message) == "string" else "API error")
    vessels = data.get("data", [])
    return normalize_vessels(vessels), None

def valid_decimal(value):
    value = value.strip()
    if not value or len(value) > 20 or value.count(".") > 1:
        return False
    if value[0] in ["-", "+"]:
        value = value[1:]
    return value and all([value[i].isdigit() or value[i] == "." for i in range(len(value))])

def fetch_custom_data(url):
    if type(url) != "string" or len(url) > 2048 or not url.startswith("https://"):
        return None, "Custom URL must use HTTPS"
    response = http.get(url, headers = {"Accept": "application/json"})
    if response.status_code != 200:
        return None, "Custom URL error: " + str(response.status_code)

    body = response.body()
    if not body or len(body) > 2097152:
        return None, "Custom response is empty or too large"

    # The data source appears to be a Python-style dictionary string rather than strict JSON.
    # We attempt to normalize it to valid JSON.
    if body.startswith("{'") or body.startswith("['"):
        body = body.replace("'", '"')
        body = body.replace("True", "true")
        body = body.replace("False", "false")
        body = body.replace("None", "null")

    data = json.decode(body, None)

    vessels = []
    if type(data) == "dict":
        vessels = [data]
    elif type(data) == "list":
        vessels = data
    else:
        return None, "Invalid JSON format from custom URL"

    return normalize_vessels(vessels), None

def normalize_vessels(vessels):
    if type(vessels) != "list":
        return []
    result = []
    for vessel in vessels[:200]:
        normalized = normalize_vessel(vessel)
        if normalized:
            result.append(normalized)
    return result

def number(value):
    return value if type(value) in ["int", "float"] else 0

def text(value, limit = 120):
    return value[:limit] if type(value) == "string" else ""

def normalize_vessel(v):
    if type(v) != "dict":
        return None
    if "MetaData" in v and "Message" in v:
        # Custom format mapping
        meta = v.get("MetaData", {})
        msg_outer = v.get("Message", {})
        msg = msg_outer.get("PositionReport") or msg_outer.get("ShipStaticData") or {}

        v = {
            "name": meta.get("ShipName") or meta.get("ShipName_String"),
            "mmsi": meta.get("MMSI") or meta.get("MMSI_String"),
            "lat": meta.get("latitude") or msg.get("Latitude"),
            "lng": meta.get("longitude") or msg.get("Longitude"),
            "sog": msg.get("Sog"),
            "cog": msg.get("Cog"),
            "hdt": msg.get("TrueHeading"),
            "status": msg.get("NavigationalStatus"),
            "ts": meta.get("time_utc"),
            "type": v.get("MessageType"),
        }
    return {
        "name": text(v.get("name")),
        "mmsi": text(str(v.get("mmsi") or ""), 24),
        "imo": text(str(v.get("imo") or ""), 24),
        "lat": number(v.get("lat")),
        "lng": number(v.get("lng")),
        "sog": number(v.get("sog")),
        "cog": number(v.get("cog")),
        "hdt": number(v.get("hdt")),
        "status": v.get("status") if type(v.get("status")) == "int" else 15,
        "ts": text(v.get("ts"), 80),
        "type": text(v.get("type"), 80),
        "flag": text(v.get("flag"), 8),
        "dest": text(v.get("dest")),
        "eta": text(v.get("eta"), 40),
        "draught": number(v.get("draught")),
        "a": number(v.get("a")),
        "b": number(v.get("b")),
        "c": number(v.get("c")),
        "d": number(v.get("d")),
    }

NAV_STATUS = {
    0: "Underway",
    1: "Anchor",
    2: "Not cmd",
    3: "Restrict",
    4: "Moored",
    5: "Aground",
    6: "Fishing",
    7: "Sailing",
    8: "Reserved",
    9: "Reserved",
    10: "Reserved",
    11: "AIS-SART",
    12: "Undef",
    13: "Undefined",
    14: "AIS-SART",
    15: "N/A",
}

AUTO_PRIORITY = [
    "dest",
    "type",
    "flag",
    "imo",
    "mmsi",
    "coords",
    "hdt",
    "draft",
    "eta",
]

def get_info_text(option, vessel, skip_field = ""):
    if option == "auto":
        for field in AUTO_PRIORITY:
            if field == skip_field:
                continue
            if field == "dest":
                dest = vessel.get("dest", "")
                if dest:
                    return dest, field
            elif field == "type":
                vtype = vessel.get("type", "")
                if vtype:
                    return vtype, field
            elif field == "flag":
                flag = vessel.get("flag", "")
                if flag:
                    return flag, field
            elif field == "imo":
                imo = vessel.get("imo", 0)
                if imo:
                    return "IMO: " + str(imo), field
            elif field == "mmsi":
                mmsi = vessel.get("mmsi", "")
                if mmsi:
                    return "MMSI: " + str(mmsi), field
            elif field == "coords":
                lat = vessel.get("lat", 0)
                lng = vessel.get("lng", 0)
                if lat and lng:
                    return str(int(lat * 1000) / 1000.0) + ", " + str(int(lng * 1000) / 1000.0), field
            elif field == "hdt":
                hdt = vessel.get("hdt", "")
                if hdt:
                    return "Hdg: " + str(hdt), field
            elif field == "draft":
                draught = vessel.get("draught", 0)
                if draught:
                    return "Draft: " + str(draught) + "m", field
            elif field == "eta":
                eta = vessel.get("eta", "")
                if eta:
                    return "ETA: " + eta, field
        return "", ""
    if option == "speed_course":
        sog = vessel.get("sog", 0)
        cog = vessel.get("cog", 0)
        return str(sog) + " kn - " + str(cog) + "°", ""
    elif option == "nav_status":
        status = vessel.get("status", 15)
        return NAV_STATUS.get(status, "N/A"), ""
    elif option == "vessel_type":
        vtype = vessel.get("type", "")
        return vtype if vtype else "Unknown", "type"
    elif option == "flag":
        flag = vessel.get("flag", "")
        return flag if flag else "N/A", "flag"
    elif option == "imo":
        imo = vessel.get("imo", 0)
        return "IMO: " + str(imo) if imo else "N/A", "imo"
    elif option == "mmsi":
        mmsi = vessel.get("mmsi", "")
        return "MMSI: " + str(mmsi) if mmsi else "N/A", "mmsi"
    elif option == "dimensions":
        a = vessel.get("a", 0)
        b = vessel.get("b", 0)
        c = vessel.get("c", 0)
        d = vessel.get("d", 0)
        if a and b and c and d:
            return str(a) + "x" + str(b) + "x" + str(c) + "m", "dims"
        return "N/A", ""
    elif option == "coordinates":
        lat = vessel.get("lat", 0)
        lng = vessel.get("lng", 0)
        lat_str = str(int(lat * 1000) / 1000.0)
        lng_str = str(int(lng * 1000) / 1000.0)
        return lat_str + ", " + lng_str, "coords"
    elif option == "heading":
        hdt = vessel.get("hdt", "")
        return "Hdg: " + str(hdt) if hdt else "N/A", "hdt"
    elif option == "draught":
        draught = vessel.get("draught", 0)
        return "Draft: " + str(draught) + "m" if draught else "Draft: N/A", "draft"
    elif option == "destination":
        dest = vessel.get("dest", "")
        return dest if dest else "N/A", "dest"
    elif option == "eta":
        eta = vessel.get("eta", "")
        return "ETA: " + eta if eta else "N/A", "eta"
    elif option == "none":
        return "", ""
    return "", ""

def render_view(vessels, line2_opt, line3_opt):
    if len(vessels) == 0:
        return []

    # Find vessel with a name, pick newest by ts
    v = None
    for vv in vessels:
        name = vv.get("name")
        if name:
            if v == None or vv.get("ts", "") > v.get("ts", ""):
                v = vv

    if not v:
        # Use newest by mmsi
        for vv in vessels:
            mmsi = vv.get("mmsi")
            if mmsi:
                if v == None or vv.get("ts", "") > v.get("ts", ""):
                    v = vv
        if not v:
            return []

    name = v.get("name") or ""
    vtype = v.get("type") or ""

    name_line = (name + (" (" + vtype + ")" if vtype else ""))[:160]

    vtype_lower = vtype.lower() if vtype else ""
    is_cg = "CGC " in name or name.startswith("CGC")
    if is_cg:
        icon = CARGO_ICON  # Placeholder if we want to draw it
    elif vtype_lower == "tug":
        icon = TUG_ICON
    elif vtype_lower == "container ship" or "container" in vtype_lower:
        icon = CONTAINER_ICON
    else:
        icon = CARGO_ICON

    info_lines = [render.Text(name_line, font = "tom-thumb", color = "#fff")]

    line2_result = get_info_text(line2_opt, v, "")
    if line2_result:
        info_lines.append(render.Text(line2_result[0], font = "tom-thumb", color = "#aaa"))

    line3_skip = line2_result[1] if (line2_opt == "auto" and line3_opt == "auto") else ""
    line3_result = get_info_text(line3_opt, v, line3_skip)
    if line3_result:
        info_lines.append(render.Text(line3_result[0], font = "tom-thumb", color = "#aaa"))

    icon_widget = render.Image(src = icon)
    if is_cg:
        # Sleeker Coast Guard Cutter: Pointed bow, angled racing stripe, mast and bridge details
        # Scaled to be longer (approx 44 pixels)
        icon_widget = render.Stack(
            children = [
                # Hull Layers (Pointed Bow on the Right)
                render.Padding(pad = (0, 4, 0, 0), child = render.Box(width = 44, height = 2, color = "#fff")),  # Top deck
                render.Padding(pad = (1, 6, 2, 0), child = render.Box(width = 41, height = 2, color = "#fff")),  # Mid hull
                render.Padding(pad = (3, 8, 5, 0), child = render.Box(width = 36, height = 2, color = "#ddd")),  # Bottom hull
                # Superstructure
                render.Padding(pad = (10, 1, 0, 0), child = render.Box(width = 20, height = 3, color = "#fff")),
                render.Padding(pad = (26, 2, 0, 0), child = render.Box(width = 4, height = 1, color = "#333")),  # Bridge windows
                render.Padding(pad = (14, 0, 0, 0), child = render.Box(width = 1, height = 2, color = "#999")),  # Mast
                # Racing Stripe (Angled)
                render.Padding(pad = (38, 4, 0, 0), child = render.Box(width = 2, height = 2, color = "#f00")),
                render.Padding(pad = (37, 6, 0, 0), child = render.Box(width = 2, height = 2, color = "#f00")),
                render.Padding(pad = (36, 8, 0, 0), child = render.Box(width = 2, height = 2, color = "#f00")),
            ],
        )

    return render.Root(
        max_age = 1800,
        child = render.Column(
            children = [
                render.Row(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = icon_widget,
                        ),
                    ],
                ),
                render.Padding(
                    pad = (1, 0, 1, 0),
                    child = render.Column(
                        children = info_lines,
                    ),
                ),
            ],
        ),
    )

def render_error(err):
    return render.Root(
        child = render.Padding(
            child = render.Text(err, font = "tom-thumb", color = "#f00"),
            pad = 1,
        ),
    )

def main(config):
    use_custom = config.bool("use_custom")
    timeout = config.str("timeout", "60").strip()
    if not timeout.isdigit() or len(timeout) > 4 or int(timeout) > 1440:
        return render_error("Invalid timeout")
    timeout_mins = int(timeout)

    if use_custom:
        data_url = config.get("data_url", "")
        if not data_url:
            return render_error("Data URL required")
        vessels, err = fetch_custom_data(data_url)
    else:
        api_key = config.str("api_key", "").strip()
        if not api_key or len(api_key) > 512:
            return render_error("API key required")
        bbox = config.get("bbox", DEFAULT_BBOX)
        if bbox == "":
            bbox = DEFAULT_BBOX
        vessels, err = fetch_vessels(bbox, api_key)

    if err:
        return render_error(err)

    if len(vessels) > 0 and timeout_mins > 0:
        # Find newest vessel
        newest_v = None
        for v in vessels:
            if newest_v == None or v.get("ts", "") > newest_v.get("ts", ""):
                newest_v = v

        if newest_v and newest_v.get("ts"):
            ts_str = newest_v.get("ts")
            parsed_ts = None

            # Try to handle common formats without crashing
            if " +0000 UTC" in ts_str:
                # Format: '2026-06-03 05:19:21.142948755 +0000 UTC'
                parsed_ts = time.parse_time(ts_str, format = "2006-01-02 15:04:05.999999999 -0700 MST")
            elif "T" in ts_str:
                # Likely ISO8601/RFC3339
                if "." in ts_str:
                    parsed_ts = time.parse_time(ts_str, format = "2006-01-02T15:04:05.999999999Z07:00")
                else:
                    parsed_ts = time.parse_time(ts_str, format = "2006-01-02T15:04:05Z07:00")

            if parsed_ts:
                now = time.now()
                diff = now - parsed_ts
                if diff.minutes > timeout_mins:
                    return render_error("Ship data is too old")

    line2_opt = config.get("line2", "speed_course")
    line3_opt = config.get("line3", "nav_status")
    allowed = [option.value for option in DISPLAY_OPTIONS]
    if line2_opt not in allowed or line3_opt not in allowed:
        return render_error("Invalid display option")

    return render_view(vessels, line2_opt, line3_opt)
