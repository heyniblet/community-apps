"""
Applet: ISS Tracker
Summary: Tracks the ISS Position
Description: Tracks the position of the International Space Station using LAT/LONG coordinates.
Author: Chris Jones (@IPv6Freely)
"""

load("http.star", "http")
load("images/iss_logo.png", ISS_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ISS_LOGO = ISS_LOGO_ASSET.readall()

ISS_URL = "https://api.wheretheiss.at/v1/satellites/25544"

def get_ISS():
    resp = http.get(ISS_URL)

    if resp.status_code != 200:
        return None

    data = resp.json()
    if type(data) != "dict":
        return None

    timestamp_value = data.get("timestamp")
    lat = data.get("latitude")
    lon = data.get("longitude")
    if type(timestamp_value) not in ["int", "float"] or type(lat) not in ["int", "float"] or type(lon) not in ["int", "float"]:
        return None
    timestamp = time.from_timestamp(int(timestamp_value)).format("15:04:03")

    return timestamp, lat, lon

def main():
    position = get_ISS()
    if position == None:
        return render.Root(child = render.WrappedText("ISS position unavailable", width = 64, align = "center"))
    timestamp, lat, lon = position

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 22,
                        child = render.Image(width = 20, height = 20, src = ISS_LOGO),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lat)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lon)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(timestamp)),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
