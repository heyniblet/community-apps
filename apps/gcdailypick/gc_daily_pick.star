"""
Applet: GC Daily Pick
Summary: Guitar Center daily pick
Description: Shows the daily pick deal from Guitar Center.
Author: Bennett Schoonerman
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/guitar_center_logo.png", GUITAR_CENTER_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GUITAR_CENTER_LOGO = GUITAR_CENTER_LOGO_ASSET.readall()
DAILY_PICK_READER_URL = "https://r.jina.ai/https://www.guitarcenter.com/Daily-Pick.gc"
IMAGE_PREFIX = "https://media.guitarcenter.com/"

def get_daily_pick():
    response = http.get(DAILY_PICK_READER_URL)
    body = response.body()
    if response.status_code != 200 or len(body) > 512 * 1024:
        return None

    deal = parse_deal(body)
    if not deal:
        return None

    image_url = deal.get("image_url")
    if type(image_url) == "string" and image_url.startswith(IMAGE_PREFIX) and len(image_url) <= 2048:
        image_response = http.get(image_url)
        if image_response.status_code == 200 and len(image_response.body()) <= 1024 * 1024:
            deal["image"] = image_response.body()
    return deal

def parse_deal(body):
    lines = body.split("\n")
    start = -1
    for index in range(len(lines)):
        if lines[index].strip() == "# Daily Pick":
            start = index
            break
    if start < 0:
        return None

    deal = {"image": GUITAR_CENTER_LOGO, "image_url": "", "name": "", "original": "", "savings": "", "price": ""}
    for line in lines[start + 1:min(start + 80, len(lines))]:
        line = line.strip()
        link_at = line.find("](")
        if line.startswith("![") and link_at > 2 and line.endswith(")") and not deal["image_url"]:
            deal["image_url"] = line[link_at + 2:-1]
            alt = line[2:link_at]
            deal["name"] = alt.split(": ")[-1][:160]
        elif line.startswith("## [") and link_at > 4:
            deal["name"] = line[4:link_at][:160]
        elif line.startswith("Save "):
            deal["savings"] = line[5:40]
        elif line.startswith("Regular Price:"):
            deal["original"] = line[14:].strip()[:24]
        elif line.startswith("$") and not deal["price"]:
            deal["price"] = line[:24]

    if not deal["name"] or not deal["price"]:
        return None
    return deal

def main(config):
    # ponytail: opt-in isolates the slow reader; replace it if Guitar Center offers a stable feed.
    if not config.bool("live", False):
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [render.Image(src = GUITAR_CENTER_LOGO, width = 32), render.WrappedText("Enable live deal", width = 30)],
            ),
        )
    deal = get_daily_pick()
    if not deal:
        return render.Root(child = render.WrappedText("Daily Pick unavailable", color = "#ffcc66"))

    details = render.Column(
        children = [
            render.Marquee(width = 64, child = render.Text(deal["name"]), offset_start = 5, offset_end = 32),
            render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Box(width = 40, height = 8, child = render.Text(deal["original"])),
                            render.Box(width = 40, height = 8, child = render.Text("-" + deal["savings"], color = "#EA202E")),
                            render.Box(width = 40, height = 1, child = render.Box(width = 30, height = 1, color = "#ccc")),
                            render.Box(width = 40, height = 8, child = render.Text(deal["price"], color = "#85BB65")),
                        ],
                    ),
                    render.Image(width = 24, height = 24, src = deal["image"]),
                ],
            ),
        ],
    )
    return render.Root(
        child = render.Stack(
            children = [
                animation.Transformation(
                    duration = 450,
                    child = render.Image(src = GUITAR_CENTER_LOGO, width = 64, height = 32),
                    keyframes = [
                        animation.Keyframe(percentage = 0, transforms = [animation.Translate(0, 0)]),
                        animation.Keyframe(percentage = 0.1, transforms = [animation.Translate(0, 0)]),
                        animation.Keyframe(percentage = 0.2, transforms = [animation.Translate(0, -64)]),
                        animation.Keyframe(percentage = 1, transforms = [animation.Translate(0, -64)], curve = "ease_in"),
                    ],
                ),
                animation.Transformation(
                    duration = 450,
                    child = details,
                    keyframes = [
                        animation.Keyframe(percentage = 0, transforms = [animation.Translate(0, 64)], curve = "ease_out"),
                        animation.Keyframe(percentage = 0.1, transforms = [animation.Translate(0, 64)], curve = "ease_out"),
                        animation.Keyframe(percentage = 0.2, transforms = [animation.Translate(0, 0)]),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "live",
                name = "Live Daily Pick",
                desc = "Fetch today's deal through the public Jina Reader fallback because Guitar Center blocks direct app requests.",
                icon = "music",
                default = False,
            ),
        ],
    )
