"""
Applet: Envoy Desk
Summary: Envoy Desk information
Description: Can be placed on an Envoy Desk to display its current status.
Author: Sam Kalum <skalum@envoy.com>
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_RESPONSE_BYTES = 1024 * 1024
MAX_RESERVATIONS = 500

def getDeskInfo(config):
    envoy_token = safe_token(config.get("envoy_token"))
    desk_id = safe_id(config.get("desk_id"), False)
    floor_ids = safe_id(config.get("floor_ids"), True)
    if not envoy_token or not desk_id or not floor_ids:
        return None

    url = "https://api.envoy.com/v1/reservations"
    params = {
        "status": "ACTIVE",
        "floorIds": floor_ids,
    }
    headers = {
        "Authorization": "Bearer %s" % (envoy_token),
        "Accept": "*/*",
    }

    res = http.get(url, params = params, headers = headers)

    body = res.body()
    payload = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    reservations = payload.get("data") if type(payload) == "dict" else None
    if type(reservations) != "list":
        return None

    desk_reservation = None
    for reservation in reservations[:MAX_RESERVATIONS]:
        space = reservation.get("space") if type(reservation) == "dict" else None
        if type(space) == "dict" and str(space.get("id") or "") == desk_id:
            desk_reservation = reservation
            break

    if desk_reservation != None:
        reserved_by = desk_reservation.get("reservedBy")
        reserved_space = desk_reservation.get("space")
        return {
            "is_available": False,
            "full_name": safe_text(reserved_by.get("name") if type(reserved_by) == "dict" else None, "Reserved"),
            "desk_name": safe_text(reserved_space.get("name") if type(reserved_space) == "dict" else None, desk_id),
        }

    url = "https://api.envoy.com/v1/spaces/%s" % (desk_id)
    headers = {
        "Authorization": "Bearer %s" % (envoy_token),
        "Accept": "*/*",
    }

    res = http.get(url, headers = headers)

    body = res.body()
    payload = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    desk = payload.get("data") if type(payload) == "dict" else None
    if type(desk) != "dict":
        return None

    return {
        "is_available": desk.get("isAvailable") == True,
        "desk_name": safe_text(desk.get("name"), desk_id),
        "assigned": bool(desk.get("assignedTo")),
    }

def safe_token(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 4096 and "\r" not in value and "\n" not in value else ""

def safe_id(value, commas):
    value = str(value or "").strip()
    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_:." + ("," if commas else "")
    return value if value and len(value) <= 512 and all([char in allowed for char in value.elems()]) else ""

def safe_text(value, fallback):
    return str(value or fallback)[:120]

def main(config):
    envoy_token = safe_token(config.get("envoy_token"))
    desk_id = safe_id(config.get("desk_id"), False)

    if not envoy_token:
        return render.Root(
            child = render.Marquee(
                child = render.Text("Please authenticate to Envoy."),
                width = 64,
            ),
        )
    elif desk_id == "":
        return render.Root(
            child = render.Marquee(
                child = render.Text("Please enter a desk ID."),
                width = 64,
            ),
        )

    desk_info = getDeskInfo(config)
    if desk_info == None:
        return render.Root(child = render.Marquee(child = render.Text("Envoy data unavailable."), width = 64))

    if "full_name" in desk_info:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = desk_info["full_name"],
                                    color = "#fb4338",
                                ),
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    elif desk_info["assigned"] == True:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Assigned",
                                ),
                                color = "#8b0000",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    elif desk_info["is_available"] == False:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Not available",
                                ),
                                color = "#8b0000",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    else:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Available",
                                ),
                                color = "#006400",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "envoy_token",
                name = "Envoy API Token",
                desc = "Bearer token from an Envoy OAuth integration with reservations.read and spaces.read scopes.",
                icon = "code",
                secret = True,
            ),
            schema.Text(
                id = "desk_id",
                name = "Desk ID",
                desc = "At what desk is the Tidbyt located?",
                icon = "locationDot",
            ),
            schema.Text(
                id = "floor_ids",
                name = "Floor ID",
                desc = "On what floor is the Tidbyt located?",
                icon = "locationDot",
            ),
        ],
    )
