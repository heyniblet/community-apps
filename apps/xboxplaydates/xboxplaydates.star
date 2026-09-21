# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: XboxPlaydates
Summary: Quotes from Xbox Playdates
Description: Displays quotes from the Xbox Playdates Teams.  You can find out more about Xbox Playdates at XboxPlaydates.org .
Author: PalmettoBling
"""

load("http.star", "http")
load("render.star", "render")

DEFAULT_WHO = "world"
QUOTEURL = "https://www.drivebird.com/api/quotes/today"

def main():
    rep = http.get(QUOTEURL, ttl_seconds = 3600)
    if rep.status_code != 200:
        fail("Something happened trying to get the quote. %d", rep.status_code)

    payload = rep.json().get("data", {})
    quoteId = payload["id"]
    quote = payload["quote"]
    attribution = payload.get("author") or "Xbox Playdates"

    return render.Root(
        child = render.Column(
            expanded = False,
            children = [
                render.Text(
                    content = ("# %s: " % quoteId),
                    color = "#099",
                ),
                render.Marquee(
                    width = 64,
                    height = 12,
                    offset_start = 16,
                    child = render.WrappedText(
                        height = 16,
                        linespacing = -1,
                        content = ("%s" % quote),
                    ),
                ),
                render.Marquee(
                    width = 64,
                    offset_end = 0,
                    child = render.Text(
                        color = "#0a0",
                        content = ("-%s" % attribution),
                    ),
                ),
            ],
        ),
    )
