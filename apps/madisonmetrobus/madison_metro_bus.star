"""Show Madison Metro arrivals from the official GTFS-Realtime feed."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FEED_URL = "https://transitdata.cityofmadison.com/GTFS-RealTime/TrapezeRealTimeFeed.json"

def positive_int(config, key, default, minimum, maximum):
    value = str(config.get(key) or default)
    if not value.isdigit():
        return default
    value = int(value)
    return value if value >= minimum and value <= maximum else default

def main(config):
    stop_id = str(config.get("stopID") or "863").strip()
    next_n = positive_int(config, "next_n", 3, 1, 4)
    min_mins = positive_int(config, "min_mins", 2, 0, 120)
    if len(stop_id) > 24 or not stop_id.isdigit():
        return status("Configure a valid stop ID")

    response = http.get(FEED_URL, headers = {"Accept": "application/json"}, ttl_seconds = 60)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 2097152:
        return status("Madison Metro unavailable")
    data = json.decode(body, {})
    entities = data.get("entity") if type(data) == "dict" else None
    if type(entities) != "list":
        return status("Invalid Madison Metro data")

    now = time.now().unix
    arrivals = []
    for entity in entities[:2000]:
        trip_update = entity.get("trip_update") if type(entity) == "dict" else None
        if type(trip_update) != "dict":
            continue
        trip = trip_update.get("trip")
        route = str(trip.get("route_id") or "Bus")[:12] if type(trip) == "dict" else "Bus"
        updates = trip_update.get("stop_time_update")
        if type(updates) != "list":
            continue
        for update in updates[:100]:
            if type(update) != "dict" or str(update.get("stop_id") or "") != stop_id:
                continue
            event = update.get("arrival") or update.get("departure")
            timestamp = event.get("time") if type(event) == "dict" else None
            if type(timestamp) == "string" and timestamp.isdigit():
                timestamp = int(timestamp)
            if type(timestamp) != "int":
                continue
            minutes = int((timestamp - now) / 60)
            if minutes >= min_mins and minutes <= 240:
                arrivals.append((minutes, route))

    arrivals = sorted(arrivals)[:next_n]
    if not arrivals:
        return status("No upcoming buses\nStop %s" % stop_id)
    children = [render.Text("Stop %s Arrivals" % stop_id, color = "#2222FF", font = "tom-thumb")]
    for minutes, route in arrivals:
        children.append(render.Row(children = [render.Text("%s: " % route), render.Text("%d min" % minutes)]))
    return render.Root(child = render.Column(children = children))

def status(text):
    return render.Root(child = render.WrappedText(text, width = 64, align = "center"))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "stopID", name = "Stop ID", desc = "Madison Metro GTFS stop ID.", icon = "gear", default = "863"),
        schema.Text(id = "next_n", name = "Num Buses", desc = "Number of arrivals to display (1-4).", icon = "gear", default = "3"),
        schema.Text(id = "min_mins", name = "Minimum Mins", desc = "Ignore arrivals closer than this many minutes.", icon = "gear", default = "2"),
    ])
