"""
Applet: TransSee
Summary: Realtime transit prediction
Description: Provides real-time transit predictions based on actual travel times for over 150 agencies. Requires paid premium. See transsee.ca/tidbyt for usage information
Author: doconno@gmail.com
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    premium = config.str("id")
    if not premium:
        # Show example image by default when no TransSee Premium Id entered
        return render.Root(render.Column(children = [
            render.Row(children = [
                render.Box(width = 17, height = 8, color = "#6CBE45", child = render.Text(content = "B54", color = "#FFFFFF")),
                render.Text(content = "→7-9,→22-27"),
            ]),
            render.Marquee(width = 64, child = render.Text("See transsee.ca/tidbyt for usage")),
        ]))
    elif re.match(r"^[A-Za-z0-9_-]{1,128}$", premium):
        rep = http.get("https://www.transsee.ca/bitmap", params = {"premium": premium})
        body = rep.body()
        jsonarray = json.decode(body, []) if rep.status_code == 200 and body and len(body) <= 64 * 1024 else []
        if type(jsonarray) == "list":
            col = []
            for item in jsonarray[:6]:
                if type(item) != "dict":
                    continue
                route = bounded_text(item.get("routeName"), 12)
                prediction = bounded_text(item.get("pred"), 32)
                destination = bounded_text(item.get("dest"), 80)
                if not route or not prediction:
                    continue
                col.append(render.Row(
                    children = [
                        render.Box(width = 17, height = 8, color = valid_color(item.get("routeColour"), "#6CBE45"), child = render.Text(content = route, color = valid_color(item.get("textColour"), "#FFFFFF"))),
                        render.Text(content = prediction),
                    ],
                ))
                if len(jsonarray) <= 2:
                    if config.bool("scroll"):
                        col.append(render.Marquee(width = 64, child = render.Text(destination)))
                    else:
                        col.append(render.Text(destination))

            return render.Root(render.Column(children = col)) if col else []
    return []

def bounded_text(value, limit):
    return value[:limit] if type(value) == "string" else ""

def valid_color(value, fallback):
    return value if type(value) == "string" and re.match(r"^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$", value) else fallback

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "id",
                name = "TransSee Premium Id",
                desc = "In premium email or transsee.ca/tidbyt",
                icon = "hashtag",
                secret = True,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll destination",
                desc = "Horizontally scroll the destination when it doesn't fit.",
                icon = "leftRight",
                default = True,
            ),
        ],
    )
