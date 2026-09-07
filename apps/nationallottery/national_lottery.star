"""
Applet: National Lottery
Summary: UK National Lottery results
Description: Results for the most recent draw of the UK national lottery main game.
Author: dinosaursrarr
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

RESULTS_URL = "https://www.national-lottery.co.uk/results/lotto/draw-history/csv"
TIMEZONE = "Europe/London"

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#f00000"
YELLOW = "#fff100"

def parse_time(time_str):
    return time.parse_time(time_str, "2006-01-02", TIMEZONE)

def fetch_latest_result():
    resp = http.get(RESULTS_URL, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None
    results = xpath.loads(resp.body())
    draw_date = results.query("/draw-results/game/draw/draw-date")
    balls = results.query_all("/draw-results/game/balls[1]/ball")
    bonus_ball = results.query("/draw-results/game/balls[1]/bonus-ball")
    if not valid_date(draw_date) or len(balls) != 6 or not valid_number(bonus_ball):
        return None
    if len([ball for ball in balls if not valid_number(ball)]) > 0:
        return None
    return [draw_date, balls, bonus_ball]

def parse_result(result):
    draw_date = parse_time(result[0])
    balls = [int(ball) for ball in result[1]]
    bonus_ball = int(result[2])
    return draw_date, balls, bonus_ball

def valid_number(value):
    return type(value) == "string" and value != "" and len([char for char in value.elems() if char not in "0123456789"]) == 0

def valid_date(value):
    if type(value) != "string" or len(value) != 10 or value[4] != "-" or value[7] != "-":
        return False
    return valid_number(value[:4]) and valid_number(value[5:7]) and valid_number(value[8:])

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
    latest_result = fetch_latest_result()
    if not latest_result:
        return render.Root(render.Text("Cannot load results"))
    draw_date, balls, bonus_ball = parse_result(latest_result)

    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    pad = (0, 1, 0, 0),
                    color = RED,
                    child = render.WrappedText(
                        content = "LOTTO",
                        width = 64,
                        align = "center",
                        color = WHITE,
                        font = "tom-thumb",
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 0, 4),
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
                    ] + [render_ball(bonus_ball, YELLOW, BLACK)],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
