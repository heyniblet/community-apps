"""
Applet: Json Display
Summary: Displays simple json data
Description: Takes values from a simple json file and outputs them.
Author: thickey256
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    feed_url = config.get("feed_url") or "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/example.json"
    if not valid_feed_url(feed_url):
        return error_frame("Invalid public HTTPS feed")

    rep = http.get(url = feed_url)
    body = rep.body()
    json_contents = json.decode(body, {}) if rep.status_code == 200 and body and len(body) <= 64 * 1024 else {}
    if type(json_contents) != "dict":
        return error_frame("JSON feed unavailable")

    font = "tom-thumb"
    title = bounded_text(json_contents.get("title_text"), 120)
    data = json_contents.get("data", [])
    if not title or type(data) != "list":
        return error_frame("Invalid JSON feed")

    icon = None
    image_url = json_contents.get("title_image")
    origin = "https://" + feed_url.split("/")[2]
    if type(image_url) == "string" and len(image_url) <= 2048 and image_url.startswith(origin + "/") and not any([c in image_url for c in ["@", " ", "\t", "\r", "\n"]]):
        icon_response = http.get(image_url, ttl_seconds = 3600)
        icon_body = icon_response.body()
        content_type = icon_response.headers.get("Content-Type", "").lower()
        if icon_response.status_code == 200 and icon_body and len(icon_body) <= 512 * 1024 and content_type.startswith("image/"):
            icon = icon_body

    title_children = []
    if icon != None:
        title_children.append(render.Box(width = 11, child = render.Image(src = icon)))
    title_children.append(render.Marquee(width = 64, child = render.Text(title)))
    children_array = [
        render.Box(
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "start",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = title_children,
            ),
            height = 10,
        ),
        render.Padding(
            pad = (0, 0, 0, 1),
            child = render.Box(width = 64, height = 1, color = "#555555"),
        ),
    ]

    for item in data[:3]:
        if type(item) != "dict":
            continue
        item_title = bounded_text(item.get("title"), 100)
        item_value = bounded_text(item.get("value"), 200)
        if not item_title or not item_value:
            continue
        children_array.append(
            render.Padding(
                pad = (1, 0, 1, 1),
                child = render.Marquee(width = 64, child = render.Text("%s:%s" % (item_title, item_value), font = font, color = valid_color(item.get("color")))),
            ),
        )

    return render.Root(
        child = render.Column(children = children_array),
    )

def valid_feed_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://"):
        return False
    parts = value.split("/")
    return len(parts) >= 3 and parts[2] and ":" not in parts[2] and not any([c in value for c in ["@", "\\", " ", "\t", "\r", "\n", "#"]])

def bounded_text(value, limit):
    return value[:limit] if type(value) == "string" else ""

def valid_color(value):
    return value if type(value) == "string" and re.match(r"^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$", value) else "#ffffff"

def error_frame(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, color = "#f00"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed_url",
                name = "JSON URL",
                desc = "URL for your json data",
                icon = "link",
                default = "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/example.json",
            ),
            schema.Text(
                id = "feed_refresh",
                name = "Refresh Time",
                desc = "Number of seconds between data refreshes.",
                icon = "clock",
                default = "120",
            ),
        ],
    )
