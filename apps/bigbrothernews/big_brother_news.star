"""
Applet: Big Brother News
Summary: Ticker for Big Blagger
Description: Shows the top story from bigblagger.co.uk.
Author: meejle
"""

load("http.star", "http")
load("images/news_icon.png", NEWS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

NEWS_ICON = NEWS_ICON_ASSET.readall()
PRIMARY_FEED = "https://bigblagger.co.uk/feed"
FALLBACK_FEED = "https://news.google.com/rss/search?q=site%3Abigblagger.co.uk&hl=en-GB&gl=GB&ceid=GB:en"
MAX_FEED_BYTES = 512 * 1024

def main(config):
    fontsize = config.get("fontsize", "tb-8")
    if fontsize not in ["tb-8", "tom-thumb"]:
        fontsize = "tb-8"
    articles = get_cacheable_data(PRIMARY_FEED, 1)
    if articles == None:
        articles = get_cacheable_data(FALLBACK_FEED, 1)

    if articles == None:
        return connectionError(config)

    if fontsize == "tb-8":
        return render.Root(
            delay = 50,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 24,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_larger(articles),
                            ),
                    ),
                ],
            ),
        )

    else:
        return render.Root(
            delay = 50,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 24,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_smaller(articles),
                            ),
                    ),
                ],
            ),
        )

def render_article_larger(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tb-8", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tb-8", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tb-8", color = "#faa708", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def render_article_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tom-thumb", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tom-thumb", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tom-thumb", color = "#faa708", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    errorHead = "Error: Couldn't get the top story"
    errorBlurb = "For the latest headlines, visit bigblagger .co.uk"
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 26,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = errorHead, width = 64, color = "#FFFFFF", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#faa708", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def get_cacheable_data(url, articlecount):
    articles = []

    res = http.get(url, ttl_seconds = 900)
    if res.status_code != 200:
        return None
    data = res.body()
    if len(data) > MAX_FEED_BYTES:
        return None

    data_xml = xpath.loads(data)

    for i in range(1, min(articlecount, 10) + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        title = data_xml.query(title_query)
        if type(title) == "string" and title:
            articles.append((title[:500], str(data_xml.query(desc_query)).replace("None", "")[:1000]))

    return articles if articles else None

def get_schema():
    fsoptions = [
        schema.Option(
            display = "Larger",
            value = "tb-8",
        ),
        schema.Option(
            display = "Smaller",
            value = "tom-thumb",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "fontsize",
                name = "Change the text size",
                desc = "To prevent long words falling off the edge.",
                icon = "textHeight",
                default = fsoptions[0].value,
                options = fsoptions,
            ),
        ],
    )
