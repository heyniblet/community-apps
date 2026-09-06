"""
Applet: Wiki Page Today
Summary: Wikipedia Featured Article
Description: Display Wikipedia's Featured Article of the Day in a Tidbyt format.
Author: UnBurn
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIKIPEDIA_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAQAAAClB0z9AAAAHUlEQVR42mNgYPgPB0AOkIBxQBhK
4eIiGCAS1SgAimpBv3jp7u8AAAAASUVORK5CYII=""")
WIKIPEDIA_THUMBNAIL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAABk0lEQVR42t3Vv2uTQRgH8CcRUdRB
RNSioIjUQXRQBG2xk9BBJ1FwEooEF8lW/4FMNpNi/bk4mLFFQxdBQZwihTiIUMFBRUTQQVtM5W1z
H0GylTTRdxG/tzzD3QfuhvtGhGIqpWbK6D8pS81UUozfx2v+MqmmGKkkR1IpUjMX0IwskyNZFnLm
fwKqKp31DHc680Pc68xzvunsUV0JvHRRCHWf8cqQMOod3jhrrZoFSxpOKSibXQnw3WahDmgo2KmF
5LBLAMac6f4GV4QRACeFG5ix3gfAVxvMdgc+WqfgBeCpsNtPQ8oAJozQHWBMOAdIjgkXbPQJsGyv
6dWB14rWeAt4JIRxAHX7LK8OcFq4DGg7KDwAMOo6vYDnwiZfAMeFQ9pgzhbzPYHOzSvgsW0GhWlQ
Nk5vgClhu5bkhKr7whHJvK3e9we0DQp3PTHgh8weYcZN5+kP4Law37BrYFI46oBG/0DLDmGXRdAy
IAzTP0BFuAVgQpj6M2DBVUsAFk1q/7s/UsrkSMpyF0vuastfrnnr/RfBJHmDsmOptgAAAABJRU5E
rkJggg==
""")

WIKIPEDIA_URL = "https://api.wikimedia.org/feed/v1/wikipedia/%s/featured/%s"
WIKIPEDIA_HEADER = {"Accept": "application/json", "User-Agent": "WikiPageToday/1.0 (https://github.com/tronbyt/apps)"}

TTL_TIME = 21600
MAX_RESPONSE_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024
SUPPORTED_LANGS = ["de", "en", "hu", "la", "sv"]
MARQUEE_DELAY = 150

DEFAULT_LANG = "en"
DEFAULT_COLOR = "#FFFFFF"

def get_featured_article_json(lang, date):
    if lang not in SUPPORTED_LANGS:
        lang = DEFAULT_LANG
    url = WIKIPEDIA_URL % (lang, date)
    response = http.get(url, headers = WIKIPEDIA_HEADER, ttl_seconds = TTL_TIME)
    body = response.body()
    article_json = json.decode(body, {}) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else {}
    return article_json if type(article_json) == "dict" else {}

def extract_article_information(article_json):
    article = article_json["tfa"]
    titles = article.get("titles", {})
    title = titles.get("normalized") if type(titles) == "dict" else None
    title = title or article.get("normalizedtitle") or article.get("title") or "Featured article"
    title = title[:300] if type(title) == "string" else "Featured article"
    extract = article.get("extract", "")
    extract = extract[:5000] if type(extract) == "string" else ""
    description = get_reduced_extract(extract)
    image = WIKIPEDIA_THUMBNAIL
    thumbnail = article.get("thumbnail", {})
    if type(thumbnail) == "dict" and "source" in thumbnail:
        image_url = thumbnail["source"]
        if type(image_url) == "string" and image_url.startswith("https://upload.wikimedia.org/"):
            response = http.get(image_url, headers = WIKIPEDIA_HEADER, ttl_seconds = TTL_TIME)
            body = response.body()
            content_type = response.headers.get("Content-Type", response.headers.get("content-type", ""))
            if response.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES and content_type.startswith("image/"):
                image = body
    return (title, description, image)

def has_featured_article(article_json):
    return type(article_json) == "dict" and type(article_json.get("tfa")) == "dict" and type(article_json["tfa"].get("extract")) == "string"

def get_reduced_extract(extract):
    MAX_LENGTH = 100

    if not extract:
        return "Featured article details are unavailable."
    sentences = extract.split(".")
    ret = sentences[0] + "."
    for s in sentences[1:]:
        new_sentence = ret + s + "."
        if s != "" and len(new_sentence) <= MAX_LENGTH:
            ret = new_sentence
        else:
            break

    return ret

def main(config):
    CURRENT_ARTICLE_UNAVAILABLE = False
    PREVIOUS_ARTICLE_UNAVAILABLE = False

    lang = config.str("lang", DEFAULT_LANG)
    today = time.now().format("2006/01/02")
    article_json = get_featured_article_json(lang, today)
    title = ""
    image = ""
    description = ""

    # Check if the current day's article is present in the JSON
    if has_featured_article(article_json):
        title, description, image = extract_article_information(article_json)
    else:
        # Otherwise, get yesterday's article
        CURRENT_ARTICLE_UNAVAILABLE = True
        yesterday = (time.now() - time.parse_duration("24h")).format("2006/01/02")
        article_json = get_featured_article_json(lang, yesterday)
        if has_featured_article(article_json):
            title, description, image = extract_article_information(article_json)
        else:
            PREVIOUS_ARTICLE_UNAVAILABLE = True

    # If neither the current nor previous article can be found, render a retryable fallback.
    if CURRENT_ARTICLE_UNAVAILABLE and PREVIOUS_ARTICLE_UNAVAILABLE:
        title = "Wikipedia"
        description = "Featured article is currently unavailable."
        image = WIKIPEDIA_THUMBNAIL

    top_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 6, color = "#3f3f3f"),
            render.Row(
                children = [
                    render.Padding(child = render.Image(src = WIKIPEDIA_ICON, width = 7, height = 6), pad = (1, 0, 1, 0)),
                    render.Marquee(
                        width = 56,
                        delay = MARQUEE_DELAY,
                        child = render.Text(
                            title,
                            font = "tom-thumb",
                        ),
                    ),
                ],
            ),
        ],
    )

    body = render.Row(
        children = [
            render.Padding(child = render.Image(src = image, width = 16, height = 25), pad = (0, 0, 1, 0)),
            render.Marquee(
                height = 25,
                delay = MARQUEE_DELAY,
                scroll_direction = "vertical",
                child = (
                    render.WrappedText(
                        content = description,
                        font = "tb-8",
                        color = config.str("color", DEFAULT_COLOR),
                    )
                ),
            ),
        ],
    )

    return render.Root(
        max_age = TTL_TIME,
        show_full_animation = True,
        delay = 20,
        child = render.Column(
            children = [top_bar, render.Box(color = "#fff", width = 64, height = 1), body],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Deutsch",
            value = "de",
        ),
        schema.Option(
            display = "English",
            value = "en",
        ),
        schema.Option(
            display = "Magyar",
            value = "hu",
        ),
        schema.Option(
            display = "Latina",
            value = "la",
        ),
        schema.Option(
            display = "Svenska",
            value = "sv",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "lang",
                name = "Language",
                desc = "The language of the article",
                icon = "language",
                default = "en",
                options = options,
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "The color of the font",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
        ],
    )
