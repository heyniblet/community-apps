"""
Applet: RSS Misc Feeds
Summary: Provides misc RSS Feeds
Description: Based upon a curated list, allow user to select display of various RSS feeds not covered in standalone apps.
Author: jvivona
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23318
# jvivoan - 20231114 - added more articles as per request ** NOTE:  Marquee is limited to 320px high - so text will get cut off after about 40 total lines of text regardless of what you select here  **

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900
MAX_FEED_BYTES = 1024 * 1024

FEEDS = [
    {"value": "0", "url": "https://movieweb.com/feed/", "display": "MovieWeb", "shortName": "MovieWeb", "showdesc": True, "descElement": "description", "itemElement": "item"},
    {"value": "1", "url": "https://www.polygon.com/feed/", "display": "Polygon", "shortName": "Polygon", "showdesc": False, "descElement": "description", "itemElement": "item"},
    {"value": "2", "url": "https://slickdeals.net/newsearch.php?searchin=first&forumchoice[]=9&rss=1", "display": "Slickdeals Hot Deals", "shortName": "Slickdeals", "showdesc": False, "descElement": "description", "itemElement": "item"},
    {"value": "3", "url": "https://www.theverge.com/rss/index.xml", "display": "The Verge - All Posts", "shortName": "The Verge", "showdesc": False, "descElement": "content", "itemElement": "entry"},
    {"value": "4", "url": "https://la.eater.com/rss/front-page/index.xml", "display": "LA Eater - Front Page", "shortName": "LA Eater", "showdesc": False, "descElement": "content", "itemElement": "entry"},
    {"value": "5", "url": "https://9to5google.com/feed/", "display": "9 to 5 Google", "shortName": "9 to 5 Google", "showdesc": False, "descElement": "content", "itemElement": "item"},
    {"value": "6", "url": "https://9to5mac.com/feed/", "display": "9 to 5 Mac", "shortName": "9 to 5 Mac", "showdesc": False, "descElement": "content", "itemElement": "item"},
    {"value": "7", "url": "https://admin.cnnbrasil.com.br/feed/", "display": "CNN Brasil", "shortName": "CNN Brasil", "showdesc": False, "descElement": "description", "itemElement": "item"},
    {"value": "8", "url": "https://feeds.arstechnica.com/arstechnica/index.rss", "display": "Ars Technica - All News", "shortName": "Ars Technica", "showdesc": True, "descElement": "description", "itemElement": "item"},
]

DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#cccccc33"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#65d0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#ff8c00"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

def main(config):
    selected_feed = FEEDS[1]
    for feed in FEEDS:
        if feed["value"] == config.get("feed", "1"):
            selected_feed = feed
            break
    articlecount = config.get("articlecount", DEFAULT_ARTICLE_COUNT)
    articlecount = int(articlecount) if str(articlecount).isdigit() and 1 <= int(articlecount) and int(articlecount) <= 5 else int(DEFAULT_ARTICLE_COUNT)
    articles = get_feed(selected_feed["url"], articlecount, selected_feed)
    if articles == None or len(articles) == 0:
        return render.Root(child = render.WrappedText("Feed unavailable", width = 64, align = "center"))

    if canvas.is2x():
        return render_2x(articles, selected_feed)
    return render_1x(articles, selected_feed)

def render_1x(articles, selected_feed):
    # 64x32 layout (unchanged): feed shortName title bar over the scrolling
    # body (description shown per the feed's showdesc flag).
    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Text(selected_feed["shortName"], color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(articles, selected_feed["showdesc"]),
                        ),
                ),
            ],
        ),
    )

def render_2x(articles, selected_feed):
    # 128x64 layout: fixed feed-name header, then each article as a white
    # headline; the description is shown when the feed opts in (showdesc).
    show_desc = selected_feed["showdesc"]
    body = []
    for article in articles:
        body.append(render.WrappedText(content = clean_text(article[0]), color = TEXT_COLOR, font = ARTICLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 2, color = SPACER_COLOR))
        desc = clean_text(article[1])
        if show_desc and desc != "":
            body.append(render.WrappedText(content = desc, color = ARTICLE_COLOR, font = ARTICLE_SUB_TITLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 9, color = SPACER_COLOR))

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 128,
                    height = 9,
                    color = TITLE_BKG_COLOR,
                    child = render.Text(selected_feed["shortName"], color = TITLE_TEXT_COLOR, font = ARTICLE_FONT),
                ),
                render.Marquee(
                    height = 55,
                    scroll_direction = "vertical",
                    offset_start = 55,
                    child = render.Column(children = body),
                ),
            ],
        ),
    )

def render_article(news, showDesc):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText(clean_text(article[0]), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
        if showDesc:
            news_text.append(render.WrappedText(clean_text(article[1]), font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 8, color = SPACER_COLOR))

    return (news_text)

def clean_text(s):
    if not s:
        return ""

    # RSS text comes through with HTML entities (e.g. &apos; &quot;); unescape
    # the common ones. &amp; is handled first so double-escaped entities resolve.
    for entity, char in [("&amp;", "&"), ("&apos;", "'"), ("&#39;", "'"), ("&quot;", "\""), ("&#34;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " ")]:
        s = s.replace(entity, char)
    return s.strip()

def get_schema():
    feed_options = []
    for feed in FEEDS:
        feed_options.append(
            schema.Option(
                display = feed["display"],
                value = feed["value"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feed",
                name = "RSS Feed",
                desc = "Select which feed to display",
                icon = "newspaper",
                default = feed_options[1].value,
                options = feed_options,
            ),
            schema.Dropdown(
                id = "articlecount",
                name = "Article Count",
                desc = "Select number of articles to display",
                icon = "hashtag",
                default = "3",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
                    ),
                ],
            ),
        ],
    )

def get_feed(url, articlecount, selected_feed):
    articles = []
    data = get_cacheable_data(url)
    if data == None:
        return None

    data_xml = xpath.loads(data)
    for i in range(1, articlecount + 1):
        title_query = "//%s[%s]/title" % (selected_feed["itemElement"], str(i))
        desc_query = "//%s[%s]/%s" % (selected_feed["itemElement"], str(i), selected_feed["descElement"])
        title = data_xml.query(title_query)
        if title:
            articles.append((clean_text(str(title))[:160], clean_text(str(data_xml.query(desc_query) or ""))[:320]))

    return articles

def get_cacheable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    return body if res.status_code == 200 and body and len(body) <= MAX_FEED_BYTES else None
