"""
Applet: Positive Quote
Summary: Display a positive quote
Description: Shows the user a random positive quote.
Author: Brian Bell
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

TTL_SECONDS = 300
MAX_RESPONSE_BYTES = 4096
FALLBACK_AFFIRMATION = "You can take the next step."

def main():
    affirmation = get_affirmation()

    return render.Root(
        delay = 150,
        child = render.Box(
            width = 64,
            height = 32,
            color = "#18243A",
            child = render.Padding(
                pad = 2,
                child = render.Box(
                    color = "#00000066",
                    child = render.Padding(
                        pad = (2, 1, 2, 1),
                        child = render.Marquee(
                            align = "center",
                            height = 26,
                            offset_start = 0,
                            offset_end = -11,
                            scroll_direction = "vertical",
                            child = render.WrappedText(content = affirmation, font = "tom-thumb"),
                        ),
                    ),
                ),
            ),
        ),
    )

def get_affirmation():
    response = http.get("https://www.affirmations.dev", ttl_seconds = TTL_SECONDS)
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES or not body.startswith("{") or not body.endswith("}"):
        return FALLBACK_AFFIRMATION
    data = json.decode(body, None)
    affirmation = data.get("affirmation") if type(data) == "dict" else None
    if type(affirmation) != "string" or not affirmation.strip():
        return FALLBACK_AFFIRMATION
    return affirmation.strip()[:240]
