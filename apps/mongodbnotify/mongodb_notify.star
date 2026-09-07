"""
Applet: Webhook Notify
Summary: Message notifications
Description: Displays a bounded notification document from a user-hosted HTTPS endpoint.
Author: bsbishop
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_RESPONSE_BYTES = 65536

def main(config):
    endpoint = config.str("endpoint_url")
    if not endpoint:
        return notification("WEBHOOK", "Add an HTTPS endpoint", "#4f46e5")
    if not valid_https_url(endpoint):
        return notification("CONFIG ERROR", "Endpoint must be a public HTTPS URL", "#991b1b")

    headers = {"Accept": "application/json"}
    api_key = config.str("api_key")
    if api_key:
        headers["Authorization"] = "Bearer " + api_key
    response = http.get(endpoint, headers = headers, ttl_seconds = 60)
    if response.status_code == 204:
        return []
    if response.status_code != 200 or len(response.body()) > MAX_RESPONSE_BYTES:
        return notification("API ERROR", "Endpoint returned %d" % response.status_code, "#991b1b")

    payload = response.json()
    if type(payload) != "dict":
        return notification("API ERROR", "Expected a JSON object", "#991b1b")
    title = payload.get("title", "Notification")
    message = payload.get("message", "")
    color = payload.get("color", "#4f46e5")
    if type(title) != "string" or type(message) != "string" or type(color) != "string" or not valid_color(color):
        return notification("API ERROR", "Invalid notification fields", "#991b1b")
    if not message:
        return []
    return notification(title[:80], message[:500], color)

def valid_https_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n"]]):
        return False
    parts = value.split("/", 3)
    return len(parts) == 4 and parts[2] and "@" not in parts[2]

def valid_color(value):
    if len(value) != 7 or not value.startswith("#"):
        return False
    return all([char.lower() in "0123456789abcdef" for char in value[1:]])

def notification(title, message, color):
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = color,
            child = render.Column(
                children = [
                    render.Marquee(child = render.Text(title, font = "tom-thumb"), width = 62, align = "center"),
                    render.Box(width = 62, height = 1, color = "#ffffff"),
                    render.Marquee(
                        child = render.WrappedText(message, font = "tom-thumb", width = 60, align = "center"),
                        width = 62,
                        height = 23,
                        scroll_direction = "vertical",
                    ),
                ],
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
            ),
        ),
        delay = 3000,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                name = "Notification endpoint",
                desc = "Public HTTPS endpoint returning title, message, and optional color as JSON.",
                icon = "link",
            ),
            schema.Text(
                id = "api_key",
                name = "Bearer token",
                desc = "Optional token sent in the Authorization header.",
                icon = "key",
                secret = True,
            ),
        ],
    )
