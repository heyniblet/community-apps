"""
Applet: NOS
Summary: Laatste nieuws van NOS
Description: Laat een willekeurig recente nieuwsbericht zien van de website nos.nl.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("images/logo.png", LOGO_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

LOGO = LOGO_ASSET.readall()

DEFAULT_CATEGORY = "nosnieuwsalgemeen"
VALID_CATEGORIES = [
    "nosnieuwsalgemeen",
    "nosnieuwsbinnenland",
    "nosnieuwsbuitenland",
    "nosnieuwspolitiek",
    "nosnieuwseconomie",
    "nosnieuwsopmerkelijk",
    "nosnieuwskoningshuis",
    "nosnieuwscultuurenmedia",
    "nosnieuwstech",
    "nossportalgemeen",
    "nosvoetbal",
    "nossportwielrennen",
    "nossportschaatsen",
    "nossporttennis",
    "nossportformule1",
    "nieuwsuuralgemeen",
    "nosop3",
    "jeugdjournaal",
]

def get_news_feed(category = DEFAULT_CATEGORY, ttl_seconds = 60 * 5):
    if category not in VALID_CATEGORIES:
        category = DEFAULT_CATEGORY
    url = "https://feeds.nos.nl/{}".format(category)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Nos.nl request failed with status %d @ %s", response.status_code, url)
    body = response.body()
    if not body or len(body) > 512000:
        fail("Nos.nl returned an invalid feed")
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
    if not image_url.startswith("https://cdn.nos.nl/") and not image_url.startswith("https://images.cdn.nos.nl/"):
        return None

    # wd320
    response = http.get(url = image_url.replace("1008x567", "128x72a"), ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        return None
    body = response.body()
    return body if body and len(body) <= 2000000 else None

def main(config):
    category = config.str("category", DEFAULT_CATEGORY)

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
                                width = 8,
                                height = 8,
                            ),
                        ),
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#0008",
                            child = render.Marquee(
                                width = 64,
                                offset_start = 64,
                                offset_end = 64,
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
        schema.Option(display = "Nieuws algemeen", value = "nosnieuwsalgemeen"),
        schema.Option(display = "Nieuws binnenland", value = "nosnieuwsbinnenland"),
        schema.Option(display = "Nieuws buitenland", value = "nosnieuwsbuitenland"),
        schema.Option(display = "Nieuws politiek", value = "nosnieuwspolitiek"),
        schema.Option(display = "Nieuws economie", value = "nosnieuwseconomie"),
        schema.Option(display = "Nieuws opmerkelijk", value = "nosnieuwsopmerkelijk"),
        schema.Option(display = "Nieuws koningshuis", value = "nosnieuwskoningshuis"),
        schema.Option(display = "Nieuws cultuur en media", value = "nosnieuwscultuurenmedia"),
        schema.Option(display = "Nieuws tech", value = "nosnieuwstech"),
        schema.Option(display = "Sport algemeen", value = "nossportalgemeen"),
        schema.Option(display = "Sport voetbal", value = "nosvoetbal"),
        schema.Option(display = "Sport wielrennen", value = "nossportwielrennen"),
        schema.Option(display = "Sport schaatsen", value = "nossportschaatsen"),
        schema.Option(display = "Sport tennis", value = "nossporttennis"),
        schema.Option(display = "Sport formule1", value = "nossportformule1"),
        schema.Option(display = "Nieuwsuur", value = "nieuwsuuralgemeen"),
        schema.Option(display = "NOS op 3", value = "nosop3"),
        schema.Option(display = "NOS Jeugdjournaal", value = "jeugdjournaal"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "Nieuws categorie",
                desc = "Kies een nieuws categorie",
                default = DEFAULT_CATEGORY,
                options = categories,
                icon = "newspaper",
            ),
        ],
    )
