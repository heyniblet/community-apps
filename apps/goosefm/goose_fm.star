"""
Applet: Goose FM
Summary: Info on Goose.fm
Description: Info for the music service Goose.fm. Supports station overview and individual station data.
Author: jqr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_WIDTH = 64
MAX_HEIGHT = 32
DEFAULT_TTL = 30
MAX_RESPONSE_BYTES = 256 * 1024
STATIONS_URL = "https://goose.fm/stations/"

def main(config):
    callsign = (config.str("callsign") or "").strip().upper()[:10]
    stations = list_stations()
    if not callsign:
        return render_station_overview(stations)
    for station in stations:
        if station["callsign"] == callsign:
            return render.Root(render_station(station))
    return render.Root(render.Text("Station unavailable"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "callsign",
                name = "Station Callsign",
                desc = "Show detailed info about a single station.",
                icon = "towerBroadcast",
            ),
        ],
    )

def get_json(url, ttl_seconds = DEFAULT_TTL):
    response = http.get(url, headers = {"Accept": "application/json"}, ttl_seconds = ttl_seconds)
    body = response.body()
    return json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None

def render_station_overview(stations):
    if not stations:
        return render.Root(render.Text("Goose FM unavailable"))
    rows = []

    for station in stations:
        rows.append(render_station_with_listeners(station))

    return render.Root(
        render.Marquee(render.Column(rows), scroll_direction = "vertical", height = MAX_HEIGHT),
    )

def list_stations():
    results = []
    payload = get_json(STATIONS_URL)
    for station in payload[:50] if type(payload) == "list" else []:
        if type(station) != "dict":
            continue
        callsign = station.get("callsign")
        listeners = station.get("listeners")
        if type(callsign) != "string" or not callsign or type(listeners) not in ("int", "float"):
            continue
        results.append({
            "callsign": callsign.upper()[:10],
            "listeners": int(listeners),
            "dj": clean_text(station.get("dj")),
            "song_title": clean_text(station.get("title")),
            "song_artist": clean_text(station.get("artist")),
        })

    return results

def clean_text(value):
    return " ".join(value.split())[:100] if type(value) == "string" else ""

def render_station(station, width = MAX_WIDTH):
    return render.Column(
        [
            render_station_with_listeners(station),
            render.Marquee(render.Text(station["dj"], color = "c44"), width = width),
            render.Marquee(render.Text(station["song_title"], color = "#fff"), width = width),
            render.Marquee(render.Text(station["song_artist"], color = "#ccc"), width = width),
        ],
    )

def render_station_with_listeners(station):
    callsign = station["callsign"]
    listeners = station["listeners"]

    station_color = ternary(listeners == 0, "#666", "#f66")
    listner_color = ternary(listeners == 0, "#666", "#3f3")
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(callsign, color = station_color),
            render.Text("%i" % listeners, color = listner_color),
        ],
    )

def ternary(condition, true_color, false_color):
    if condition:
        return true_color
    else:
        return false_color
