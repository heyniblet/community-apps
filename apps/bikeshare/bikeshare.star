"""
Applet: Bikeshare
Summary: Bikeshare availability
Description: Shows bike and parking availability for user selected bikeshare locations.
Author: snorremd
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bike_icon.png", BIKE_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BIKE_ICON = BIKE_ICON_ASSET.readall()

DEFAULT_STATUS_URL = "https://gbfs.urbansharing.com/bergenbysykkel.no/station_status.json"
DEFAULT_START = {"id": "5356", "name": "Fløen Bybanestopp"}
DEFAULT_STOP = {"id": "4963", "name": "Kronstad Allmenning"}
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_STATIONS = 5000

# Renders a cute little green bike

# User agent to identify this as a Tidbyt community app when making requests
USER_AGENT = "Tidbyt - Bikeshare (https://github.com/tidbyt/community/tree/main/apps/bikeshare)"

def fetch_status(station):
    if not station or not station["url"].startswith("https://"):
        return None
    station_status_resp = http.get(
        url = station["url"],
        headers = {
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
    )

    if (station_status_resp.status_code != 200):
        print("Bikeshare request failed with status %d", station_status_resp.status_code)
        return None

    body = station_status_resp.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    statuses = data.get("data", {}).get("stations", []) if type(data) == "dict" else []
    for status in statuses[:MAX_STATIONS]:
        if type(status) == "dict" and str(status.get("station_id", "")) == station["id"]:
            return status
    return None

def parse_station(value, fallback, status_url):
    decoded = json.decode(value, None) if value else None
    if type(decoded) == "dict":
        details = decoded.get("station", {})
        if type(details) != "dict":
            return None
        station_id = str(details.get("station_id", "")).strip()
        name = str(details.get("name", station_id)).strip()
        url = decoded.get("url") or status_url
    else:
        station_id = str(value or fallback["id"]).strip()
        name = fallback["name"] if not value or station_id == fallback["id"] else station_id
        url = status_url
    if not station_id or not name or type(url) != "string":
        return None
    return {"id": station_id[:128], "name": name[:80], "url": url.strip()}

def main(config):
    status_url = config.str("station_status_url", DEFAULT_STATUS_URL).strip()
    start = parse_station(config.get("station_start"), DEFAULT_START, status_url)
    stop = parse_station(config.get("station_stop"), DEFAULT_STOP, status_url)
    if not start or not stop:
        return render_error()

    start_status = fetch_status(start)
    stop_status = fetch_status(stop)
    if not start_status or not stop_status:
        return render_error()

    start["availability"] = max(0, int(start_status.get("num_bikes_available", 0)))
    stop["availability"] = max(0, int(stop_status.get("num_docks_available", 0)))

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Image(src = BIKE_ICON),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Marquee(
                                width = 48,
                                child = render.Text(content = start["name"], font = "tom-thumb"),
                            ),
                        ),
                        render.Padding(
                            pad = (0, 0, 2, 0),
                            child = render.Text(content = "%d" % start["availability"], font = "tom-thumb", color = "#8bc34a"),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Marquee(
                                width = 48,
                                child = render.Text(content = stop["name"], font = "tom-thumb"),
                            ),
                        ),
                        render.Padding(
                            pad = (0, 0, 2, 0),
                            child = render.Text(content = "%d" % stop["availability"], font = "tom-thumb", color = "#13b6ff"),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error():
    return render.Root(
        render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Bikeshare status unavailable",
                            color = "#ff0000",
                            align = "center",
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
                id = "provider",
                name = "Provider URL",
                desc = "Public HTTPS GBFS provider URL (kept for existing installations and host approval).",
                icon = "building",
                default = DEFAULT_STATUS_URL,
            ),
            schema.Text(
                id = "station_status_url",
                name = "Station status URL",
                desc = "Public HTTPS GBFS station_status feed.",
                icon = "link",
                default = DEFAULT_STATUS_URL,
            ),
            schema.Text(
                id = "station_start",
                name = "Start station ID",
                desc = "Station ID for available bikes; legacy saved selections still work.",
                icon = "bicycle",
                default = DEFAULT_START["id"],
            ),
            schema.Text(
                id = "station_stop",
                name = "Stop station ID",
                desc = "Station ID for available docks; legacy saved selections still work.",
                icon = "squareParking",
                default = DEFAULT_STOP["id"],
            ),
        ],
    )
