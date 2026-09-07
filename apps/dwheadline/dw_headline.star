"""
Applet: DW Headline
Summary: DailyWire Headlines
Description: Shows the latest published headline on DailyWire.com.
Author: bmdelaune
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DAILYWIRE_FEED_XML_URL = "https://www.dailywire.com/feeds/rss.xml"
MAX_RESPONSE_BYTES = 512 * 1024

def main():
    title = get_headline()

    return render.Root(
        child = render.Stack(
            children = [
                render.Marquee(
                    width = 64,
                    height = 32,
                    offset_start = 20,
                    offset_end = 20,
                    child = render.WrappedText(
                        content = title,
                        width = 60,
                    ),
                    scroll_direction = "vertical",
                ),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    cross_align = "end",
                    children = [
                        render.Box(height = 10, width = 65),
                        render.Stack(
                            children = [
                                render.Box(height = 10, width = 14, color = "#C83740"),
                                render.Padding(pad = 1, child = render.Box(height = 8, width = 12, color = "#000000")),
                                render.Padding(
                                    pad = 2,
                                    child = render.Text(
                                        content = "DW",
                                        height = 7,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_headline():
    resp = http.get(DAILYWIRE_FEED_XML_URL, ttl_seconds = 600)
    body = resp.body()
    if resp.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES:
        titles = html(body).find("item title")
        if titles.len() > 0:
            title = titles.first().text().strip()
            if title:
                return title[:300]
    return "!! Error"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
