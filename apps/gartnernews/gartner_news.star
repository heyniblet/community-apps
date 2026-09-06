"""
Applet: Gartner News
Summary: Gartner News Display
Description: Display Gartner News Feed.
Author: Robert Ison
"""

load("http.star", "http")
load("images/gartner_logo.png", GARTNER_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

GARTNER_LOGO = GARTNER_LOGO_ASSET.readall()
GARTNER_NEWS_URL = "https://news.google.com/rss/search?q=site%3Agartner.com%2Fen%2Fnewsroom&hl=en-US&gl=US&ceid=US%3Aen"

def main(config):
    response = http.get(GARTNER_NEWS_URL)
    body = response.body()
    if response.status_code != 200 or len(body) > 512 * 1024 or "<rss" not in body:
        return message("Gartner news unavailable")

    document = xpath.loads(body)
    titles = []
    for index in range(1, min(body.count("<item>"), 20) + 1):
        title = document.query("//item[%d]/title" % index)
        if type(title) == "string" and title:
            titles.append(title.replace(" - Gartner", "")[:180])
    if not titles:
        return message("No Gartner headlines")

    rows = ["", ""]
    row = 0
    for title in titles:
        candidate = title if not rows[row] else "%s - %s" % (rows[row], title)
        if len(candidate) > 180:
            if row == 1:
                break
            row = 1
            candidate = title
        rows[row] = candidate[:180]

    delay = config.get("scroll", "60")
    if delay not in ["30", "45", "60"]:
        delay = "60"
    return render.Root(
        render.Column(
            children = [
                render.Image(GARTNER_LOGO),
                render.Box(height = 3),
                render.Marquee(width = 64, offset_start = 5, offset_end = 64, child = render.Text(rows[0], color = "#FFF000", font = "5x8")),
                render.Box(height = 3),
                render.Marquee(width = 64, offset_start = len(rows[0]) * 5, offset_end = 64, child = render.Text(rows[1], color = "#FFF000", font = "tb-8")),
            ],
        ),
        show_full_animation = True,
        delay = int(delay),
    )

def message(text):
    return render.Root(child = render.WrappedText(text, color = "#ffcc66"))

def get_schema():
    options = [
        schema.Option(display = "Slow Scroll", value = "60"),
        schema.Option(display = "Medium Scroll", value = "45"),
        schema.Option(display = "Fast Scroll", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = options,
                default = options[0].value,
            ),
        ],
    )
