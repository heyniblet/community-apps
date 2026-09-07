"""
Applet: Czechianews
Summary: Headline news from Czechia
Description: Dispaly only the news title from Czechia.
Author: solarisle
"""

load("html.star", "html")
load("http.star", "http")
load("images/irozhlas_icon.webp", IROZHLAS_ICON_ASSET = "file")
load("images/seznam_icon.webp", SEZNAM_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IROZHLAS_ICON = IROZHLAS_ICON_ASSET.readall()
SEZNAM_ICON = SEZNAM_ICON_ASSET.readall()

MEDIA_SEZNAM = "seznam"
MEDIA_IROZHLAS = "irozhlas"

SEZNAM_URL = "https://www.seznamzpravy.cz/rss"
IROZHLAS_URL = "https://www.irozhlas.cz/rss/irozhlas"

DEFAULT_COLOR = "#FF0000"
TEXT_SPEED = "100"

def main(config):
    media_source = config.str("media_source", MEDIA_SEZNAM)
    if media_source not in [MEDIA_SEZNAM, MEDIA_IROZHLAS]:
        media_source = MEDIA_SEZNAM
    response = http.get(SEZNAM_URL if media_source == MEDIA_SEZNAM else IROZHLAS_URL, ttl_seconds = 600)

    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return render.Root(
            child = render.WrappedText(
                content = "Web source not availible now",
                color = DEFAULT_COLOR,
                width = 64,
            ),
        )

    news_title = parse_headline(response.body())

    return render_text(config, media_source, news_title)

def parse_headline(body):
    titles = html(body).find("item").eq(0).find("title")
    title = titles.eq(0).text().strip() if titles.len() else ""
    return title[:300] if title else "There is no news..."

def config_color(config):
    color = config.str("font_color", DEFAULT_COLOR)
    return color if len(color) in [4, 7] and color.startswith("#") and all([char in "0123456789abcdefABCDEF" for char in color[1:].codepoints()]) else DEFAULT_COLOR

def render_text(config, media_source, headlineText):
    if media_source == MEDIA_SEZNAM:
        iconFile = SEZNAM_ICON
    else:
        iconFile = IROZHLAS_ICON

    return render.Root(
        delay = int(config.str("text_speed", TEXT_SPEED)),
        child = render.Marquee(
            width = 64,
            height = 32,
            scroll_direction = "vertical",
            align = "center",
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Image(src = iconFile, width = 12, height = 12),
                    render.WrappedText(
                        content = headlineText,
                        color = config_color(config),
                        width = 64,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "font_color",
                name = "Font Color",
                desc = "Color of the font",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Dropdown(
                id = "text_speed",
                name = "Display Speed",
                desc = "The speed for rotating the text.",
                icon = "personRunning",
                default = "100",
                options = [
                    schema.Option(
                        display = "Fast",
                        value = "50",
                    ),
                    schema.Option(
                        display = "Normal",
                        value = "100",
                    ),
                    schema.Option(
                        display = "Slow",
                        value = "150",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "media_source",
                name = "Media Source",
                desc = "Select your favorite news source.",
                icon = "bars",
                default = "seznam",
                options = [
                    schema.Option(
                        display = "seznamzpravy.cz",
                        value = "seznam",
                    ),
                    schema.Option(
                        display = "irozhlas.cz",
                        value = "irozhlas",
                    ),
                ],
            ),
        ],
    )
