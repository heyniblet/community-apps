"""
Applet: Capital Bikeshare
Summary: Bikeshare status in DC
Description: Reports the number of eBikes and normal bikes available at a given dock in DC.
Author: abrahamrowe
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATION_INFORMATION_URL = "https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json"
STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_status.json"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 2500

def get_stations(url):
    response = http.get(url, ttl_seconds = 60)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return []
    data = json.decode(body, None)
    if type(data) != "dict" or type(data.get("data")) != "dict" or type(data["data"].get("stations")) != "list":
        return []
    return data["data"]["stations"][:MAX_STATIONS]

def render_error(message):
    return render.Root(child = render.WrappedText(message, align = "center", width = 64))

def main(config):
    defaultStationName = "Montello Ave & Holbrook Terr NE"
    stationName = config.str("bikeShareName", defaultStationName)[:160]
    stationID = ""

    # identify the correct station_id
    for item in get_stations(STATION_INFORMATION_URL):
        if type(item) == "dict" and item.get("name") == stationName:
            stationID = str(item.get("station_id") or "")
            break
    if not stationID:
        return render_error("Station not found")

    numberBikes = 0
    numberEBikes = 0
    stationFound = False
    for item in get_stations(STATION_STATUS_URL):
        if type(item) == "dict" and str(item.get("station_id") or "") == stationID:
            total = item.get("num_bikes_available")
            electric = item.get("num_ebikes_available")
            if type(total) == "int" and type(electric) == "int":
                numberEBikes = max(0, electric)
                numberBikes = max(0, total - numberEBikes)
                stationFound = True
            break
    if not stationFound:
        return render_error("Status unavailable")

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 16,
                    color = "#FF6961",
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText(stationName, color = "#000000", font = "5x8"),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text("Bikes: " + str(int(numberBikes)), font = "tb-8"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text("eBikes: " + str(int(numberEBikes)), font = "tb-8"),
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
                id = "bikeShareName",
                name = "Bikeshare Dock Name",
                desc = "Go to https://account.capitalbikeshare.com/map and enter the dock name exactly as it is displayed on the site. For example, 'Walter Reed Dr & 8th St S'.",
                icon = "bicycle",
            ),
        ],
    )
