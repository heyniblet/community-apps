load("encoding/json.star", "json")
load("http.star", "http")
load("images/img_bike_src.jpg", IMG_BIKE_SRC_ASSET = "file")
load("images/img_park_src.png", IMG_PARK_SRC_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMG_BIKE_SRC = IMG_BIKE_SRC_ASSET.readall()
IMG_PARK_SRC = IMG_PARK_SRC_ASSET.readall()

STATION_INFORMATION_URL = "https://gbfs.lyft.com/gbfs/2.3/bkn/en/station_information.json"
STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/bkn/en/station_status.json"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 3000

def get_stations(url, ttl_seconds):
    resp = http.get(url, ttl_seconds = ttl_seconds)
    body = resp.body()
    data = json.decode(body, None) if resp.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "dict" or type(data.get("data")) != "dict" or type(data["data"].get("stations")) != "list":
        return []
    return data["data"]["stations"][:MAX_STATIONS]

w = 15
h = int(w * 0.75)

img_bike = render.Image(src = IMG_BIKE_SRC, width = w, height = h)

img_park = render.Image(src = IMG_PARK_SRC, width = w, height = h)

############ STATION IDs
def pop_stations(data):
    dic = {}
    for s in data:
        if type(s) == "dict" and type(s.get("name")) == "string" and s.get("station_id") != None:
            dic.update({s["name"][:160]: str(s["station_id"])})
    return dict(sorted(dic.items()))

###########

def get_info(stat_name, kind, bike_data, station_list):
    station_id = station_list.get(stat_name)
    info = None
    for item in bike_data:
        if type(item) == "dict" and str(item.get("station_id") or "") == station_id:
            info = item
            break
    if not info or type(info.get("num_docks_available")) != "int" or type(info.get("num_bikes_available")) != "int":
        return None
    docs_avail = max(0, info["num_docks_available"])
    bikes_avail = max(0, info["num_bikes_available"])
    res = {
        "docks": "  Docks: " + str(docs_avail),
        "bikes": "  Bikes: " + str(bikes_avail),
    }
    return res[kind]

def get_col_children(stat_name, bike_data, station_list):
    bikes = get_info(stat_name, "bikes", bike_data, station_list)
    docks = get_info(stat_name, "docks", bike_data, station_list)
    if bikes == None or docks == None:
        return None
    l = []
    l.append(render.Marquee(child = render.Text(stat_name, color = "#45b6fe"), width = 70, scroll_direction = "horizontal"))
    l.append(render.Row(children = [img_bike, render.Text(bikes)], cross_align = "center"))
    l.append(render.Row(children = [img_park, render.Text(docks)], cross_align = "center"))
    l.append(render.Text(""))
    return l

def get_stat_col(stat_name, bike_data, station_list):
    l = get_col_children(stat_name, bike_data, station_list)
    return render.Column(children = l) if l else None

def get_col_list(bike_data, station_list):
    col_list = [get_stat_col(s, bike_data, station_list) for s in station_list]
    return col_list

def main(config):
    station_ids = pop_stations(get_stations(STATION_INFORMATION_URL, 600))
    data_bikes = get_stations(STATION_STATUS_URL, 60)
    if not station_ids or not data_bikes:
        return render.Root(child = render.WrappedText("Citi Bike data unavailable", align = "center", width = 64))
    default = station_ids.keys()[0]
    option = config.get("search_station", default)
    decoded = json.decode(option, None)
    station_name = str(decoded.get("value") if type(decoded) == "dict" else option)[:160]
    if station_name not in station_ids:
        return render.Root(child = render.WrappedText("Citi Bike station unavailable", align = "center", width = 64))
    info = get_stat_col(station_name, data_bikes, station_ids)
    if info == None:
        return render.Root(child = render.WrappedText("Citi Bike status unavailable", align = "center", width = 64))
    return render.Root(
        child = info,
        delay = 80,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "search_station",
                name = "Station",
                desc = "Exact station name from Citi Bike's official GBFS station_information feed. Existing selections remain supported.",
                icon = "gear",
            ),
        ],
    )
