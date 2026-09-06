"""
Applet: Guardian News
Summary: Latest news
Description: Show the latest Guardian top story from your preferred edition.
Author: meejle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/news_icon.gif", NEWS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NEWS_ICON = NEWS_ICON_ASSET.readall()
API_URL = "https://content.guardianapis.com/"
MAX_RESPONSE_BYTES = 1024 * 1024
EDITIONS = ["uk", "us", "au", "international"]
FONTS = ["tb-8", "tom-thumb"]

def main(config):
    edition = config.get("edition", "uk")
    fontsize = config.get("fontsize", "tb-8")
    api_key = config.get("api_key")
    edition = edition if edition in EDITIONS else "uk"
    fontsize = fontsize if fontsize in FONTS else "tb-8"
    if not valid_key(api_key):
        return connection_error(fontsize, "Configure Guardian API key")

    response = http.get(
        API_URL + edition,
        params = {"show-editors-picks": "true", "api-key": api_key, "show-fields": "trailText"},
    )
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return connection_error(fontsize, "Guardian unavailable")
    payload = json.decode(body, {})
    api_response = payload.get("response", {}) if type(payload) == "dict" else {}
    stories = api_response.get("editorsPicks", []) if type(api_response) == "dict" else []
    story = stories[0] if type(stories) == "list" and stories and type(stories[0]) == "dict" else None
    if story == None:
        return connection_error(fontsize, "No top story")

    headline = safe_text(story.get("webTitle"), 300)
    section = safe_text(story.get("sectionName"), 80)
    pillar = safe_text(story.get("pillarName"), 40)
    fields = story.get("fields", {})
    blurb = strip_markup(safe_text(fields.get("trailText"), 1000) if type(fields) == "dict" else "")
    if not headline:
        return connection_error(fontsize, "No top story")
    pillar_color = {"Opinion": "#ff7f0f", "Sport": "#00b2ff", "Arts": "#eacca0", "Lifestyle": "#ffabdb"}.get(pillar, "#ff5944")
    return render_story(section, headline, blurb, fontsize, pillar_color)

def render_story(section, headline, blurb, fontsize, pillar_color):
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 27,
            offset_end = 32,
            child = render.Column(
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = section or "News", width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 1),
                    render.Box(width = 64, height = 1, color = pillar_color),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = headline, width = 64, color = pillar_color, font = fontsize, linespacing = 1),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = blurb, width = 64, color = "#fff", font = fontsize, linespacing = 1),
                ],
            ),
        ),
    )

def connection_error(fontsize, message):
    return render_story("Error", message, "Visit theguardian.com for headlines", fontsize, "#ff5944")

def valid_key(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 256 and all([char.isalnum() or char in "-_" for char in value.elems()])

def safe_text(value, maximum):
    return value[:maximum] if type(value) == "string" else ""

def strip_markup(value):
    for tag in ["<strong>", "</strong>", "<em>", "</em>", "<b>", "</b>", "<i>", "</i>", "<p>", "</p>"]:
        value = value.replace(tag, "")
    return value

def get_schema():
    editions = [
        schema.Option(display = "UK", value = "uk"),
        schema.Option(display = "US", value = "us"),
        schema.Option(display = "Australia", value = "au"),
        schema.Option(display = "International", value = "international"),
    ]
    fonts = [schema.Option(display = "Larger", value = "tb-8"), schema.Option(display = "Smaller", value = "tom-thumb")]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(id = "edition", name = "Choose your Edition", desc = "Get news relevant to you.", icon = "newspaper", default = "uk", options = editions),
            schema.Dropdown(id = "fontsize", name = "Change the text size", desc = "Use smaller text for long words.", icon = "textHeight", default = "tb-8", options = fonts),
            schema.Text(id = "api_key", name = "Guardian API Key", desc = "Your Guardian Open Platform key.", icon = "key", secret = True),
        ],
    )
