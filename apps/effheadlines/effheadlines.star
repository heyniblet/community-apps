"""
Applet: EFF Headlines
Author: hainish
Summary: EFF Headlines tidbyt
Description: Get the latest headlines from the Electronic Frontier Foundation.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("random.star", "random")
load("render.star", "render")
load("xpath.star", "xpath")

EFF_XML_URL = "https://www.eff.org/rss/updates.xml"

def main():
    rep = http.get(EFF_XML_URL, ttl_seconds = 3600)
    if rep.status_code != 200:
        fail("EFF XML request failed with status %d", rep.status_code)

    rss = xpath.loads(rep.body())
    titles = rss.query_all("/rss/channel/item/title")
    guids = rss.query_all("/rss/channel/item/guid")
    count = len(titles)
    if len(guids) < count:
        count = len(guids)
    if count > 10:
        count = 10
    if count == 0:
        fail("EFF RSS feed contained no articles")

    index = random.number(0, count - 1)
    node_id = guids[index].split(" at ")[0]
    url = "https://eff.org/node/" + node_id
    headline = titles[index]

    data = cache.get(url)
    if data == None:
        code = qrcode.generate(
            url = url,
            size = "large",
            color = "#fff",
            background = "#000",
        )

        cache.set(url, base64.encode(code), ttl_seconds = 3600)
    else:
        code = base64.decode(data)

    return render.Root(
        child = render.Stack(children = [
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(
                        child = render.Image(src = code),
                        pad = 1,
                    ),
                    render.Marquee(
                        child = render.WrappedText(
                            content = headline,
                            color = "#aaf",
                            font = "tom-thumb",
                            width = 32,
                        ),
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 32,
                        offset_end = 32,
                    ),
                ],
            ),
            render.Row(main_align = "end", expanded = True, children = [
                render.Box(width = 13, height = 6, color = "#000"),
            ]),
            render.Row(main_align = "end", expanded = True, children = [
                render.Text(content = "EFF", color = "#a00", font = "tom-thumb"),
            ]),
        ]),
    )
