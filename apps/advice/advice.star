"""
Applet: Advice
Summary: Random advice API
Description: Shows random advice from AdviceSlip.com.
Author: mrrobot245
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ADVICE_URL = "https://api.adviceslip.com/advice"
SCROLL_SPEEDS = ["200", "150", "100", "60", "30"]
MAX_RESPONSE_BYTES = 16 * 1024
MAX_ADVICE_LENGTH = 500

def main(config):
    scroll_speed = config.str("scroll_speed", "100")
    if scroll_speed not in SCROLL_SPEEDS:
        scroll_speed = "100"

    rep = http.get(ADVICE_URL, ttl_seconds = 300)
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES else {}
    slip = data.get("slip") if type(data) == "dict" else None
    advice = slip.get("advice") if type(slip) == "dict" else None
    if type(advice) != "string" or not advice.strip():
        advice = "Advice is unavailable right now."

    return render.Root(
        delay = int(scroll_speed),
        child = render.Column(
            children = [
                render.Marquee(
                    offset_start = 32,
                    offset_end = 32,
                    width = 64,
                    height = 32,
                    scroll_direction = "vertical",
                    child =
                        render.Column(
                            children = [
                                render.Padding(
                                    render.WrappedText(
                                        content = advice[:MAX_ADVICE_LENGTH],
                                        width = 60,
                                        color = "#fff",
                                    ),
                                    pad = (3, 0, 3, 2),
                                ),
                            ],
                        ),
                ),
            ],
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Slower", value = "150"),
        schema.Option(display = "Normal (Default)", value = "100"),
        schema.Option(display = "Fast", value = "60"),
        schema.Option(display = "Faster", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "personRunning",
                default = scroll_speed[2].value,
                options = scroll_speed,
            ),
        ],
    )
