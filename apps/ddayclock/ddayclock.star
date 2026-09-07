"""
Applet: DDayClock
Summary: Displays the current time of the Doomsday Clock
Description: Gets the current Doomsday Clock data from the Bulletin of the Atomic Scientists.
Author: LLarry
"""

load("html.star", "html")
load("http.star", h = "http")
load("render.star", r = "render")
load("schema.star", s = "schema")

#Constants
DDAYCLOCK_URL = "https://thebulletin.org/doomsday-clock/current-time/"

MAX_SECONDS = 3600
MAX_MINUTES = 60

DEFAULT_CLOCK_COLOR = "#fff"
DEFAULT_TEXT_COLOR = "#fff"
DEFAULT_TIME_COLOR = "#f00"

def config_color(value, fallback):
    return value if type(value) == "string" and len(value) in [4, 7] and value.startswith("#") and all([char in "0123456789abcdefABCDEF" for char in value[1:].codepoints()]) else fallback

def main(config):
    #Initializes all values
    degrees = -1
    clockColor = config_color(config.get("clockColor"), DEFAULT_CLOCK_COLOR)
    textColor = config_color(config.get("textColor"), DEFAULT_TEXT_COLOR)
    timeColor = config_color(config.get("timeColor"), DEFAULT_TIME_COLOR)
    clock_time = get_data(DDAYCLOCK_URL)
    if clock_time == None:
        return r.Root(child = r.WrappedText(content = "Clock unavailable", align = "center", color = textColor))
    number, unit = clock_time

    #One second is 0.1 degrees of a circle
    #One minute is 6 degrees of a circle
    if (unit.lower() == "seconds"):
        if number <= MAX_SECONDS:
            degrees = number * 0.1
    elif (unit.lower() == "minutes"):
        if number <= MAX_MINUTES:
            degrees = number * 6

    #Returns Degree Error
    #Happens if number isn't within acceptable bounds.
    if degrees == -1:
        return r.Root(
            child = r.Box(
                r.Text(
                    content = "Deg. Error",
                    font = "6x13",
                ),
            ),
        )
    else:
        #Sets the different secition colors and section degrees.
        #Needs at least three sections due to pie charts starting at the right and not the top.
        if degrees < 270:
            d1 = 270 - degrees
            c1 = "#000"
            d2 = degrees
            c2 = timeColor
            d3 = 90
            c3 = c1
        else:
            d1 = 270
            c1 = timeColor
            d2 = 90 - (degrees - 270)
            c2 = "#000"
            d3 = 90 - d2
            c3 = timeColor

        #Beginning graphical return
        return r.Root(
            r.Row(
                children = [
                    r.Column(
                        children = [
                            r.WrappedText(
                                align = "center",
                                content = "{} {} Until 12:00".format(number, unit[0:1]),
                                width = 32,
                                font = "tb-8",
                                color = textColor,
                            ),
                        ],
                        main_align = "center",
                        expanded = True,
                    ),
                    r.Column(
                        children = [
                            r.Column(
                                children = [
                                    r.Circle(
                                        color = clockColor,
                                        diameter = 24,
                                        child = r.PieChart(colors = [c1, c2, c3], weights = [d1, d2, d3], diameter = 24),
                                    ),
                                ],
                                main_align = "center",
                            ),
                        ],
                        main_align = "center",
                        expanded = True,
                    ),
                ],
                main_align = "center",
                expanded = True,
            ),
        )

def get_data(url):
    response = h.get(url, ttl_seconds = 43200)
    if response.status_code != 200 or len(response.body()) > 1024 * 1024:
        return None
    headings = html(response.body()).find("h2")
    for i in range(min(headings.len(), 50)):
        parts = headings.eq(i).text().strip().split()
        for j in range(0, len(parts) - 3):
            if not parts[j].isdigit() or parts[j + 1].lower() not in ["second", "seconds", "minute", "minutes"] or parts[j + 2].lower() != "to" or parts[j + 3].lower() != "midnight":
                continue
            number = int(parts[j])
            unit = parts[j + 1].lower()
            if unit.startswith("second") and number <= MAX_SECONDS:
                return (number, "seconds")
            if unit.startswith("minute") and number <= MAX_MINUTES:
                return (number, "minutes")
    return None

#Allows you to determine UI colors
def get_schema():
    return s.Schema(
        version = "1",
        fields = [
            s.Color(
                id = "timeColor",
                name = "Time Color",
                desc = "Color of the distance to midnight.",
                icon = "fire",
                default = DEFAULT_TIME_COLOR,
            ),
            s.Color(
                id = "clockColor",
                name = "Clock Color",
                desc = "Color of the clock border.",
                icon = "clock",
                default = DEFAULT_CLOCK_COLOR,
            ),
            s.Color(
                id = "textColor",
                name = "Text Color",
                desc = "Color of the display text.",
                icon = "font",
                default = DEFAULT_TEXT_COLOR,
            ),
        ],
    )
