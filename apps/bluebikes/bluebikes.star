"""
Applet: Bluebikes
Summary: Boston Bluebikes Status
Description: Displays Boston Bluebike Station Status (Available Bikes, E-Bikes, Docks).
Author: eric-pierce
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/bluebike_image.png", BLUEBIKE_IMAGE_ASSET = "file")
load("images/electric_bike_image.png", ELECTRIC_BIKE_IMAGE_ASSET = "file")
load("images/lightning_bolt_image.png", LIGHTNING_BOLT_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BLUEBIKE_IMAGE = BLUEBIKE_IMAGE_ASSET.readall()
ELECTRIC_BIKE_IMAGE = ELECTRIC_BIKE_IMAGE_ASSET.readall()
LIGHTNING_BOLT_IMAGE = LIGHTNING_BOLT_IMAGE_ASSET.readall()

#Bluebikes Urls
BLUEBIKE_STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_information.json"
BLUEBIKE_STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_status.json"
BLUEBIKE_MISSING_DATA = "DATA_NOT_FOUND"

#Images

#Station cache names
STATION_NAME_CACHE_SUFFIX = "_station_name"
STATION_STATUS_NAME_SUFFIX = "_station_status"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 2000

def response_stations(rep):
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    stations = data.get("data", {}).get("stations", []) if type(data) == "dict" else []
    return [station for station in stations[:MAX_STATIONS] if type(station) == "dict"] if type(stations) == "list" else []

def count(value):
    if type(value) == "int":
        return max(0, value)
    value = str(value or "")
    for char in value.elems():
        if char not in "0123456789":
            return 0
    return int(value) if value else 0

def find_station_status_by_id(station_id):
    station_status_cached = cache.get(station_id + STATION_STATUS_NAME_SUFFIX)
    if station_status_cached != None:
        station_status = json.decode(station_status_cached, None)
        if type(station_status) == "dict":
            return station_status
    else:
        rep = http.get(BLUEBIKE_STATION_STATUS_URL)
        station_list = response_stations(rep)
        for station in station_list:
            if station["station_id"] == station_id:
                station_status = station
                cache.set(station_id + STATION_STATUS_NAME_SUFFIX, json.encode(station_status), ttl_seconds = 30)
                return station_status

    #unable to retrieve station status
    return BLUEBIKE_MISSING_DATA

def find_station_name_by_id(station_id):
    station_name = ""
    station_name_cached = cache.get(station_id + STATION_NAME_CACHE_SUFFIX)
    if station_name_cached != None:
        station_name = station_name_cached
    else:
        rep = http.get(BLUEBIKE_STATIONS_URL)
        station_list = response_stations(rep)
        for station in station_list:
            if station["station_id"] == station_id:
                station_name = station["name"]
                break
        cache.set(station_id + STATION_NAME_CACHE_SUFFIX, station_name, ttl_seconds = 600)
    return station_name

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station",
                name = "Bluebike Station ID",
                desc = "Station ID from the Bluebikes GBFS feed; existing saved searches still work.",
                icon = "building",
            ),
        ],
    )

def main(config):
    station_config = config.get("station")
    if station_config == None:  # Generate fake data
        ebikes_available = "8"
        bikes_available = "2"
        docks_available = "5"
        station_name = "Fenway Outfield"
    else:
        decoded = json.decode(station_config, None)
        station_id = str(decoded.get("value") or decoded.get("station_id") or "").strip() if type(decoded) == "dict" else str(station_config).strip()
        station = find_station_status_by_id(station_id)
        if station == BLUEBIKE_MISSING_DATA:
            station = {}

        # Number of ebikes
        ebikes_available = str(count(station.get("num_ebikes_available")))

        # Number of docks
        docks_available = str(count(station.get("num_docks_available")))

        # bikes_available includes classic and ebikes. Subtracting the ebikes to get classic (non-ebikes) count
        bikes_available = str(max(0, count(station.get("num_bikes_available")) - count(station.get("num_ebikes_available"))))
        station_name = find_station_name_by_id(station_id = station_id)
        if not station_name:
            station_name = "Station unavailable"
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
                        render.Image(src = BLUEBIKE_IMAGE),
                        render.Text(content = bikes_available, font = "6x13"),
                        #render.Image(src = ELECTRIC_BIKE_IMAGE),
                        render.Image(src = LIGHTNING_BOLT_IMAGE),
                        render.Text(content = ebikes_available, font = "6x13"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text(content = "Docks:", font = "5x8", color = "4683B7"),
                        render.Text(content = docks_available, font = "5x8", color = "4683B7"),
                    ],
                ),
            ],
        ),
    )
