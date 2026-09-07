"""
Applet: Boris Bikes
Summary: London street bikes
Description: Availability for a Santander bicycle dock in London.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bike_image.png", BIKE_IMAGE_ASSET = "file")
load("images/lightning_image.png", LIGHTNING_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BIKE_IMAGE = BIKE_IMAGE_ASSET.readall()
LIGHTNING_IMAGE = LIGHTNING_IMAGE_ASSET.readall()

# Unceremoniously nicked from Martin Strauss's baywheels app

# Hackney is for cycling.
DEFAULT_DOCK_ID = "BikePoints_21"

DOCK_URL = "https://api.tfl.gov.uk/BikePoint/%s"
USER_AGENT = "Tidbyt boris_bikes"
MAX_RESPONSE_BYTES = 512 * 1024

def app_key(config):
    return config.get("tfl_app_key") or ""  # Fall back to freebie quota

def fetch_dock(dock_id, config):
    if not dock_id.startswith("BikePoints_") or len(dock_id) > 32:
        return None
    for char in dock_id[len("BikePoints_"):].elems():
        if char not in "0123456789":
            return None
    params = {}
    if app_key(config):
        params["app_key"] = app_key(config)
    resp = http.get(
        DOCK_URL % dock_id,
        params = params,
        headers = {
            "User-Agent": USER_AGENT,
        },
    )
    if resp.status_code != 200:
        print("TFL BikePoint request failed with status ", resp.status_code)
        return None
    body = resp.body()
    return json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None

def tidy_name(name):
    if not name:
        print("TFL BikePoint request did not contain dock name")
        return "Unknown dock"

    # Don't need the bit of town, user chose the location.
    comma = name.rfind(",")
    name = name[:comma].strip() if comma >= 0 else name.strip()

    # Abbreviate some common words to fit on screen better.
    words = name.split(" ")
    for i in range(len(words)):
        if words[i] == "Street":
            words[i] = "St"
        if words[i] == "Road":
            words[i] = "Rd"
        if words[i] == "Avenue":
            words[i] = "Ave"

    return " ".join(words)

def get_dock(dock_id, config):
    resp = fetch_dock(dock_id, config)
    if not resp:
        return "No data", "?", "?"
    name = tidy_name(resp.get("commonName"))
    acoustic_count = 0
    electric_count = 0
    for property in resp.get("additionalProperties", [])[:100]:
        if type(property) != "dict":
            continue
        if property["key"] == "NbStandardBikes":
            acoustic_count = int(property["value"])
        if property["key"] == "NbEBikes":
            electric_count = int(property["value"])
    return name, acoustic_count, electric_count

def main(config):
    dock = config.get("dock")
    if dock:
        decoded = json.decode(dock, None)
        dock_id = str(decoded.get("value") or decoded.get("id") or "").strip() if type(decoded) == "dict" else str(dock).strip()
    else:
        dock_id = DEFAULT_DOCK_ID
    dock_name, acoustic_count, electric_count = get_dock(dock_id, config)

    return render.Root(
        max_age = 120,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Marquee(
                        child = render.Text(dock_name),
                        scroll_direction = "horizontal",
                        width = 62,
                        height = 8,
                    ),
                ),

                # Bike picture
                render.Padding(
                    pad = (1, 7, 0, 0),
                    child = render.Image(BIKE_IMAGE),
                ),

                # Bike stats
                render.Padding(
                    pad = (44, 8, 0, 0),
                    child = render.Stack(
                        children = [
                            # Acoustic bikes
                            render.Padding(
                                pad = (9, 4, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(acoustic_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
                            # Electric bikes
                            render.Padding(
                                pad = (0, 14, 0, 0),
                                child = render.Image(
                                    src = LIGHTNING_IMAGE,
                                    width = 8,
                                    height = 8,
                                ),
                            ),
                            render.Padding(
                                pad = (9, 14, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(electric_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
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
                id = "tfl_app_key",
                name = "TfL App Key",
                desc = "Your TfL app key. See https://api-portal.tfl.gov.uk/",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "dock",
                name = "Dock ID",
                desc = "TfL BikePoint ID, for example BikePoints_21. Existing saved locations still work.",
                icon = "bicycle",
                default = DEFAULT_DOCK_ID,
            ),
        ],
    )
