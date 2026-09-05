"""
Applet: BKK Schedule
Summary: Budapest public transit
Description: Public transit display for Budapest, show upcoming BKK departures for a stop.
Author: tomzorz
"""

# dev: http://127.0.0.1:8080/?stop_id=F04039

# TODO:
# - add error return to meta

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# stop ID examples
# margit hid budai hidfo pesti iranyba: F00189
# moricz zsigmond korter eszaki iranyba: F02203

DEFAULT_STOP_ID = "F00189"

MAX_RESPONSE_BYTES = 2 * 1024 * 1024

# https://editor.swagger.io/?url=https://opendata.bkk.hu/docs/futar-openapi.yaml
# https://futar.bkk.hu/stop/BKK_F04039?routeIds=%7CBKK_3420
# https://opendata.bkk.hu/data-sources
# https://github.com/tidbyt/community/blob/main/apps/mtatraintime/mtatraintime.star

request_headers = {
    "user-agent": "bkk-tidbyt-service",
    "accept": "application/json, text/plain, */*",
    "accept-language": "en-US,en;q=0.9",
}

def to_hex(i):
    hex = "%x" % i
    if len(hex) == 1:
        hex = "0" + hex
    return hex

def safe_hex(value, fallback):
    value = str(value or "").lstrip("#").lower()
    if len(value) != 6:
        return fallback
    for char in value.elems():
        if char not in "0123456789abcdef":
            return fallback
    return value

def get_meta(references, trip_id):
    trips = references.get("trips", {}) if type(references) == "dict" else {}
    routes = references.get("routes", {}) if type(references) == "dict" else {}
    trip = trips.get(trip_id, {}) if type(trips) == "dict" else {}
    route = routes.get(trip.get("routeId"), {}) if type(routes) == "dict" and type(trip) == "dict" else {}
    style = route.get("style", {}) if type(route) == "dict" else {}
    icon = style.get("vehicleIcon", {}) if type(style) == "dict" else {}
    return {
        "name": str(route.get("shortName") or "?")[:12] if type(route) == "dict" else "?",
        "color": safe_hex(icon.get("color") if type(icon) == "dict" else None, "303030"),
        "secondaryColor": safe_hex(icon.get("secondaryColor") if type(icon) == "dict" else None, "ffffff"),
    }

def render_error(message):
    return render.Root(child = render.WrappedText(content = message, width = 62, align = "center", color = "#ff6666"))

def main(config):
    API_KEY = (config.get("api_key") or "").strip()

    if API_KEY == None or API_KEY == "":
        return render_error("Add a BKK API key")

    stop_id = (config.get("stop_id", DEFAULT_STOP_ID) or DEFAULT_STOP_ID).strip()[:32]
    config_stop = stop_id if stop_id.startswith("BKK_") else "BKK_" + stop_id

    timezone = config.get("timezone") or "Europe/Budapest"
    if not time.is_valid_timezone(timezone):
        timezone = "Europe/Budapest"
    now = time.now().in_location(timezone)

    # today_date = now.format("20060102")
    epoch = now.unix

    url = "https://futar.bkk.hu/api/query/v1/ws/otp/api/where/arrivals-and-departures-for-stop.json"
    rep = http.get(
        url,
        headers = request_headers,
        params = {
            "key": API_KEY,
            "version": "3",
            "includeReferences": "true",
            "stopId": config_stop,
            "onlyDepartures": "true",
            "limit": "8",
            "minutesBefore": "0",
            "minutesAfter": "60",
        },
    )
    if rep.status_code != 200:
        return render_error("BKK API unavailable ({})".format(rep.status_code))
    body = rep.body()
    stop_data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    data = stop_data.get("data", {}) if type(stop_data) == "dict" else {}
    entry = data.get("entry", {}) if type(data) == "dict" else {}
    references = data.get("references", {}) if type(data) == "dict" else {}
    stop_times = entry.get("stopTimes", []) if type(entry) == "dict" else []

    all_departures = []
    for stop_time in stop_times[:8]:
        if type(stop_time) != "dict":
            continue
        meta = get_meta(references, stop_time.get("tripId"))
        departure_time = stop_time.get("predictedDepartureTime") or stop_time.get("departureTime") or 0
        time_diff = departure_time - epoch
        if time_diff > 0:
            all_departures.append(
                {
                    "number": meta["name"],
                    "color": meta["color"],
                    "secondaryColor": meta["secondaryColor"] or "ffffff",
                    "name": str(stop_time.get("stopHeadsign") or "Unknown destination")[:120],
                    "time": str(int(math.round(time_diff / 60))),
                },
            )

    column_children = []
    for departure in all_departures:
        column_children.append(
            render.Row(
                children = [
                    render.Box(
                        child = render.Text(
                            content = departure["number"],
                            font = "tom-thumb",
                            color = "#" + departure["secondaryColor"],
                            offset = -1,
                        ),
                        color = "#" + departure["color"],
                        width = 16,
                        height = 8,
                    ),
                    render.Box(
                        color = "#309030",
                        width = 1,
                        height = 8,
                    ),
                    render.Box(
                        child = render.Text(
                            content = departure["time"] + "'",
                            font = "tb-8",
                            color = "#ffffff",
                            offset = 0,
                        ),
                        color = "#309030",
                        width = 12,
                        height = 8,
                    ),
                    render.Box(width = 1, height = 8),
                    render.Marquee(
                        child = render.Text(content = departure["name"], font = "5x8"),
                        width = 34,
                    ),
                ],
            ),
        )

    final_child = render.Column(children = column_children)

    if not column_children:
        # there are no listed departures in the next 60 minutes
        animation_children = []
        for i in range(10):
            for _ in range(7):
                animation_children.append(
                    render.WrappedText(
                        content = "No scheduled departures in the next 60 minutes.",
                        width = 62,
                        color = "#ff" + to_hex(i * 20) + to_hex(i * 10),
                        font = "5x8",
                    ),
                )
        animation_children.extend(animation_children[::-1])
        final_child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Animation(children = animation_children),
        )

    return render.Root(child = final_child, max_age = 60)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "BKK Stop ID",
                desc = "The stop to display departures at.",
                icon = "train",
                default = DEFAULT_STOP_ID,
            ),
            schema.Text(
                id = "api_key",
                name = "BKK API Key",
                desc = "Your BKK OpenData API Key.",
                icon = "key",
                secret = True,
            ),
        ],
    )
