load("http.star", "http")
load("render.star", r = "render")
load("time.star", "time")

URL = "https://ssd-api.jpl.nasa.gov/cad.api"
LUNAR_DISTANCE_AU = 0.00256955529
HEADERS = {"User-Agent": "Niblet/1.0 support@heyniblet.com"}

def main():
    neos = get_neos()
    if len(neos) == 0:
        return r.Text(content = "No NEOs")

    index = time.now().second % len(neos)
    neo = neos[index]

    name = neo.get("name", "Unknown")
    if len(name) > 20:
        name = name[:17] + "..."

    approach = time.from_timestamp(neo["approach"])
    date = str(approach.month) + "/" + str(approach.day)
    lunar = str(int(neo["distance_au"] / LUNAR_DISTANCE_AU * 100 + 0.5) / 100.0)
    speed = str(int(neo["velocity_km_s"] * 3600))

    return r.Root(
        child = r.Stack(
            children = [
                r.Box(width = 64, height = 32, padding = 1, color = "#000000", child = r.Box(width = 63, height = 31, color = "#000000")),
                #r.Box(width=63, height=31, color="#000000"),
                r.Column(
                    children = [
                        r.Row(
                            children = [
                                r.Text(content = " " + name, color = "#8093f1", height = 10),
                            ],
                        ),
                        #r.Box(width=64, height = 1),
                        r.Box(width = 64, height = 1, color = "#5A5A5A"),
                        r.Text(content = " Date: " + date, font = "tom-thumb", height = 7, color = "#72ddf7"),
                        #r.Text(content=" Lunar: " + lunar, color="#72ddf7", , height=8),
                        r.Text(content = " " + speed + " kph", color = "#b388eb", font = "tom-thumb", height = 7),
                        r.Marquee(width = 64, offset_start = 5, offset_end = 32, height = 5, child = r.Text(content = " L Dist: " + lunar, color = "#f7aef8", font = "tom-thumb", height = 7)),
                    ],
                ),  #, r.Box(width=64, height=11, padding = 1, color="#5A5A5A", child=r.Box(width=63, height=10, color="#000000")),
            ],
        ),
    )

def get_neos():
    response = http.get(
        URL,
        params = {
            "date-min": "now",
            "date-max": "+8",
            "dist-max": "0.2",
            "fullname": "true",
            "limit": "50",
            "sort": "dist",
        },
        headers = HEADERS,
        ttl_seconds = 3600,
    )
    if response.status_code != 200:
        return []
    payload = response.json()
    if type(payload) != "dict" or type(payload.get("signature")) != "dict" or payload["signature"].get("version") != "1.5":
        return []
    fields = payload.get("fields")
    rows = payload.get("data")
    if type(fields) != "list" or type(rows) != "list":
        return []
    positions = {field: index for index, field in enumerate(fields)}
    required = ["des", "cd", "dist", "v_rel"]
    if len([field for field in required if field not in positions]) > 0:
        return []

    now = time.now().unix
    result = []
    for row in rows:
        if type(row) != "list" or len(row) != len(fields):
            continue
        values = [row[positions[field]] for field in required]
        if len([value for value in values if type(value) != "string" or value.strip() == ""]) > 0:
            continue
        approach = time.parse_time(row[positions["cd"]], "2006-Jan-02 15:04", "UTC").unix
        if approach < now:
            continue
        name = row[positions["fullname"]] if "fullname" in positions else row[positions["des"]]
        result.append({
            "approach": approach,
            "distance_au": float(row[positions["dist"]]),
            "name": name.strip(),
            "velocity_km_s": float(row[positions["v_rel"]]),
        })
        if len(result) == 10:
            break
    return result
