"""
Applet: Word Of The Day
Summary: Shows the Word Of The Day
Description: Displays the Merriam-Webster Word Of The Day.
Author: greg-n
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL = 3600
WOTD_API_URL = "https://wordoftheday.freeapi.me/"
MAX_RESPONSE_BYTES = 32 * 1024

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def main():
    wotd_response = http.get(WOTD_API_URL, ttl_seconds = CACHE_TTL)
    body = wotd_response.body()
    if wotd_response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return render_error()

    data = json.decode(body, {})
    if type(data) != "dict":
        return render_error()
    word_parsed = data.get("word", "")
    definition_parsed = data.get("definition") or data.get("meaning", "")

    if type(word_parsed) != "string" or type(definition_parsed) != "string" or word_parsed == "" or definition_parsed == "":
        return render_error()
    word_parsed = word_parsed[:80]
    definition_parsed = definition_parsed[:1000]

    # Values begin with lower cased letters on the calendar note cards
    word = word_parsed[0].upper() + word_parsed[1:] + ":"
    definition = definition_parsed[0].upper() + definition_parsed[1:]
    if not definition.endswith("."):
        definition += "."

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word,
                                color = "#fa0",
                                font = "5x8",
                            ),
                            render.WrappedText(
                                content = definition,
                                font = "5x8",
                            ),
                        ],
                    ),
                    height = 25,
                    offset_start = 23,
                    scroll_direction = "vertical",
                ),
                render.Box(
                    height = 1,
                    color = "#00eeff",
                ),
                render.Text(
                    content = "Today's Word",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
