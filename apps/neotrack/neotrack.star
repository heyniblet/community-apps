"""
Applet: NEOTrack
Summary: Near Earth Object Tracker
Description: Shows the closest object on approach to Earth today according to NASA's NeoW API.
Author: brettohland
"""

load("http.star", "http")
load("images/asteroid.gif", ASTEROID_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ASTEROID = ASTEROID_ASSET.readall()

CAD_URL = "https://ssd-api.jpl.nasa.gov/cad.api"
SBDB_URL = "https://ssd-api.jpl.nasa.gov/sbdb.api"
LUNAR_DISTANCE_AU = 0.00256955529
HEADERS = {"User-Agent": "Niblet/1.0 support@heyniblet.com"}

def main(config):
    if config.get("api_key") != None:
        print("The legacy NASA API key is retained but no longer sent.")
    closest_neo = get_closest_neo()
    if closest_neo == None:
        return render.Root(
            child = render.Box(
                child = render.WrappedText("NASA data unavailable", color = "#FF0000", font = "tom-thumb"),
            ),
        )

    name = "Asteroid " + closest_neo["name"]
    if closest_neo["diameter_km"] != None:
        diameter_km = closest_neo["diameter_km"]
        if diameter_km < 0.1:
            diameter = strip_trailing_zeros(str(diameter_km * 1000)[:4]) + "M"
        else:
            diameter = strip_trailing_zeros(str(diameter_km)[:4]) + "KM"
    else:
        diameter = "H" + closest_neo["magnitude"][:4]

    potentially_hazardous = get_hazard_status(closest_neo["designation"])
    if potentially_hazardous == True:
        border_color = "#F60"
    elif potentially_hazardous == False:
        border_color = "#0F0"
    else:
        border_color = "#888"

    velocity_string = strip_trailing_zeros(str(closest_neo["velocity_km_s"])[:4]) + "K/s"
    lunar_distance = closest_neo["distance_au"] / LUNAR_DISTANCE_AU
    miss_distance_string = strip_trailing_zeros(str(lunar_distance)[:4]) + "LU"

    return render.Root(
        child = render.Row(
            children = [
                render_image_and_scale(border_color, diameter),
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Column(
                        children = [
                            make_data_scroll(None, name),
                            make_data_scroll("V:", velocity_string),
                            make_data_scroll("D:", miss_distance_string),
                            make_data_scroll("O:", "Earth"),
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
                id = "api_key",
                name = "NASA API Key",
                desc = "NASA API key for NeoW API.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def get_closest_neo():
    response = http.get(
        CAD_URL,
        params = {
            "date-min": "now",
            "date-max": "+2",
            "diameter": "true",
            "dist-max": "0.2",
            "fullname": "true",
            "limit": "50",
            "sort": "dist",
        },
        headers = HEADERS,
        ttl_seconds = 3600,
    )
    if response.status_code != 200:
        return None
    payload = response.json()
    if type(payload) != "dict" or type(payload.get("signature")) != "dict" or payload["signature"].get("version") != "1.5":
        return None
    fields = payload.get("fields")
    rows = payload.get("data")
    if type(fields) != "list" or type(rows) != "list":
        return None
    positions = {field: index for index, field in enumerate(fields)}
    required = ["des", "cd", "dist", "v_rel", "h", "diameter"]
    if len([field for field in required if field not in positions]) > 0:
        return None

    now = time.now().unix
    for row in rows:
        if type(row) != "list" or len(row) != len(fields):
            continue
        values = [row[positions[field]] for field in ["des", "cd", "dist", "v_rel", "h"]]
        if len([value for value in values if type(value) != "string" or value.strip() == ""]) > 0:
            continue
        approach = time.parse_time(row[positions["cd"]], "2006-Jan-02 15:04", "UTC").unix
        if approach < now:
            continue
        name = row[positions["fullname"]] if "fullname" in positions else row[positions["des"]]
        diameter = row[positions["diameter"]]
        return {
            "designation": row[positions["des"]],
            "diameter_km": float(diameter) if type(diameter) == "string" and diameter != "" else None,
            "distance_au": float(row[positions["dist"]]),
            "magnitude": row[positions["h"]],
            "name": name.strip(),
            "velocity_km_s": float(row[positions["v_rel"]]),
        }
    return None

def get_hazard_status(designation):
    response = http.get(SBDB_URL, params = {"sstr": designation}, headers = HEADERS, ttl_seconds = 86400)
    if response.status_code != 200:
        return None
    payload = response.json()
    if type(payload) != "dict" or type(payload.get("signature")) != "dict" or payload["signature"].get("version") != "1.3":
        return None
    obj = payload.get("object")
    if type(obj) != "dict" or type(obj.get("pha")) != "bool":
        return None
    return obj["pha"]

# Creates the data display component with the prefix (fixed) and the data (scrolling)
def make_data_scroll(prefix, data_string):
    font = "5x8"
    if prefix == None:
        width = 42
    else:
        width = 33
    return render.Row(
        children = [
            render.Text(prefix or "", font = font),
            render.Marquee(
                width = width,
                align = "end",
                child = render.Text(data_string, font = font),
            ),
        ],
    )

# Builds out the righthand column with the image of the asteroid, and scale.
def render_image_and_scale(highlight_color, size_string):
    return render.Column(
        expanded = True,
        # main_align = "end",
        children = [
            render.Box(width = 1, height = 1),
            render.Stack(
                children = [
                    render.Box(width = 20, height = 20, color = highlight_color),
                    render.Padding(
                        pad = 1,
                        child = render.Image(ASTEROID, width = 18, height = 18),
                    ),
                ],
            ),
            render.Box(width = 1, height = 2),
            render.Row(
                children = [
                    render.Box(width = 1, height = 2, color = "#fff"),
                    render.Column(
                        children = [
                            render.Box(width = 18, height = 1, color = "#000"),
                            render.Box(width = 18, height = 1, color = "#FFF"),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#fff"),
                ],
            ),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Marquee(
                    width = 20,
                    align = "center",
                    child = render.Text(size_string, font = "CG-pixel-3x5-mono"),
                ),
            ),
        ],
    )

# Convets numerical strings with trailing zero characters ("0") to whole numbers.
# eg. "8.00" becomes "8", "9.01" will remain "9.01".
def strip_trailing_zeros(value):
    # Loop through and remove any and all trailing "0" characters
    for _ in range(len(value)):
        value = value.removesuffix("0")

    # Remove a trailing decimal separator if present
    value = value.removesuffix(".")
    return value
