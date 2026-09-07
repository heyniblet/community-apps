"""
Applet: Chicago Divvy
Summary: Chicago Divvy Bikes
Description: Displays the number of Divvy bikes available at a Divvy station.
Author: Will (@wilcot)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/divvy_bike_image.png", DIVVY_BIKE_IMAGE_ASSET = "file")
load("images/lightning_bolt_image.png", LIGHTNING_BOLT_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DIVVY_BIKE_IMAGE = DIVVY_BIKE_IMAGE_ASSET.readall()
LIGHTNING_BOLT_IMAGE = LIGHTNING_BOLT_IMAGE_ASSET.readall()

#Divvy Urls
DIVVY_BIKE_STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_information.json"
DIVVY_BIKE_STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_status.json"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 3000

def safe_station_id(value):
    value = str(value or "")
    if not value or len(value) > 80:
        return ""
    for char in value.elems():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return ""
    return value

def get_stations(url, ttl_seconds):
    rep = http.get(url, ttl_seconds = ttl_seconds)
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "dict" or type(data.get("data")) != "dict" or type(data["data"].get("stations")) != "list":
        return []
    return data["data"]["stations"][:MAX_STATIONS]

def find_station(stations, station_id):
    for station in stations:
        if type(station) == "dict" and str(station.get("station_id") or "") == station_id:
            return station
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station",
                name = "Divvy Station",
                desc = "Station ID from Divvy's official GBFS station_information feed. Existing station selections remain supported.",
                icon = "building",
            ),
        ],
    )

def main(config):
    station_config = config.get("station")
    if station_config == None:  # Generate fake data
        ebikes_available = "3"
        bikes_available = "5"
        station_name = "Halsted & Roscoe"
    else:
        decoded = json.decode(station_config, None)
        station_id = safe_station_id(decoded.get("value") if type(decoded) == "dict" else station_config)
        station = find_station(get_stations(DIVVY_BIKE_STATION_STATUS_URL, 60), station_id)
        station_info = find_station(get_stations(DIVVY_BIKE_STATIONS_URL, 600), station_id)
        if not station or not station_info:
            return render.Root(child = render.WrappedText("Divvy station unavailable", align = "center", width = 64))

        # Number of ebikes
        ebikes = station.get("num_ebikes_available")
        total = station.get("num_bikes_available")
        if type(ebikes) != "int" or type(total) != "int":
            return render.Root(child = render.WrappedText("Divvy data unavailable", align = "center", width = 64))
        ebikes_available = str(max(0, ebikes))

        # bikes_available includes classic and ebikes. Subtracting the ebikes to get classic (non-ebikes) count
        bikes_available = str(max(0, total - ebikes))
        station_name = str(station_info.get("name") or "Unknown station")[:160]
    return render.Root(
        render.Column(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render.Marquee(
                    child = render.Text(
                        content = station_name,
                        font = "5x8",
                    ),
                    width = 64,
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Image(src = DIVVY_BIKE_IMAGE),
                        render.Text(content = bikes_available, font = "6x13"),
                        render.Image(src = LIGHTNING_BOLT_IMAGE),
                        render.Text(content = ebikes_available, font = "6x13"),
                    ],
                ),
            ],
        ),
    )
