# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: MCTS Tracker
Summary: Track MCTS buses
Description: View MCTS departures through Transitland's copy of the official GTFS feeds.
Author: Josiah Winslow
"""

load("http.star", "http")
load("images/mcts_icon.webp", MCTS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

MCTS_ICON = MCTS_ICON_ASSET.readall()
DEFAULT_STOP_ID = "743"
TRANSITLAND_URL = "https://transit.land/api/v2/rest/stops/f-dp9-milwaukeecountytransitsystem:{stop}/departures?next=3600&limit=4"
BUS_COLORS = {
    "BLU": ("#21417e", "#fff"),
    "GOL": ("#fec110", "#332f2a"),
    "GRE": ("#008d75", "#fff"),
    "PUR": ("#543996", "#fff"),
    "RED": ("#c33529", "#fff"),
    "11": ("#039a01", "#fff"),
    "15": ("#ff8400", "#fff"),
    "30": ("#00af97", "#fff"),
    "80": ("#e30692", "#fff"),
}

def main(config):
    stop_id = config.str("stop", DEFAULT_STOP_ID)
    api_key = config.str("key")
    if not stop_id.isdigit():
        return screen(stop_id, "CONFIG", ["Invalid stop ID"], "#f00")
    if not api_key:
        return screen(stop_id, "SETUP", ["Add Transitland API key"], "#f80")

    response = http.get(
        TRANSITLAND_URL.format(stop = stop_id),
        headers = {"apikey": api_key, "Accept": "application/json"},
        ttl_seconds = 60,
    )
    if response.status_code != 200 or len(response.body()) > 1024 * 1024:
        return screen(stop_id, "API", ["Transit data unavailable"], "#f00")
    payload = response.json()
    stops = payload.get("stops", []) if type(payload) == "dict" else []
    if not stops:
        return screen(stop_id, "MCTS", ["Stop not found"], "#f80")

    stop = stops[0]
    departures = stop.get("departures", []) if type(stop) == "dict" else []
    rows = []
    for departure in departures[:4]:
        trip = departure.get("trip", {}) if type(departure) == "dict" else {}
        route = trip.get("route", {}) if type(trip) == "dict" else {}
        event = departure.get("departure", {}) if type(departure) == "dict" else {}
        route_name = route.get("route_short_name") or route.get("route_id") or "BUS"
        departure_time = event.get("estimated") or event.get("scheduled") or departure.get("departure_time") or "--:--"
        rows.append((str(route_name)[:5], str(departure_time)[:5]))
    if not rows:
        return screen(stop_id, str(stop.get("stop_name") or "MCTS"), ["No departures"], "#f80")
    return departure_screen(stop_id, str(stop.get("stop_name") or "MCTS"), rows)

def logo(stop_id):
    return render.Stack(
        children = [
            render.Image(src = MCTS_ICON),
            render.Padding(
                pad = (1, 26, 0, 0),
                child = render.WrappedText(stop_id, font = "tom-thumb", width = 22, color = "#332f2a", align = "center"),
            ),
        ],
    )

def screen(stop_id, title, messages, color):
    return render.Root(
        child = render.Row(
            children = [
                logo(stop_id),
                render.Column(
                    children = [
                        render.Marquee(child = render.Text(title, font = "tom-thumb"), width = 40),
                        render.WrappedText(" ".join(messages), font = "tom-thumb", width = 40, color = color),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
            ],
        ),
    )

def departure_screen(stop_id, stop_name, rows):
    return render.Root(
        child = render.Row(
            children = [
                logo(stop_id),
                render.Column(
                    children = [render.Marquee(child = render.Text(stop_name, font = "tom-thumb"), width = 40)] + [departure_row(*row) for row in rows],
                ),
            ],
        ),
    )

def departure_row(route, departure_time):
    colors = BUS_COLORS.get(route, ("#ffffff", "#332f2a"))
    return render.Row(
        children = [
            render.Box(width = 16, height = 6, color = colors[0], child = render.WrappedText(route, font = "tom-thumb", color = colors[1], width = 15, align = "center")),
            render.Text(departure_time, font = "tom-thumb"),
        ],
        main_align = "space_between",
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "stop", name = "Bus Stop ID", desc = "MCTS stop number.", icon = "bus", default = DEFAULT_STOP_ID),
            schema.Text(id = "key", name = "Transitland API key", desc = "A Transitland v2 API key.", icon = "key", secret = True),
        ],
    )
