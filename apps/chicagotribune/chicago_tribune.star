"""
Applet: Chicago Tribune
Summary: Chicago Tribune News
Description: Latest news, sports and other topics from the Chicago Tribune. Choose from either the latest headlines or latest stories.
Author: sgomez72
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# Declare Constants
DEFAULT_NEWS = "news"
DEFAULT_SETTING = "0"

TRIBUNE_URL = "https://www.chicagotribune.com/{}/"
MAX_RESPONSE_BYTES = 512 * 1024
CHANNELS = ["news", "business", "things-to-do", "things-to-do/restaurants-food-drink", "nation", "news/world", "opinion", "sports", "espanol"]

def main(config):
    channel = config.get("tribune_feed", DEFAULT_NEWS)
    if channel not in CHANNELS:
        channel = DEFAULT_NEWS
    type = config.get("news_format", DEFAULT_SETTING)
    if type not in ["0", "1"]:
        type = DEFAULT_SETTING

    stories = get_cacheable_data(channel)
    if not stories:
        return render.Root(child = render.WrappedText("Chicago Tribune unavailable", align = "center", width = 64))

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    height = 9,
                    width = 64,
                    color = "#000",
                    child = render.Text(
                        content = "Chicago Tribune",
                        font = "tom-thumb",
                        color = "#1162a5",
                    ),
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = "#fff",
                ),
                render.Marquee(
                    height = 30,
                    offset_start = 30,
                    child = render.Column(
                        main_align = "space_between",
                        children = render_content(stories, type),
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def render_content(stories, style):
    # renders the display based on the user's choice
    news_content = []

    if style == "0":  # Display the three latest headlines
        for eachStory in stories:
            news_content.append(render.WrappedText(content = eachStory[0], color = "#fa0"))
            news_content.append(render.Box(width = 64, height = 2, color = "#000"))
    else:  # Display the latest story
        news_content.append(render.WrappedText(content = stories[0][0], color = "#fa0"))
        news_content.append(render.WrappedText(content = stories[0][1], color = "#fff"))

    return news_content

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "tribune_feed",
                name = "News Page",
                desc = "Select which category to display.",
                icon = "newspaper",
                default = "news",
                options = [
                    schema.Option(
                        display = "News",
                        value = "news",
                    ),
                    schema.Option(
                        display = "Business",
                        value = "business",
                    ),
                    schema.Option(
                        display = "Things to Do Around Chicago",
                        value = "things-to-do",
                    ),
                    schema.Option(
                        display = "Food & Drink",
                        value = "things-to-do/restaurants-food-drink",
                    ),
                    schema.Option(
                        display = "National",
                        value = "nation",
                    ),
                    schema.Option(
                        display = "World",
                        value = "news/world",
                    ),
                    schema.Option(
                        display = "News",
                        value = "news",
                    ),
                    schema.Option(
                        display = "Opinion",
                        value = "opinion",
                    ),
                    schema.Option(
                        display = "Sports",
                        value = "sports",
                    ),
                    schema.Option(
                        display = "Noticias en Español",
                        value = "espanol",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "news_format",
                name = "News Format",
                desc = "Display the latest article or latest headlines.",
                icon = "circleQuestion",
                default = "0",
                options = [
                    schema.Option(
                        display = "Top Headlines",
                        value = "0",
                    ),
                    schema.Option(
                        display = "Top Story",
                        value = "1",
                    ),
                ],
            ),
        ],
    )

def get_cacheable_data(url):
    rep = http.get(
        TRIBUNE_URL.format(url),
        headers = {"User-Agent": "Mozilla/5.0 (compatible; Niblet/1.0)"},
        ttl_seconds = 1800,
    )
    body = rep.body()
    if rep.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return []
    main_parts = body.split('<main id="main"', 1)
    page = main_parts[1] if len(main_parts) == 2 else body
    titles = re.findall(r'(?s)<span class="dfm-title[^>]*>\s*(.*?)\s*</span>', page)[:3]
    descriptions = re.findall(r'(?s)<div class="excerpt">\s*(.*?)\s*</div>', page)[:3]
    headlines = []
    for i, title in enumerate(titles):
        description = descriptions[i] if i < len(descriptions) else ""
        headlines.append([clean_text(title)[:300], clean_text(description)[:1000]])
    return [headline for headline in headlines if headline[0]]

def clean_text(value):
    value = re.sub("<[^>]*>", " ", str(value or ""))
    for entity, char in [("&amp;", "&"), ("&#8217;", "'"), ("&#8216;", "'"), ("&apos;", "'"), ("&#39;", "'"), ("&quot;", "\""), ("&nbsp;", " ")]:
        value = value.replace(entity, char)
    return " ".join(value.split())
