"""
Applet: Bay Wheels
Summary: Bay Wheels availability
Description: Shows the availability of bikes and e-bikes at a Bay Wheels station.
Author: Martin Strauss
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/image_bicycle.gif", IMAGE_BICYCLE_ASSET = "file")
load("images/image_lightning.png", IMAGE_LIGHTNING_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE_BICYCLE = IMAGE_BICYCLE_ASSET.readall()
IMAGE_LIGHTNING = IMAGE_LIGHTNING_ASSET.readall()

# TODO: query these from https://gbfs.baywheels.com/gbfs/gbfs.json maybe?
STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/bay/en/station_information.json"
STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/bay/en/station_status.json"

DEFAULT_STATION = '{ "display": "18th St at Noe St", "value": "cd7359fc-6798-48ed-af32-9d5f6cff9ffa"}'
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_STATIONS = 2000

def main(config):
    station_id, station_name = station_selection(config.get("station_id", DEFAULT_STATION))

    all_statuses = stations_from_response(fetch_cached(STATUS_URL, 60))
    station_info = find_station(stations_from_response(fetch_cached(STATIONS_URL, 86400)), station_id)
    if station_info:
        station_name = str(station_info.get("name", station_name))[:120]

    ebikes = 0
    bikes = 0
    stationStatus = [status for status in all_statuses if status.get("station_id") == station_id]

    if len(stationStatus) > 0:
        stationStatus = stationStatus[0]

        # The Lyft API renders the total number of bikes, and the number of those that are
        # e-bikes, so we calculate the number of "classic" bikes.
        total = safe_count(stationStatus.get("num_bikes_available"))
        ebikes = min(total, safe_count(stationStatus.get("num_ebikes_available")))
        bikes = max(0, total - ebikes)

    return render.Root(
        child = render.Column(
            cross_align = "end",
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(station_name),
                        ),
                        render.Box(width = 64, height = 1, color = "#FFF"),
                    ],
                ),
                render.Row(
                    main_align = "space_around",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = IMAGE_BICYCLE, width = 32, height = 18),
                        render.Column(
                            main_align = "space_evenly",
                            cross_align = "end",
                            expanded = True,
                            children = [
                                render.Text("%d" % bikes),
                                render.Row(
                                    children = [
                                        render.Image(src = IMAGE_LIGHTNING, width = 8, height = 8),
                                        render.Text("%d" % ebikes),
                                    ],
                                ),
                            ],
                        ),
                    ],
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
                name = "Bay Wheels Station ID",
                desc = "Station ID from the public Bay Wheels GBFS feed. Existing nearby-station selections continue to work.",
                icon = "bicycle",
            ),
        ],
    )

def station_selection(raw):
    parsed = json.decode(raw, None) if type(raw) == "string" else None
    if type(parsed) == "dict":
        station_id = parsed.get("value")
        display = parsed.get("display", "Bay Wheels")
    else:
        station_id = raw
        display = "Bay Wheels"
    station_id = str(station_id or "").strip()
    if not station_id or len(station_id) > 128 or "\r" in station_id or "\n" in station_id:
        return "cd7359fc-6798-48ed-af32-9d5f6cff9ffa", "18th St at Noe St"
    return station_id, str(display or "Bay Wheels")[:120]

def stations_from_response(result):
    data = result.get("data", {}) if type(result) == "dict" else {}
    stations = data.get("stations", []) if type(data) == "dict" else []
    return [station for station in stations[:MAX_STATIONS] if type(station) == "dict" and type(station.get("station_id")) == "string"] if type(stations) == "list" else []

def find_station(stations, station_id):
    for station in stations:
        if station.get("station_id") == station_id:
            return station
    return None

def safe_count(value):
    return max(0, int(value)) if type(value) in ["int", "float"] else 0

def fetch_cached(url, ttl):
    res = http.get(url, ttl_seconds = ttl)
    if res.status_code != 200:
        return {}
    body = res.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    return data if type(data) == "dict" else {}
