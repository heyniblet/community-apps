"""
Applet: Spanish WoD
Summary: Word of the day in Spanish
Description: Displays the spanish word of the day including definition and translation.
Author: logancornelius
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")

CACHE_TTL = 3600  # 1 hour
SPANISH_DICT_WOTD_URL = "https://www.spanishdict.com/wordoftheday"
MAX_RESPONSE_BYTES = 512 * 1024

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def fetch_word_of_the_day():
    wotd_resp = http.get(SPANISH_DICT_WOTD_URL, ttl_seconds = CACHE_TTL)

    if wotd_resp.status_code != 200:
        return False

    resp_body = wotd_resp.body()
    if not resp_body or len(resp_body) > MAX_RESPONSE_BYTES:
        return False

    pattern = r"window\.SD_COMPONENT_DATA\s*=(.*);"
    matches = re.findall(pattern, resp_body)

    if len(matches) == 0:
        return False

    match = matches[0]

    data = match.replace("window.SD_COMPONENT_DATA = ", "").replace(";", "")
    parsed_data = json.decode(data, {})
    wotd = parsed_data.get("wordOfTheDayData", {}) if type(parsed_data) == "dict" else {}
    word = wotd.get("wordDisplay") if type(wotd) == "dict" else None
    definition = wotd.get("translationText") if type(wotd) == "dict" else None
    if type(word) != "string" or type(definition) != "string" or not word or not definition:
        return False

    return {
        "word": word[:80],
        "definition": definition[:1000],
    }

def main():
    wotd_dict = fetch_word_of_the_day()

    if not wotd_dict:
        return render_error()

    word = wotd_dict["word"]
    definition = wotd_dict["definition"]

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word + ":",
                                color = "#00eeff",
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
                    color = "#fa0",
                ),
                render.Text(
                    content = "Palabra del Dia",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )
