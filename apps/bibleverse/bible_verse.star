"""
Applet: Bible Verse
Summary: Bible verse every 3 minutes
Description: Displays new bible verse every 3 seconds from different bible translations.
Author: blaiseAI
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://bible-api.com/?random=verse&translation={}"

DEFAULT_TRANSLATION = "kjv"
DEFAULT_REFERENCE_COLOR = "#00FF00"
TRANSLATIONS = ["kjv", "asv", "web", "oeb-us"]
MAX_RESPONSE_BYTES = 64 * 1024

def main(config):
    translation = config.get("translation", DEFAULT_TRANSLATION)
    if translation not in TRANSLATIONS:
        translation = DEFAULT_TRANSLATION
    color = config.str("color", DEFAULT_REFERENCE_COLOR)
    response = http.get(API_URL.format(translation), ttl_seconds = 180)
    if response.status_code != 200:
        return render.Root(child = render.WrappedText(content = "Bible API unavailable", align = "center"))

    body = response.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return render.Root(child = render.WrappedText(content = "Bible API unavailable", align = "center"))
    data = json.decode(body)
    verses = data.get("verses") if type(data) == "dict" else None
    verse = verses[0] if type(verses) == "list" and verses else None
    verse_text = verse.get("text") if type(verse) == "dict" else None
    reference = data.get("reference") if type(data) == "dict" else None
    if type(verse_text) != "string" or type(reference) != "string" or not verse_text or not reference:
        return render.Root(child = render.WrappedText(content = "Bible API unavailable", align = "center"))
    verse_text = verse_text.strip()[:2000]
    reference = reference[:120]
    return render.Root(
        delay = 100,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = reference,
                    color = color,
                    font = "CG-pixel-3x5-mono",
                ),
                render.Marquee(
                    width = 64,
                    height = 32,
                    child = render.Text(
                        content = verse_text,
                        color = "#FFFFFF",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Color",
                desc = "The color of the text reference.",
                icon = "brush",
                default = DEFAULT_REFERENCE_COLOR,
                palette = [
                    DEFAULT_REFERENCE_COLOR,
                    "#FF0000",
                    "#0000FF",
                    "#BFEDC4",
                    "#00FF00",
                    "#FF00FF",
                    "#00FFFF",
                    "#78DECC",
                    "#DBB5FF",
                ],
            ),
            schema.Dropdown(
                id = "translation",
                name = "Translation",
                desc = "The translation to use for the Bible verses.",
                icon = "book",
                default = DEFAULT_TRANSLATION,
                options = [
                    schema.Option("KJV", "kjv"),
                    schema.Option("ASV", "asv"),
                    schema.Option("WEB", "web"),
                    schema.Option("OEB-US", "oeb-us"),
                ],
            ),
        ],
    )
