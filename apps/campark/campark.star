"""
Applet: CamPark
Summary: Cambridge Car Park Spaces
Description: Real Time spaces in Cambridge UK Car Parks
Author: derekllaw

Uses Smart Cambridge parking API
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# constants

API_BASE = "https://smartcambridge.org/api/v1/parking/"
SCREEN_WIDTH = 64
BIG_FONT = "5x8"
SMALL_FONT = "tom-thumb"
PARK = "car_park"
RIDE = "park_and_ride"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_PARKS = 20

def render_fixed(n):
    """ Render number in at least 3 characters

    Args:
        n: number

    Returns:
        padded string
    """
    text_num = "%d" % n
    pad = ""
    if len(text_num) == 2:
        pad = " "
    elif len(text_num) == 1:
        pad = "  "
    return (pad + text_num)

def render_row(capacity, free, name, font):
    """ Render row with free spaces in green, or red if less than 10% free

    Args:
        capacity: total spaces
        free: free spaces
        name: text
        font: font
    """
    free_colour = "#0F0" if free > (capacity // 10) else "#F00"
    free_text = render_fixed(free)
    return render.Row(children = [
        render.Text(free_text, color = free_colour, font = font),
        render.Marquee(child = render.Text(name, font = font), width = (SCREEN_WIDTH - len(free_text) * 5)),
    ])

def get_schema():
    return [
        schema.Text(
            id = "api_token",
            name = "API Token",
            desc = "API key for Smart Cambridge parking API",
            icon = "key",
            secret = True,
        ),
    ]

def get_json(url, headers):
    response = http.get(url, headers = headers)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        print("Smart Cambridge request failed with status %d" % response.status_code)
        return None
    data = json.decode(body, None)
    return data if type(data) == "dict" else None

def safe_id(value):
    value = str(value or "")
    for char in value.elems():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return ""
    return value

def main(config):
    """ Entry point

    Args:
        config: config object

    Returns:
        render root
    """

    # Collect output rows here
    rows = []
    api_token = config.get("api_token")

    # check for missing api_token
    if not api_token:
        rows.append(render.Text("No key found"))
    else:
        headers = {"Authorization": "Token %s" % api_token}

        # fetch list of parking ids
        park_data = get_json(API_BASE, headers)
        if not park_data:
            rows.append(render.Text("Parking API error"))
        else:
            park_list = park_data.get("parking_list", [])
            park_list = park_list[:MAX_PARKS] if type(park_list) == "list" else []
            count = {PARK: 0, RIDE: 0}

            for park in park_list:
                if type(park) == "dict" and park.get("parking_type") in count:
                    count[park["parking_type"]] += 1

            for parking_type in [PARK]:
                font = BIG_FONT if count[parking_type] <= 5 else SMALL_FONT
                for park in park_list:
                    if type(park) == "dict" and park.get("parking_type") == parking_type:
                        parking_id = safe_id(park.get("parking_id"))
                        if not parking_id:
                            continue
                        api_latest = "{}latest/{}/".format(API_BASE, parking_id)

                        data = get_json(api_latest, headers)
                        if not data:
                            rows.append(render.Text("Parking API error"))
                        else:
                            capacity = data.get("spaces_capacity")
                            free = data.get("spaces_free")
                            name = park.get("parking_name")
                            if type(capacity) == "int" and capacity > 0 and type(free) == "int" and name:
                                rows.append(render_row(capacity, max(0, free), str(name).title()[:80], font))

    return render.Root(
        child = render.Column(rows, expanded = True, main_align = "space_around"),
        show_full_animation = True,
    )
