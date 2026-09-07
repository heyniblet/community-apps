"""
Applet: Divvy
Summary: Divvy Bike availability
Description: Shows the availability of bikes and e-bikes at a Divvy Bike station.
Author: Andy Day (@adayNU)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/lyft_icon.png", LYFT_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

LYFT_ICON = LYFT_ICON_ASSET.readall()

STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_information.json"
STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_status.json"
DEFAULT_STATION = '{"id":"1789242536879942642","name":"Halsted St & Fulton St"}'
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 3000

def main(config):
    station_id, station_name = station_selection(config.get("station_id", DEFAULT_STATION))
    status = find_station(fetch_stations(STATION_STATUS_URL, 60), station_id)
    info = find_station(fetch_stations(STATIONS_URL, 3600), station_id)
    if info:
        station_name = str(info.get("name") or station_name)[:120]
    if not status:
        text = "Station\nunavailable"
    else:
        total = safe_count(status.get("num_bikes_available"))
        ebikes = min(total, safe_count(status.get("num_ebikes_available")))
        text = "Bikes:" + str(total - ebikes) + "\nE-Bikes:" + str(ebikes)

    return render.Root(
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(station_name),
                        ),
                        render.Box(width = 64, height = 1, color = "#4338ca"),
                    ],
                ),
                render.Box(
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = LYFT_ICON, width = 20),
                            render.WrappedText(content = text, font = "tb-8"),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station_id",
                name = "Divvy Station ID",
                desc = "Station ID from Divvy's public GBFS feed. Existing station selections remain supported.",
                icon = "bicycle",
                default = DEFAULT_STATION,
            ),
        ],
    )

def station_selection(raw):
    parsed = json.decode(raw, None) if type(raw) == "string" else None
    if type(parsed) == "dict":
        station_id = parsed.get("id") or parsed.get("value")
        station_name = parsed.get("name") or parsed.get("display") or "Divvy station"
    else:
        station_id = raw
        station_name = "Divvy station"
    station_id = str(station_id or "").strip()
    if not station_id or len(station_id) > 128 or "\r" in station_id or "\n" in station_id:
        return "1789242536879942642", "Halsted St & Fulton St"
    return station_id, str(station_name)[:120]

def fetch_stations(url, ttl_seconds):
    response = http.get(url, ttl_seconds = ttl_seconds)
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    nested = data.get("data") if type(data) == "dict" else None
    stations = nested.get("stations") if type(nested) == "dict" else None
    return [station for station in stations[:MAX_STATIONS] if type(station) == "dict"] if type(stations) == "list" else []

def find_station(stations, station_id):
    for station in stations:
        if str(station.get("station_id") or "") == station_id:
            return station
    return None

def safe_count(value):
    return min(10000, max(0, int(value))) if type(value) in ["int", "float"] else 0
