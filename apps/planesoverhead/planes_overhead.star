"""
Applet: Planes Overhead
Summary: Show closest overhead plane
Description: Fetch the closest plane flying overhead from the OpenSky API and display its typecode, altitude, speed, heading, and relative position.
Author: Conor McLaughlin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lat",
                name = "Latitude",
                desc = "Latitude to fetch planes overhead",
                icon = "locationDot",
                default = "34.023",
            ),
            schema.Text(
                id = "lng",
                name = "Longitude",
                desc = "Longitude to fetch planes overhead",
                icon = "locationDot",
                default = "-118.490",
            ),
            schema.Text(
                id = "radius",
                name = "Radius",
                desc = "Rough radius (miles) to search inside",
                icon = "ruler",
                default = "20",
            ),
            schema.Text(
                id = "client_id",
                name = "client_id",
                desc = "Optional OpenSky OAuth client ID for a higher request allowance",
                icon = "person",
            ),
            schema.Text(
                id = "client_secret",
                name = "client_secret",
                desc = "Optional OpenSky OAuth client secret for a higher request allowance",
                icon = "lock",
                secret = True,
            ),
        ],
    )

def get_bounding_box(lat, lng, radius):
    R = 6371  # earth radius in km
    radius = radius * 1.609
    x1 = lng - math.degrees(radius / R / math.cos(math.radians(lat)))
    x2 = lng + math.degrees(radius / R / math.cos(math.radians(lat)))
    y1 = lat + math.degrees(radius / R)
    y2 = lat - math.degrees(radius / R)
    dict = {"lamin": y2, "lomin": x1, "lamax": y1, "lomax": x2}
    return dict

def as_float(value, fallback):
    value = value.strip()
    unsigned = value[1:] if value.startswith("-") or value.startswith("+") else value
    parts = unsigned.split(".")
    if len(parts) > 2 or not "".join(parts) or not "".join(parts).isdigit():
        return fallback
    return float(value)

def get_haversine_distance(lat1, lng1, lat2, lng2):
    # Approximate radius of earth in km
    R = 6373.0

    lat1 = math.radians(lat1)
    lon1 = math.radians(lng1)
    lat2 = math.radians(lat2)
    lon2 = math.radians(lng2)

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = math.pow(math.sin(dlat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = R * c

    return math.round(distance * 10 / 1.609) / 10

def get_bearing(lat1, long1, lat2, long2):
    dLon = (long2 - long1)
    x = math.cos(math.radians(lat2)) * math.sin(math.radians(dLon))
    y = math.cos(math.radians(lat1)) * math.sin(math.radians(lat2)) - math.sin(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.cos(math.radians(dLon))
    brng = math.atan2(x, y)
    brng = math.degrees(brng)
    return (brng + 360) % 360

def get_heading(value):
    heading = ""

    if value == None:
        heading = "N/A"
    elif value < 11.25:
        heading = "N"
    elif value < 33.75:
        heading = "NNE"
    elif value < 56.25:
        heading = "NE"
    elif value < 78.75:
        heading = "ENE"
    elif value < 101.25:
        heading = "E"
    elif value < 123.75:
        heading = "ESE"
    elif value < 146.25:
        heading = "SE"
    elif value < 168.75:
        heading = "SSE"
    elif value < 191.25:
        heading = "S"
    elif value < 213.75:
        heading = "SSW"
    elif value < 236.25:
        heading = "SW"
    elif value < 258.75:
        heading = "WSW"
    elif value < 281.25:
        heading = "W"
    elif value < 303.75:
        heading = "WNW"
    elif value < 326.25:
        heading = "NW"
    elif value < 348.75:
        heading = "NNW"
    elif value >= 348.75:
        heading = "N"
    return heading

def get_arrow(heading):
    arrow = ""

    if (0 <= heading) and (heading < 22.5):
        arrow = "↑"
    elif (22.5 <= heading) and (heading < 67.5):
        arrow = "↗"
    elif (67.5 <= heading) and (heading < 112.5):
        arrow = "→"
    elif (112.5 <= heading) and (heading < 157.5):
        arrow = "↘"
    elif (157.5 <= heading) and (heading < 202.5):
        arrow = "↓"
    elif (202.5 <= heading) and (heading < 247.5):
        arrow = "↙"
    elif (247.5 <= heading) and (heading < 292.5):
        arrow = "←"
    elif (292.5 <= heading) and (heading < 337.5):
        arrow = "↖"
    elif (337.5 <= heading) and (heading <= 360):
        arrow = "↑"
    else:
        arrow = "·"

    return arrow

def get_typecode(icao24):
    URL = "https://buhujdzqm2.execute-api.us-east-1.amazonaws.com/default/aircraft/" + icao24

    query_get = http.get(url = URL, ttl_seconds = 86400)

    print("Type Lookup HTTP Status:", query_get.status_code)

    response = query_get.body().strip()
    if query_get.status_code != 200 or len(response) > 65536 or not response.startswith("{") or not response.endswith("}"):
        return ""

    # Parse JSON safely
    data = json.decode(response) if len(response) > 0 else {}

    # Return typecode if available, else fallback
    typecode = data.get("typecode", "") if type(data) == "dict" else ""
    return typecode[:12] if type(typecode) == "string" else ""

def render_error(status_code):
    screen = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Text(content = "Planes", height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.WrappedText(content = "HTTP" + str(status_code), color = "#f7ba99"),
            ],
        ),
    )
    return screen

def process_states(state_list, your_coord):
    output = []
    if len(state_list) > 0:
        for item in state_list[:500]:
            if type(item) != "list" or len(item) < 18 or type(item[0]) != "string" or type(item[5]) not in ["int", "float"] or type(item[6]) not in ["int", "float"]:
                continue
            temp = {}
            temp["icao24"] = item[0]
            temp["callsign"] = item[1].strip() if type(item[1]) == "string" else ""
            temp["origin_country"] = item[2]
            temp["time_position"] = item[3]
            temp["last_contact"] = item[4]
            temp["lng"] = item[5]
            temp["lat"] = item[6]
            temp["dist_from_you"] = get_haversine_distance(item[6], item[5], your_coord[0], your_coord[1])
            temp["location_vs_you"] = get_heading(get_bearing(your_coord[0], your_coord[1], item[6], item[5]))
            temp["arrow"] = get_arrow(get_bearing(your_coord[0], your_coord[1], item[6], item[5]))
            temp["on_ground"] = item[8]
            speed = item[9] if type(item[9]) in ["int", "float"] else None
            track = item[10] if type(item[10]) in ["int", "float"] else None
            climb = item[11] if type(item[11]) in ["int", "float"] else None
            altitude = item[13] if type(item[13]) in ["int", "float"] else item[7] if type(item[7]) in ["int", "float"] else None
            temp["speed"] = math.round(speed * 2.23694) if speed != None else None
            temp["heading"] = get_heading(track)
            temp["climb"] = None if climb == None else "ascending" if climb > 0.5 else "descending" if climb < -0.5 else "stable"
            temp["altitude"] = math.round(altitude * 3.28) if altitude != None else None
            if temp["callsign"] and temp["on_ground"] == False:
                output.append(temp)
        output = sorted(output, key = lambda i: i["dist_from_you"])
    return output

def render_empty():
    screen = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Text(content = "Planes", height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.WrappedText(content = "No Planes Overhead", color = "#f7ba99"),
            ],
        ),
    )
    return screen

def render_plane(planes):
    print(planes[0])
    typecode = get_typecode(planes[0]["icao24"])
    print(typecode)
    screen = render.Root(
        render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Text(content = planes[0]["callsign"][:12], height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.Text(content = "%s %s %s %s" % (typecode, planes[0]["dist_from_you"], planes[0]["arrow"], planes[0]["location_vs_you"])),
                render.Marquee(
                    child = render.Text(content = "Heading %s at %s mph, Altitude %s ft, %s" % (planes[0]["heading"], planes[0]["speed"] or "N/A", planes[0]["altitude"] or "N/A", planes[0]["climb"] or "stable")),
                    scroll_direction = "horizontal",
                    offset_end = 64,
                    width = 64,
                    delay = 100,
                ),
            ],
        ),
    )
    return screen

def get_fresh_token(client_id, client_secret):
    token_response = http.post(
        url = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token",
        form_body = {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
        },
        ttl_seconds = 300,
    )

    if token_response.status_code != 200:
        print("Failed to fetch token: " + str(token_response.status_code))
        return None

    body = token_response.body().strip()
    token_json = token_response.json() if len(body) <= 65536 and body.startswith("{") and body.endswith("}") else {}

    if type(token_json) != "dict" or type(token_json.get("access_token")) != "string":
        print("OpenSky token response did not contain an access token")
        return None

    return token_json["access_token"]

def main(config):
    lat = as_float(config.str("lat", "34.023"), 34.023)
    lng = as_float(config.str("lng", "-118.496"), -118.496)
    lat = lat if lat >= -85 and lat <= 85 else 34.023
    lng = lng if lng >= -180 and lng <= 180 else -118.496
    your_coord = [lat, lng]

    client_id = config.str("client_id", "").strip()
    client_secret = config.str("client_secret", "").strip()

    radius = as_float(config.str("radius", "20"), 20.0)
    radius = radius if radius >= 1 and radius <= 100 else 20.0
    bbox = get_bounding_box(lat, lng, radius)
    print(your_coord)

    params = {
        "lamin": str(math.round(bbox["lamin"] / 0.001) * 0.001),
        "lomin": str(math.round(bbox["lomin"] / 0.001) * 0.001),
        "lamax": str(math.round(bbox["lamax"] / 0.001) * 0.001),
        "lomax": str(math.round(bbox["lomax"] / 0.001) * 0.001),
        "extended": "1",
    }

    token = get_fresh_token(client_id, client_secret) if client_id and client_secret else None
    headers = {"Authorization": "Bearer " + token} if token else {}

    response = http.get(
        url = "https://opensky-network.org/api/states/all",
        headers = headers,
        params = params,
        ttl_seconds = 300,
    )

    api_status_code = response.status_code

    print("OpenSky API HTTP Response: " + str(api_status_code))

    # testing a non-good HTTP return code
    # api_status_code = 400

    # testing an empty states list
    # api_response["states"] = []

    if api_status_code != 200:
        return render_error(api_status_code)
    body = response.body().strip()
    if len(body) > 2097152 or not body.startswith("{") or not body.endswith("}"):
        return render_error(502)
    api_response = response.json()
    if type(api_response) != "dict" or type(api_response.get("states")) != "list":
        return render_empty()
    planes = process_states(api_response["states"], your_coord)
    if len(planes) == 0:
        return render_empty()
    return render_plane(planes)
