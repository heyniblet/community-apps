# https://developer.trimet.org/ws_docs/arrivals2_ws.shtml

load("encoding/json.star", "json")
load("http.star", "http")
load("images/trimet_logo.png", TRIMET_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TRIMET_LOGO = TRIMET_LOGO_ASSET.readall()

DEFAULT_APP_ID = "PLEASE_REGISTER_WITH_TRIMET"
DEFAULT_LOC_ID = 5103
CACHE_TIME_IN_SECONDS = 30
BUS_COLOR = "#0E4C8C"

def main(config):
    trimet_app_id = config.str("trimet_app_id", "")
    loc_id = config.str("loc_id", str(DEFAULT_LOC_ID))
    if not trimet_app_id or len(trimet_app_id) > 256 or any([c in trimet_app_id for c in [" ", "\t", "\r", "\n"]]) or not loc_id.isdigit() or len(loc_id) > 10:
        return error_frame("TriMet App ID required")

    trimet_data = http.get(
        "https://developer.trimet.org/ws/v2/arrivals",
        params = {"locIDs": loc_id, "appID": trimet_app_id},
    )
    stop_rows = []
    body = trimet_data.body()
    data = json.decode(body, {}) if trimet_data.status_code == 200 and body and len(body) <= 256 * 1024 else {}
    result = data.get("resultSet", {}) if type(data) == "dict" else {}
    locations = result.get("location", []) if type(result) == "dict" else []
    arrivals = result.get("arrival", []) if type(result) == "dict" else []
    if type(locations) == "list" and locations and type(locations[0]) == "dict" and type(arrivals) == "list":
        desc = locations[0].get("desc", "")
        direction = locations[0].get("dir", "")
        if type(desc) != "string" or type(direction) != "string":
            return error_frame("Stop unavailable")
        location_name = "%s - %s" % (desc[:100], direction[:40])

        stop_rows.append(
            render.Row(
                children = [
                    render.Marquee(
                        child = render.Text(location_name),
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        align = "start",
                    ),
                ],
            ),
        )

        for arrival in arrivals[:2]:
            row = add_stop_row(arrival)
            if row != None:
                stop_rows.append(row)
    else:
        return error_frame("Stop unavailable")

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = TRIMET_LOGO),
                render.Column(
                    children = stop_rows,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def add_stop_row(row):
    # trimet sends data in milliseconds since epoch, convert to seconds
    # estimated time is more accurate than scheduled time
    if type(row) != "dict" or type(row.get("route")) not in ["int", "float"]:
        return None
    timestamp = row.get("estimated") if type(row.get("estimated")) in ["int", "float"] else row.get("scheduled")
    if type(timestamp) not in ["int", "float"] or timestamp <= 0:
        return None
    route = str(int(row["route"]))[:8]
    arrival_in_minutes = calculate_arrival_time_in_minutes(time.from_timestamp(int(timestamp * 0.001)))

    return render.Row(
        children = [
            render.Circle(
                color = BUS_COLOR,
                diameter = 10,
                child = render.Marquee(
                    child = render.Text(route),
                    align = "center",
                    width = 10,
                    offset_start = 32,
                    offset_end = 32,
                ),
            ),
            render.Marquee(
                child = render.Text("%s" % arrival_in_minutes),
                align = "start",
                width = 15,
                offset_start = 32,
                offset_end = 32,
            ),
        ],
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
    )

def calculate_arrival_time_in_minutes(arrival):
    delta_arrival = arrival - time.now()

    if (delta_arrival.minutes < 10):
        return " %s" % int(delta_arrival.minutes)
    else:
        return "%s" % int(delta_arrival.minutes)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "trimet_app_id",
                name = "Trimet APP ID",
                desc = "Register here: https://developer.trimet.org/appid/registration/",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "loc_id",
                name = "Trimet Stop ID",
                desc = "The Stop ID that you would like to track with the app.",
                icon = "user",
            ),
        ],
    )

def error_frame(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, color = "#f00"))
