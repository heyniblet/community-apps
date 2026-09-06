"""
Applet: Nunl
Summary: Latest news from nu.nl
Description: Shows random one of the latest news items from the Dutch website nu.nl.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("images/logo.gif", LOGO_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

LOGO = LOGO_ASSET.readall()

DEFAULT_CATEGORY = "Algemeen"
VALID_CATEGORIES = ["Algemeen", "Economie", "Sport", "Achterklap", "Opmerkelijk", "Muziek", "Film", "Wetenschap", "Tech", "Gezondheid", "Podcast"]

def get_news_feed(category = DEFAULT_CATEGORY, ttl_seconds = 60 * 5):
    if category not in VALID_CATEGORIES:
        category = DEFAULT_CATEGORY
    url = "https://www.nu.nl/rss/{}".format(category)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Nu.nl request failed with status %d @ %s", response.status_code, url)
    body = response.body()
    if not body or len(body) > 524288:
        fail("Nu.nl returned an invalid feed")
    return body

def get_nth_item_from_raw_xml(raw_xml, nth = 1):
    feed_item = xpath.loads(raw_xml).query_node("//rss/channel/item[{}]".format(nth))
    if feed_item == None:
        return {"title": "Geen recent nieuws", "image": ""}
    return {
        "title": feed_item.query("/title") or "Geen recent nieuws",
        "image": feed_item.query("/enclosure/@url") or "",
    }

def get_image(image_url):
    if type(image_url) != "string" or not image_url.startswith("https://images.nu.nl/"):
        return None
    response = http.get(url = image_url.replace("sqr256.jpg", "std160"), ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        return None
    body = response.body()
    return body if body and len(body) <= 2000000 else None

def main(config):
    category = config.str("category", DEFAULT_CATEGORY)
    if category not in VALID_CATEGORIES:
        category = DEFAULT_CATEGORY

    news_feed = get_news_feed(category)
    nth_item = random.number(1, 10)
    news_item = get_nth_item_from_raw_xml(news_feed, nth_item)
    image = get_image(news_item["image"])
    background = render.Image(src = image, width = 64, height = 32) if image else render.Box(width = 64, height = 32, color = "#000")

    return render.Root(
        show_full_animation = True,
        max_age = 60 * 5,
        child = render.Stack(
            children = [
                background,
                render.Column(
                    main_align = "space_between",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (1, 1, 1, 1),
                            child = render.Image(
                                src = LOGO,
                                width = 10,
                                height = 10,
                            ),
                        ),
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#0008",
                            child = render.Marquee(
                                width = 64,
                                offset_start = 64,
                                child = render.Text(
                                    content = news_item["title"],
                                    font = "tb-8",
                                    color = "#fff",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    categories = [
        schema.Option(display = "Algemeen", value = "Algemeen"),
        schema.Option(display = "Economie", value = "Economie"),
        schema.Option(display = "Sport", value = "Sport"),
        schema.Option(display = "Achterklap", value = "Achterklap"),
        schema.Option(display = "Opmerkelijk", value = "Opmerkelijk"),
        schema.Option(display = "Muziek", value = "Muziek"),
        schema.Option(display = "Film", value = "Film"),
        schema.Option(display = "Wetenschap", value = "Wetenschap"),
        schema.Option(display = "Tech", value = "Tech"),
        schema.Option(display = "Gezondheid", value = "Gezondheid"),
        schema.Option(display = "Podcast", value = "Podcast"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "News category",
                desc = "Choose a news category",
                default = categories[0].value,
                options = categories,
                icon = "newspaper",
            ),
        ],
    )
