"""
Applet: RantinglyNews
Summary: Show news from Rantingly
Description: Show top news stories from Rantingly.com.
Author: @Mad-Chemist
"""

load("http.star", "http")
load("render.star", "render")
load("xpath.star", "xpath")

URL = "https://rantingly.com/feed/"
MAX_RESPONSE_BYTES = 128 * 1024

def main():
    rep = http.get(URL, ttl_seconds = 600)
    body = rep.body()
    if rep.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return message("News unavailable")
    titles = xpath.loads(body).query_all("//rss/channel/item/title")
    titles = [title[:240] for title in titles[:3] if type(title) == "string" and title]
    if len(titles) == 0:
        return message("News unavailable")

    children = []
    for index, title in enumerate(titles):
        if index > 0:
            children.append(render.Text("-------"))
        children.append(render.WrappedText(content = title, font = "tom-thumb"))

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 35,
            child = render.Column(
                children = children,
            ),
        ),
    )

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, align = "center")))
