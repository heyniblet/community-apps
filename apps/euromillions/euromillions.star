"""
Applet: EuroMillions
Summary: EuroMillions results
Description: Results for the most recent draw of the EuroMillions transnational lottery.
Author: dinosaursrarr
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

RESULTS_URL = "https://www.national-lottery.co.uk/results/euromillions/draw-history/xml"
TIMEZONE = "Europe/Paris"
MAX_RESPONSE_BYTES = 64 * 1024

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#f00000"
YELLOW = "#fff100"

def fetch_latest_result():
    resp = http.get(RESULTS_URL, ttl_seconds = 3600)
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    result = xpath.loads(body)
    draw_date = result.query("/draw-results/game/draw/draw-date")
    balls = result.query_all("/draw-results/game/balls[1]/ball")
    lucky_stars = result.query_all("/draw-results/game/balls[1]/bonus-ball")
    millionaire_maker_codes = result.query_all("/draw-results/game/raffles/raffle")[:20]
    if not valid_date(draw_date) or len(balls) != 5 or len(lucky_stars) != 2:
        return None
    if not all([valid_number(ball) for ball in balls + lucky_stars]):
        return None
    millionaire_maker_codes = [code for code in millionaire_maker_codes if valid_code(code)]
    draw_date = time.parse_time(draw_date, "2006-01-02", TIMEZONE)
    balls = [int(ball) for ball in balls]
    lucky_stars = [int(ball) for ball in lucky_stars]
    return draw_date, balls, lucky_stars, millionaire_maker_codes

def valid_number(value):
    return type(value) == "string" and value and len(value) <= 2 and value.isdigit()

def valid_date(value):
    return type(value) == "string" and len(value) == 10 and value[4] == "-" and value[7] == "-" and value.replace("-", "").isdigit()

def valid_code(value):
    return type(value) == "string" and value and len(value) <= 64 and value.replace(" ", "").isalnum()

def render_ball(number, ball_colour, text_colour):
    return render.Circle(
        color = ball_colour,
        diameter = 9,
        child = render.Text(
            str(number),
            color = text_colour,
            font = "tom-thumb",
        ),
    )

def main():
    result = fetch_latest_result()
    if not result:
        return render.Root(render.Text("Cannot load results"))
    draw_date, balls, lucky_stars, millionaire_maker_codes = result

    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    pad = (0, 1, 0, 0),
                    color = YELLOW,
                    child = render.WrappedText(
                        content = "EUROMILLIONS",
                        width = 64,
                        align = "center",
                        color = BLACK,
                        font = "tom-thumb",
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 0, 1),
                    child = render.WrappedText(
                        content = humanize.time_format("EEE d MMM yyyy", draw_date),
                        width = 64,
                        align = "center",
                        color = WHITE,
                        font = "tom-thumb",
                    ),
                ),
                render.Row(
                    children = [
                        render_ball(ball, RED, WHITE)
                        for ball in balls
                    ] + [
                        render_ball(ball, YELLOW, BLACK)
                        for ball in lucky_stars
                    ],
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(
                            content = " ".join([c for c in millionaire_maker_codes if c]),
                            font = "tom-thumb",
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
