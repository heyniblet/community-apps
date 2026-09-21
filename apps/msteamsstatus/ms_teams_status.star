# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: MS Teams Status
Summary: Show your MS Teams status
Description: Show Microsoft Teams presence from a user-owned HTTPS relay.
Author: schumatt
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

availability_map = {
    "Available": {"color": "#0f0", "label": "Available"},
    "AvailableIdle": {"color": "#ccc", "label": "Available - Idle"},
    "Away": {"color": "#ff0", "label": "Away"},
    "BeRightBack": {"color": "#ff0", "label": "Be Right Back"},
    "Busy": {"color": "#f00", "label": "Busy"},
    "BusyIdle": {"color": "#f00", "label": "Busy - Idle"},
    "DoNotDisturb": {"color": "#800000", "label": "Do Not Disturb"},
    "Offline": {"color": "#888", "label": "Offline"},
    "PresenceUnknown": {"color": "#0ff", "label": "Unknown"},
}
activity_map = {
    "Available": {"presence": "Available"},
    "Away": {"presence": "Away"},
    "BeRightBack": {"presence": "BeRightBack"},
    "Busy": {"presence": "Busy"},
    "DoNotDisturb": {"presence": "DoNotDisturb"},
    "InACall": {"presence": "Busy", "label": "In a Call", "color": "#f00"},
    "InAConferenceCall": {"presence": "Busy", "label": "In a Conference Call", "color": "#f00"},
    "Inactive": {"presence": "Offline"},
    "InAMeeting": {"presence": "Busy", "label": "In a Meeting"},
    "Offline": {"presence": "Offline"},
    "OffWork": {"presence": "Offline", "label": "Off Work"},
    "OutOfOffice": {"presence": "Offline", "label": "Out of Office", "color": "#cd00cd"},
    "PresenceUnknown": {"presence": "PresenceUnknown"},
    "Presenting": {"presence": "DoNotDisturb", "label": "Presenting"},
    "UrgentInterruptionsOnly": {"presence": "DoNotDisturb"},
}

def main(config):
    url = config.str("endpoint_url")
    token = config.str("relay_token")
    if not valid_url(url) or not token:
        return render_teams_status("Microsoft Teams", "PresenceUnknown", "PresenceUnknown", "Add your HTTPS relay URL", False)
    response = http.get(url, headers = {"Authorization": "Bearer " + token})
    if response.status_code != 200 or len(response.body()) > 128 * 1024:
        return render_teams_status("Microsoft Teams", "PresenceUnknown", "PresenceUnknown", "Relay unavailable", False)
    data = json.decode(response.body(), {})
    if type(data) != "dict":
        return render_teams_status("Microsoft Teams", "PresenceUnknown", "PresenceUnknown", "Invalid relay response", False)
    name = text(data.get("displayName"), "Microsoft Teams", 100)
    availability = text(data.get("availability"), "PresenceUnknown", 40)
    activity = text(data.get("activity"), "PresenceUnknown", 40)
    message = text(data.get("statusMessage"), "", 300)
    return render_teams_status(name, availability, activity, message, data.get("isOutOfOffice") == True)

def valid_url(value):
    return type(value) == "string" and value.startswith("https://") and len(value) <= 4096 and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def text(value, fallback, limit):
    return value[:limit] if type(value) == "string" and value else fallback

def render_teams_status(name, availability, activity, message, out_of_office):
    if activity in activity_map and activity_map[activity]["presence"] in availability_map:
        status = activity_map[activity]
        presence = availability_map[status["presence"]]
        label = status.get("label", presence["label"])
        color = status.get("color", presence["color"])
        dot_color = presence["color"]
    elif availability in availability_map:
        label = availability_map[availability]["label"]
        color = availability_map[availability]["color"]
        dot_color = color
    else:
        label = "Unknown"
        color = "#ff4f00"
        dot_color = color
    if out_of_office:
        dot_color = "#cd00cd"
        label += " / Out of Office"

    return render.Root(
        delay = 1,
        child = render.Row(
            children = [
                render.Padding(child = render.Box(width = 5, color = color), pad = (0, 0, 1, 0)),
                render.Column(
                    children = [
                        render.Marquee(child = render.Text(name), width = 59, offset_start = 59, offset_end = 59),
                        render.Row(
                            children = [
                                render.Padding(child = render.Circle(diameter = 6, color = dot_color), pad = (0, 1, 1, 2), color = "#000"),
                                render.Marquee(width = 51, child = render.Text(label, color = color), offset_start = 0),
                            ],
                        ),
                        render.Marquee(child = render.WrappedText(message, font = "CG-pixel-3x5-mono", linespacing = 2), scroll_direction = "vertical", height = 15, align = "center", offset_start = 0),
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
                id = "endpoint_url",
                name = "Teams relay URL",
                desc = "A user-owned HTTPS endpoint returning displayName, availability, activity, statusMessage, and isOutOfOffice as JSON.",
                icon = "link",
            ),
            schema.Text(
                id = "relay_token",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                icon = "key",
                secret = True,
            ),
        ],
    )
