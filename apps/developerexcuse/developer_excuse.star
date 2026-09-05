"""
Applet: Developer Excuse
Summary: Developer Excuse
Description: Developer Excuse app generates playful and imaginative excuses to bring a smile to developers facing coding hiccups and bugs.
Author: masonwongcs
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

EXCUSE_URL = "https://excuser-three.vercel.app/v1/excuse/developers/"
DEFAULT_COLOR = "#ffffff"
DEFAULT_DIRECTION = "horizontal"

def main(config):
    rep = http.get(EXCUSE_URL, ttl_seconds = 300)
    body = rep.body()
    payload = json.decode(body, None) if rep.status_code == 200 and len(body) <= 256 * 1024 else None
    excuse = payload[0].get("excuse") if type(payload) == "list" and payload and type(payload[0]) == "dict" else None
    if type(excuse) != "string" or not excuse or len(excuse) > 500:
        return render.Root(child = render.Text("No excuse available", color = "#888"))

    direction = config.get("direction", DEFAULT_DIRECTION)
    if direction not in ["horizontal", "vertical"]:
        direction = DEFAULT_DIRECTION
    color = config.get("text_color", DEFAULT_COLOR)
    if type(color) != "string" or not re.match(r"^#[0-9a-fA-F]{6}$", color):
        color = DEFAULT_COLOR

    if (direction == "vertical"):
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            height = 32,
                            scroll_direction = "vertical",
                            child = render.WrappedText(
                                content = excuse,
                                width = 64,
                                color = color,
                            ),
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = excuse,
                                color = color,
                            ),
                        ),
                    ],
                ),
            ),
        )

def get_schema():
    directions = [
        schema.Option(display = "Horizontal", value = "horizontal"),
        schema.Option(display = "Vertical", value = "vertical"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "To set the color of the text.",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "direction",
                icon = "gear",
                name = "Direction",
                desc = "To control the direction of the marquee.",
                options = directions,
                default = DEFAULT_DIRECTION,
            ),
        ],
    )
