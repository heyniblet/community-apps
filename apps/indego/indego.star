"""
Applet: Indego
Summary: Indego bike share
Description: Shows available bikes and docks at an Indego station.
Author: radiocolin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bike_dock.png", BIKE_DOCK_ASSET = "file")
load("images/bike_dock_gray.png", BIKE_DOCK_GRAY_ASSET = "file")
load("images/electric_bike.png", ELECTRIC_BIKE_ASSET = "file")
load("images/electric_bike_gray.png", ELECTRIC_BIKE_GRAY_ASSET = "file")
load("images/regular_bike.png", REGULAR_BIKE_ASSET = "file")
load("images/regular_bike_gray.png", REGULAR_BIKE_GRAY_ASSET = "file")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")

BIKE_DOCK = BIKE_DOCK_ASSET.readall()
BIKE_DOCK_GRAY = BIKE_DOCK_GRAY_ASSET.readall()
ELECTRIC_BIKE = ELECTRIC_BIKE_ASSET.readall()
ELECTRIC_BIKE_GRAY = ELECTRIC_BIKE_GRAY_ASSET.readall()
REGULAR_BIKE = REGULAR_BIKE_ASSET.readall()
REGULAR_BIKE_GRAY = REGULAR_BIKE_GRAY_ASSET.readall()

indego_api_endpoint = "https://bts-status.bicycletransit.workers.dev/phl"
indego_green = "#93D500"
indego_blue = "#0082CA"
white = "#fff"
default_dock = "3162.0"

def get_indego_data():
    r = http.get(indego_api_endpoint, ttl_seconds = 600)
    body = r.body()
    data = json.decode(body, {}) if r.status_code == 200 and body and len(body) <= 1024 * 1024 else {}
    return data if type(data) == "dict" else {}

def get_dock_info(selected_dock):
    data = get_indego_data()
    r = {}
    features = data.get("features", [])
    if type(features) != "list":
        return r
    for dock in features[:3000]:
        properties = dock.get("properties", {}) if type(dock) == "dict" else {}
        if type(properties) == "dict" and str(properties.get("id")) == selected_dock:
            r["name"] = str(properties.get("name", "Station"))[:120]
            r["docksAvailable"] = safe_count(properties.get("docksAvailable"))
            r["classicBikesAvailable"] = safe_count(properties.get("classicBikesAvailable"))
            r["electricBikesAvailable"] = safe_count(properties.get("electricBikesAvailable"))
            break
    return r

def safe_count(value):
    return int(value) if type(value) in ["int", "float"] and value >= 0 and value <= 10000 else 0

def main(config):
    scale = 2 if canvas.is2x() else 1
    selected_dock = config.str("dock", default_dock)
    if not re.match(r"^[0-9]{1,12}(\.[0-9]+)?$", selected_dock):
        selected_dock = default_dock
    dock_data = get_dock_info(selected_dock)
    if not dock_data:
        return render.Root(child = render.WrappedText("Indego station unavailable", width = 64, align = "center", color = "#f00"))

    if dock_data.get("classicBikesAvailable") > 0:
        regular_bike_color = "#FF9400"
        regular_bike_image = REGULAR_BIKE
    else:
        regular_bike_color = "#999999"
        regular_bike_image = REGULAR_BIKE_GRAY

    if dock_data.get("electricBikesAvailable") > 0:
        electric_bike_color = "#1EB100"
        electric_bike_image = ELECTRIC_BIKE
    else:
        electric_bike_color = "#999999"
        electric_bike_image = ELECTRIC_BIKE_GRAY

    if dock_data.get("docksAvailable") > 0:
        dock_color = "#00A1FE"
        dock_image = BIKE_DOCK
    else:
        dock_color = "#999999"
        dock_image = BIKE_DOCK_GRAY

    header_font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-14"
    data_font = "Dina_r400-6" if scale == 1 else "terminus-12"

    header_height = 7 if scale == 1 else 14
    header_pad = (0, 1, 0, 1) if scale == 1 else (0, 0, 0, 0)
    icon_height = 15 if scale == 1 else 28
    text_height = 10 if scale == 1 else 22

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = header_height, width = 64 * scale, color = "#8C189A", child = render.Padding(pad = header_pad, child = render.Marquee(width = 64 * scale, offset_start = 64 * scale, offset_end = 64 * scale, child = render.Text(dock_data["name"], font = header_font)))),
                        ]),
                        render.Row(children = [
                            render.Column(children = [
                                render.Box(width = 21 * scale, height = icon_height, child = render.Image(src = regular_bike_image, width = 21 * scale, height = icon_height)),
                                render.Box(width = 21 * scale, height = text_height, child = render.Text(str(dock_data["classicBikesAvailable"]), font = data_font, color = regular_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 21 * scale, height = icon_height, child = render.Image(src = electric_bike_image, width = 21 * scale, height = icon_height)),
                                render.Box(width = 21 * scale, height = text_height, child = render.Text(str(dock_data["electricBikesAvailable"]), font = data_font, color = electric_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 22 * scale, height = icon_height, child = render.Image(src = dock_image, width = 21 * scale, height = icon_height)),
                                render.Box(width = 22 * scale, height = text_height, child = render.Text(str(dock_data["docksAvailable"]), font = data_font, color = dock_color)),
                            ]),
                        ]),
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
                id = "dock",
                name = "Dock ID",
                desc = "The numeric Indego station ID to display.",
                icon = "bicycle",
                default = default_dock,
            ),
        ],
    )
