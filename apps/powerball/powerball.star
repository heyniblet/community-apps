"""
Applet: PowerBall
Summary: Shows Powerball Numbers
Description: Shows up to date powerball numbers and next drawing.
Author: AmillionAir
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

NUMBERS_URL = "https://data.ny.gov/resource/d6yy-54nr.json?$limit=1&$order=draw_date%20DESC"
TTL_SECONDS = 3600
MAX_RESPONSE_BYTES = 8192

def main():
    draw = get_latest_draw()
    if not draw:
        return render_message("Powerball results unavailable")
    PB_NUMS = draw["winning_numbers"].split(" ")
    Draw_Date = draw["draw_date"][5:10].replace("-", "/")
    Jackpot = "POWERBALL"
    Won = "Power Play x%s" % draw.get("multiplier", "-")

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(Jackpot + "      ", font = "tb-8"),
                    offset_start = 5,
                    offset_end = 5,
                ),
                render.Stack(
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 2, height = 10),
                                render.Circle(color = "#FFF", diameter = 10),
                                render.Circle(color = "#FFF", diameter = 10),
                                render.Circle(color = "#FFF", diameter = 10),
                                render.Circle(color = "#FFF", diameter = 10),
                                render.Circle(color = "#FFF", diameter = 10),
                                render.Circle(color = "#F00", diameter = 10),
                            ],
                        ),
                        render.Column(
                            children = [
                                render.Box(width = 64, height = 2),
                                render.Row(
                                    children = [
                                        render.Box(width = 3, height = 4),
                                        render.Text(content = PB_NUMS[0], color = "#000", font = "tom-thumb"),
                                        render.Box(width = 2, height = 4),
                                        render.Text(content = PB_NUMS[1], color = "#000", font = "tom-thumb"),
                                        render.Box(width = 2, height = 4),
                                        render.Text(content = PB_NUMS[2], color = "#000", font = "tom-thumb"),
                                        render.Box(width = 2, height = 4),
                                        render.Text(content = PB_NUMS[3], color = "#000", font = "tom-thumb"),
                                        render.Box(width = 2, height = 4),
                                        render.Text(content = PB_NUMS[4], color = "#000", font = "tom-thumb"),
                                        render.Box(width = 2, height = 4),
                                        render.Text(content = PB_NUMS[5], color = "#000", font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 1, color = "#0a0"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 1, height = 20),
                        render.Column(
                            children = [
                                render.Text(Draw_Date, font = "tom-thumb"),
                                render.Box(width = 20, height = 1),
                                render.Text("RESULT", font = "tom-thumb"),
                            ],
                        ),
                        render.Box(width = 2, height = 20),
                        render.Column(
                            children = [
                                render.Text(Won, font = "tom-thumb"),
                                render.Box(width = 38, height = 1),
                                render.Text("Latest Draw", font = "tom-thumb"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_latest_draw():
    response = http.get(NUMBERS_URL, ttl_seconds = TTL_SECONDS)
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES or not body.startswith("[") or not body.endswith("]"):
        return None
    rows = json.decode(body, None)
    if type(rows) != "list" or len(rows) != 1 or type(rows[0]) != "dict":
        return None
    draw = rows[0]
    numbers = draw.get("winning_numbers", "").split(" ")
    if len(numbers) != 6 or type(draw.get("draw_date")) != "string" or len(draw["draw_date"]) < 10:
        return None
    for number in numbers:
        if len(number) != 2 or not number.isdigit():
            return None
    return draw

def render_message(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("POWERBALL", font = "tb-8"),
                render.WrappedText(message, align = "center"),
            ],
        ),
    )
