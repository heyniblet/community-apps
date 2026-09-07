load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{"lat":45.6,"lng":"-122.64","locality":"Portland, OR","timezone":"America/Los_Angeles"}
"""
DEFAULT_STOP = "13043"
URL = "https://developer.trimet.org/ws/V2/arrivals"

def main(config):
    api_key = config.str("trimet_api_key")

    # font_sm = config.get("font-sm", "tom-thumb")
    font_sm = config.get("font-sm", "CG-pixel-3x5-mono")
    font_lg = config.get("font-lg", "6x13")
    stop = config.str("stop", DEFAULT_STOP)
    if not api_key:
        return render.Root(child = render.Text("API key missing", font = "5x8"))
    if not stop or len(stop) > 12 or any([c not in "0123456789" for c in stop.elems()]):
        return render.Root(child = render.Text("Invalid stop ID", font = "5x8"))
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone).format("1/2 3:04 PM")

    response = http.get(URL, params = {"locIDs": stop, "appID": api_key, "json": "true"})
    if response.status_code != 200:
        return render.Root(child = render.Text("TriMet unavailable", font = "5x8"))
    rep = response.json()
    result = rep.get("resultSet", {})
    arrivals = result.get("arrival", [])
    locations = result.get("location", [])
    if not arrivals or not locations:
        return render.Root(child = render.Text("No arrivals", font = "5x8"))
    timestamp = arrivals[0].get("estimated") or arrivals[0].get("scheduled")
    if timestamp == None:
        return render.Root(child = render.Text("No arrival time", font = "5x8"))
    est = int(timestamp)
    conv = time.from_timestamp(est // 1000).in_location(timezone).format("3:04 PM")

    stop = locations[0].get("desc", "TriMet stop")

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%s" % stop,
                    font = font_sm,
                ),
                render.Text(
                    content = "%s" % conv,
                    font = font_lg,
                ),
                render.Text(
                    content = "%s" % now,
                    font = font_sm,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "Enter a TriMet Stop ID",
                icon = "bus",
                default = DEFAULT_STOP,
            ),
            # schema.Location(
            #     id = "location",
            #     name = "Location",
            #     desc = "Location for which to display time.",
            #     icon = "locationDot",
            # ),
            schema.Text(
                id = "trimet_api_key",
                name = "TriMet API Key",
                desc = "A TriMet API key to access the TriMet API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
