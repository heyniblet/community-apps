"""
Applet: GA Pilot Buddy
Summary: Local flight rules and wx
Description: See local aerodrome flight rules and current abbreviated METAR information.
Author: icdevin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/error_icon.png", ERROR_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ERROR_ICON = ERROR_ICON_ASSET.readall()
DEFAULT_LOCATION = """
{
    "lat": "33.6295968",
    "lng": "-117.8862308",
    "description": "Newport Beach, CA, USA",
    "locality": "Newport Beach",
    "place_id": "ChIJ3whWdFnf3IARUV7GZxqUpjs",
    "timezone": "America/Los_Angeles"
}
"""
FLIGHT_RULES_COLOR_MAP = {"VFR": "#01CF00", "MVFR": "#0061E7", "IFR": "#EB0000", "LIFR": "#D300D3"}

def get_headers(token):
    return {"Authorization": "Token %s" % token}

def get_nearby_aerodromes(location, token, show_all):
    lat = coordinate(location.get("lat"), -90, 90)
    lng = coordinate(location.get("lng"), -180, 180)
    if lat == None or lng == None:
        return None
    url = "https://avwx.rest/api/station/near/{},{}".format(humanize.float("#.#", lat), humanize.float("#.#", lng))
    response = http.get(url, params = {"n": "10"}, headers = get_headers(token))
    if response.status_code != 200 or len(response.body()) > 2 * 1024 * 1024:
        return None
    aerodromes = json.decode(response.body(), [])
    if type(aerodromes) != "list":
        return None

    result = []
    for aerodrome in aerodromes[:20]:
        station = aerodrome.get("station") if type(aerodrome) == "dict" else None
        if type(station) != "dict" or type(station.get("icao")) != "string":
            continue
        if show_all or station.get("operator") == "PUBLIC":
            result.append(aerodrome)
    return result

def get_aerodrome_metar(aerodrome, token):
    aerodrome_id = aerodrome["station"]["icao"]
    if not identifier(aerodrome_id, 8):
        return None
    response = http.get("https://avwx.rest/api/metar/%s" % aerodrome_id, headers = get_headers(token))
    if response.status_code != 200 or len(response.body()) > 2 * 1024 * 1024:
        return None
    metar = json.decode(response.body(), {})
    return metar if type(metar) == "dict" else None

def render_aerodrome_row(aerodrome, token):
    metar = get_aerodrome_metar(aerodrome, token)
    if not metar:
        return None
    station_id = aerodrome["station"]["icao"][:8]
    rules = metar.get("flight_rules")
    wind = metar.get("wind_direction", {})
    speed = metar.get("wind_speed", {})
    visibility = metar.get("visibility", {})
    altimeter = metar.get("altimeter", {})
    wind = wind if type(wind) == "dict" else {}
    speed = speed if type(speed) == "dict" else {}
    visibility = visibility if type(visibility) == "dict" else {}
    altimeter = altimeter if type(altimeter) == "dict" else {}
    alt_value = altimeter.get("value")
    altitude = humanize.float("##.##", alt_value) if type(alt_value) in ["int", "float"] else "?"
    weather = "Wind %s@%s, Vis %s, Alt %s" % (
        safe_text(wind.get("repr")),
        safe_text(speed.get("repr")),
        safe_text(visibility.get("repr")),
        altitude,
    )
    return render.Padding(
        pad = (2, 2, 0, 0),
        child = render.Row(
            cross_align = "center",
            children = [
                render.Padding(pad = (0, 0, 2, 0), child = render.Circle(color = FLIGHT_RULES_COLOR_MAP.get(rules, "#C3C3C3"), diameter = 6)),
                render.Padding(pad = (0, 0, 2, 0), child = render.Box(width = 20, height = 8, child = render.Text(station_id))),
                render.Marquee(width = 50, offset_start = 40, offset_end = 50, child = render.Text(weather[:160])),
            ],
        ),
    )

def main(config):
    token = config.get("avwx_api_token")
    if not valid_secret(token):
        return render_error("Add AVWX token")
    location = json.decode(config.get("location", DEFAULT_LOCATION), {})
    if type(location) != "dict":
        return render_error("Check location")
    aerodromes = get_nearby_aerodromes(location, token, config.bool("show_all_aerodromes"))
    if aerodromes == None:
        return render_error("Weather unavailable")
    rows = [render_aerodrome_row(aerodrome, token) for aerodrome in aerodromes[:3]]
    rows = [row for row in rows if row != None]
    if not rows:
        return render_error("No nearby METAR")
    return render.Root(child = render.Column(children = rows))

def coordinate(value, minimum, maximum):
    if type(value) in ["int", "float"]:
        number = float(value)
    elif type(value) == "string":
        value = value.strip()
        unsigned = value[1:] if value.startswith("-") or value.startswith("+") else value
        parts = unsigned.split(".")
        if not unsigned or len(value) > 20 or len(parts) > 2 or not all([part.isdigit() for part in parts]):
            return None
        number = float(value)
    else:
        return None
    return number if minimum <= number and number <= maximum else None

def identifier(value, maximum):
    return type(value) == "string" and value and len(value) <= maximum and all([char.isalnum() or char in "-_" for char in value.codepoints()])

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 2048 and "\r" not in value and "\n" not in value

def safe_text(value):
    return value[:24] if type(value) == "string" and value else "?"

def render_error(text):
    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [render.Image(src = ERROR_ICON), render.WrappedText(text, width = 45, color = "#ffcc66")],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "avwx_api_token", name = "AVWX API Token", desc = "Your AVWX API token. See https://avwx.rest/ for details.", icon = "key", secret = True),
            schema.Location(id = "location", name = "Location", desc = "Location for which to display nearby aerodromes", icon = "locationDot"),
            schema.Toggle(id = "show_all_aerodromes", name = "Show All Aerodromes", desc = "Enables showing all aerodromes including military, private, etc.", icon = "gear", default = False),
        ],
    )
