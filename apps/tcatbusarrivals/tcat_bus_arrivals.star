"""
Applet: TCAT Bus Arrivals
Summary: Show TCAT arrival times
Description: Display Arrival Times for TCAT Ithaca Buses at a Specific Stop.
Author: Harry Samuels
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/tcat_and_car.png", TCAT_AND_CAR_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TCAT_AND_CAR = TCAT_AND_CAR_ASSET.readall()

TCAT_API = "https://realtimetcatbus.availtec.com/InfoPoint/rest"

NO_BUSES = [
    render.Circle(
        diameter = 12,
        color = "#20B7BC",
        child = render.Text("N"),
    ),
    render.Circle(
        diameter = 12,
        color = "#2722B3",
        child = render.Text("O"),
    ),
    render.Box(
        height = 12,
        width = 6,
    ),
    render.Circle(
        diameter = 12,
        color = "#7C26A6",
        child = render.Text("B"),
    ),
    render.Circle(
        diameter = 12,
        color = "#E22DD0",
        child = render.Text("U"),
    ),
    render.Circle(
        diameter = 12,
        color = "#EE1C1C",
        child = render.Text("S"),
    ),
    render.Circle(
        diameter = 12,
        color = "#F0A524",
        child = render.Text("E"),
    ),
    render.Circle(
        diameter = 12,
        color = "#DCDC37",
        child = render.Text("S"),
    ),
]

def main(config):
    stopCode = str(config.get("stopCode", "1524")).strip()
    if not re.match("^[0-9]{1,8}$", stopCode):
        return message("Enter a valid TCAT stop")

    stop = fetch_json(TCAT_API + "/Stops/Get/" + stopCode, {})
    departures = fetch_json(TCAT_API + "/StopDepartures/Get/" + stopCode, [])
    if type(stop) != "dict" or type(departures) != "list":
        return message("TCAT data unavailable")

    stopName = stop.get("Name", "Stop " + stopCode)
    stopName = stopName[:80] if type(stopName) == "string" else "Stop " + stopCode
    kid_list = []
    time_list = []
    for board in departures[:2]:
        directions = board.get("RouteDirections", []) if type(board) == "dict" else []
        for direction in directions[:20] if type(directions) == "list" else []:
            if type(direction) != "dict":
                continue
            route = str(direction.get("RouteId", "?"))[:4]
            route_departures = direction.get("Departures", [])
            for departure in route_departures[:3] if type(route_departures) == "list" else []:
                minutes = departureMinutes(departure)
                if minutes == None:
                    continue
                minute_text = str(minutes)
                kid_list.append(
                    render.Row(
                        cross_align = "center",
                        children = [
                            render.Circle(diameter = 12, color = routeColor(route), child = render.Text(content = route)),
                            render.Text(color = "#25FF51", content = " in " + minute_text + " min  "),
                        ],
                    ),
                )
                time_list.append(minute_text)
                if len(kid_list) >= 12:
                    break

    return render.Root(
        child = render.Column(
            main_align = "start",
            children = [
                render.WrappedText(
                    height = 12,
                    color = "#FFD546",
                    font = "CG-pixel-4x5-mono",
                    linespacing = 1,
                    content = stopName,
                ),
                render.Box(
                    height = 1,
                    color = "#FF0000",
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 32,
                    offset_end = 32,
                    child = render.Row(
                        children = timeSort(kid_list, time_list),
                    ),
                ),
                render.Box(
                    height = 1,
                    color = "#FF0000",
                ),
                #render.Box(
                #    height= 1,
                #),
                render.Marquee(
                    scroll_direction = "horizontal",
                    width = 64,
                    offset_start = 64,
                    offset_end = 64,
                    child = render.Row(
                        children = [
                            render.Image(
                                src = TCAT_AND_CAR,
                            ),
                            render.Box(
                                width = 22,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def fetch_json(url, fallback):
    response = http.get(url, ttl_seconds = 60)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 256 * 1024:
        return fallback
    return json.decode(body, fallback)

def departureMinutes(departure):
    if type(departure) != "dict":
        return None
    value = departure.get("ETA") or departure.get("EDT") or departure.get("STA") or departure.get("SDT")
    timestamps = re.findall("[0-9]{10,13}", value) if type(value) == "string" else []
    if not timestamps:
        return None
    return max(0, (int(timestamps[0][:10]) - time.now().unix) // 60)

def routeColor(route):
    colors = ["#20B7BC", "#2722B3", "#7C26A6", "#E22DD0", "#EE1C1C", "#F0A524", "#DCDC37"]
    total = 0
    for char in route.codepoints():
        total += ord(char)
    return colors[total % len(colors)]

def message(text):
    return render.Root(child = render.WrappedText(color = "#FF5555", content = text, align = "center"))

def timeSort(kid_list, time_list):
    sorted_list = []
    sorted_times = []

    if kid_list != []:
        sorted_list.append(kid_list[0])
        sorted_times.append(time_list[0])
        iterations = len(kid_list)
        for x in range(1, iterations):
            y = 0
            eta = int(time_list[x])
            for _ in range(0, iterations):
                if y < len(sorted_list) and eta >= int(sorted_times[y]):
                    y = y + 1
            if y < len(sorted_list):
                sorted_list.insert(y, kid_list[x])
                sorted_times.insert(y, time_list[x])
            else:
                sorted_list.append(kid_list[x])
                sorted_times.append(time_list[x])
    else:
        sorted_list = NO_BUSES
    return sorted_list

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stopCode",
                name = "Bus Stop Number",
                desc = "The number of the bus stop. (Located on the sign at each bus stop)",
                icon = "locationDot",
                default = "1524",
            ),
        ],
    )
