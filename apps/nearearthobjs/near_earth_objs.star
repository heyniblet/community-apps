"""
Applet: Near Earth Objs
Summary: Show next near earth object
Description: Displays the name, speed, distance, and arrival of the next near Earth object.
Author: noahcolvin
"""

load("http.star", "http")
load("images/image.png", IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

IMAGE = IMAGE_ASSET.readall()
URL = "https://ssd-api.jpl.nasa.gov/cad.api?date-min=now&date-max=%2B7&dist-max=0.2&sort=date&limit=50&fullname=true"
AU_KM = 149597870.7
KM_TO_MILES = 0.621371

# Image derived from Pixabay asset 5636947.

def main(config):
    metric = config.bool("metric") or False
    closest = get_soonest_neo()

    if closest == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Image(src = IMAGE, width = 15, height = 10),
                    render.WrappedText(content = "No objects found... phew!", font = "5x8"),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Marquee(
                    child = render.Text(content = closest["name"], font = "tb-8"),
                    width = 64,
                    scroll_direction = "horizontal",
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = IMAGE, width = 15, height = 10),
                        render.Text(content = str(neo_relative_time(closest)), font = "tb-8"),
                    ],
                ),
                render.Marquee(
                    child = render.Row(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Text(content = neo_distance(closest, metric), font = "tb-8"),
                            render.Text(content = " @ ", font = "tb-8"),
                            render.Text(content = neo_speed(closest, metric), font = "tb-8"),
                        ],
                    ),
                    width = 64,
                    scroll_direction = "horizontal",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "metric",
                name = "Use Kilometers",
                desc = "Whether to display distance and speed in kilometers.",
                icon = "meteor",
                default = False,
            ),
        ],
    )

def get_soonest_neo():
    resp = http.get(URL, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None
    payload = resp.json()
    if type(payload) != "dict" or type(payload.get("signature")) != "dict":
        return None
    if payload["signature"].get("version") != "1.5":
        return None
    fields = payload.get("fields")
    rows = payload.get("data")
    if type(fields) != "list" or type(rows) != "list" or len(rows) == 0 or type(rows[0]) != "list":
        return None

    positions = {field: index for index, field in enumerate(fields)}
    required = ["des", "cd", "dist", "v_rel"]
    if len([field for field in required if field not in positions]) > 0:
        return None
    now = time.now().unix
    for row in rows:
        if type(row) != "list" or len(row) != len(fields):
            continue
        name = row[positions["fullname"]] if "fullname" in positions else row[positions["des"]]
        values = [name, row[positions["cd"]], row[positions["dist"]], row[positions["v_rel"]]]
        if len([value for value in values if type(value) != "string" or value.strip() == ""]) > 0:
            continue
        approach = time.parse_time(row[positions["cd"]], "2006-Jan-02 15:04", "UTC").unix
        if approach < now:
            continue
        return {
            "name": name.strip(),
            "approach": approach,
            "distance_au": float(row[positions["dist"]]),
            "speed_km_s": float(row[positions["v_rel"]]),
        }
    return None

def neo_speed(neo, metric):
    speed = neo["speed_km_s"] * 3600
    if not metric:
        speed = speed * KM_TO_MILES
    return "{} {}".format(format_number(int(speed)), "km/h" if metric else "mph")

def neo_distance(neo, metric):
    distance = neo["distance_au"] * AU_KM
    if not metric:
        distance = distance * KM_TO_MILES
    return "{} {}".format(format_number(int(distance)), "km" if metric else "miles")

def neo_relative_time(neo):
    return time.from_timestamp(neo["approach"]) - time.from_timestamp(time.now().unix)

def format_number(number):
    digits = str(number)
    if len(digits) < 4:
        return digits
    count = 0
    result = ""
    for digit in reversed(digits.elems()):
        result = digit + result
        count += 1
        if count == 3:
            result = "," + result
            count = 0
    return result.strip(",")
