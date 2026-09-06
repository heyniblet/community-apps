"""
Applet: Indego Stations
Summary: Indego station availability
Description: The user selects an Indego (Philadelphia BIKE share) station and Tidbyt will regularly display the number of regular and electric bikes available.
Author: RayPatt
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bike.png", BIKE_ASSET = "file")
load("images/ebike.png", EBIKE_ASSET = "file")
load("images/lightning.png", LIGHTNING_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BIKE = BIKE_ASSET.readall()
EBIKE = EBIKE_ASSET.readall()
LIGHTNING = LIGHTNING_ASSET.readall()

url = "https://kiosks.bicycletransit.workers.dev/phl"

def main(config):
    rep = http.get(url, ttl_seconds = 60)
    body = rep.body()
    data = json.decode(body, {}) if rep.status_code == 200 and body and len(body) <= 1024 * 1024 else {}
    features = data.get("features", []) if type(data) == "dict" else []
    selected = config.get("Station", "1")
    if type(features) != "list" or type(selected) != "string" or not selected.isdigit():
        return error_frame()
    station_no = int(selected)
    if station_no < 0 or station_no >= len(features) or type(features[station_no]) != "dict":
        return error_frame()
    properties = features[station_no].get("properties", {})
    name = properties.get("name") if type(properties) == "dict" else None
    bikes = properties.get("classicBikesAvailable") if type(properties) == "dict" else None
    ebikes = properties.get("electricBikesAvailable") if type(properties) == "dict" else None
    if type(name) != "string" or type(bikes) not in ["int", "float"] or type(ebikes) not in ["int", "float"]:
        return error_frame()
    name = name[:120]

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(child = render.Text(name), width = 64),
                render.Row(
                    expanded = False,
                    children = [
                        render.Column(
                            expanded = True,
                            children = [
                                render.Image(src = BIKE),
                            ],
                        ),
                        render.Row(
                            cross_align = "start",
                            children = [
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text(" " + str(int(bikes))),
                                        render.Text(" " + str(int(ebikes))),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "start",
                                    children = [
                                        render.Text(" Bikes"),
                                        render.Row(
                                            children = [
                                                render.Image(src = LIGHTNING),
                                                render.Text("Bikes"),
                                            ],
                                        ),
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
                id = "Station",
                name = "Station Number",
                desc = "The zero-based station number from the Indego feed. Existing selections remain valid.",
                icon = "brush",
                default = "1",
            ),
        ],
    )

def error_frame():
    return render.Root(child = render.WrappedText(content = "Indego station unavailable", width = 64, color = "#f00"))
