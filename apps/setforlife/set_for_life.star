"""
Applet: Set For Life
Summary: Set For Life results
Description: Results for the most recent draw of the UK national lottery's Set For Life game.
Author: dinosaursrarr
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

RESULTS_URL = "https://www.national-lottery.co.uk/results/set-for-life/draw-history/xml"
TIMEZONE = "Europe/London"
MAX_RESPONSE_BYTES = 64 * 1024

WHITE = "#ffffff"
BLACK = "#000000"
TEAL = "#44c1d0"
MUSTARD = "#ffd400"

def fetch_latest_result():
    resp = http.get(RESULTS_URL, ttl_seconds = 3600)
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    result = xpath.loads(body)
    draw_date = result.query("//draw-date")
    balls = [result.query("//ball[%d]" % index) for index in range(1, 6)]
    life_ball = result.query("//bonus-ball")
    if type(draw_date) != "string" or len(draw_date) != 10 or not draw_date.replace("-", "").isdigit() or not all([ball and str(ball).isdigit() for ball in balls]) or not life_ball or not str(life_ball).isdigit():
        return None
    draw_date = time.parse_time(draw_date, "2006-01-02", TIMEZONE)
    balls = [int(ball) for ball in balls]
    life_ball = int(life_ball)
    return draw_date, balls, life_ball

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
    draw_date, balls, life_ball = result

    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    pad = (0, 1, 0, 0),
                    color = TEAL,
                    child = render.WrappedText(
                        content = "SET FOR LIFE",
                        width = 64,
                        align = "center",
                        color = BLACK,
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
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render_ball(ball, TEAL, BLACK)
                        for ball in balls
                    ] + [render_ball(life_ball, MUSTARD, BLACK)],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
