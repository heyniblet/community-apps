# Modified in this community-maintained version; see Git history for contributors.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: No Laying Up
Summary: Lists NLU content
Description: No Laying Up produces golf and golf adjacent media content. This app displays the last 6 items posted to the No Laying Up RSS feed. Orange for NLU podcasts, green for Trap Draw podcasts, blue for Nest podcasts, yellow for blogs and red for video content. 
Author: M0ntyP

Very niche app for the true NLU sickos out there

v1.1
Updated to reflect change in titles in RSS feed

v1.2
Distinguish Nest podcast episodes from the other podcasts with blue color
Changed blog color to yellow

v1.2.1
Changed Nest color to lighter blue, previous color was too dark
Stripped "Episode" from the title of Nest pods to align with other pod title format, "<Episode Number>: <Title>"
Updated app description to reflect new colors
"""

load("http.star", "http")
load("render.star", "render")
load("xpath.star", "xpath")

RSS_FEED = "https://nolayingup.com/feeds/all.xml"

def main():
    # Update feed every hour
    feed = get_cachable_data(RSS_FEED, 3600)
    rss = xpath.loads(feed)

    channel = rss.query_all("//rss/channel/item/title")
    link = rss.query_all("//rss/channel/item/link")
    description = []
    content_type = []
    pod_type = []
    item_count = min(6, len(channel), len(link))
    if item_count == 0:
        return render.Root(child = render.Text("NLU feed unavailable", font = "tom-thumb"))

    for i in range(0, item_count, 1):
        desc = channel[i]
        article_link = link[i]
        if "/trap-draw" in article_link:
            nlu_podcast = "Trap"
        elif "/nest-podcast" in article_link:
            nlu_podcast = "Nest"
            if desc.startswith("Episode "):
                desc = desc[8:]
        else:
            nlu_podcast = "NLU"
        content = "pod" if "/podcast" in article_link else "vid" if "/video" in article_link else "blo"

        description.append(desc)
        content_type.append(content)
        pod_type.append(nlu_podcast)

    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    padding = 0,
                    color = "#000",
                    child = render.Text("NO LAYING UP", color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = articles(description, content_type, pod_type),
                        ),
                ),
            ],
        ),
    )

def articles(description, content_type, pod_type):
    articles = []
    content_color = "#000"

    for i in range(0, len(description), 1):
        if content_type[i] == "pod":
            if pod_type[i] == "NLU":
                content_color = "#eb9b34"
            elif pod_type[i] == "Trap":
                content_color = "#019b5b"
            else:
                content_color = "#88ccff"
        elif content_type[i] == "vid":
            content_color = "#eb3449"
        elif content_type[i] == "blo":
            content_color = "#ebe534"

        articles.append(render.WrappedText(content = description[i], color = content_color, font = "CG-pixel-3x5-mono", linespacing = 1))
        articles.append(render.Box(width = 64, height = 3, color = "#000"))

    return articles

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("No Laying Up feed failed with status code: %d" % res.status_code)

    body = res.body()
    if not body or len(body) > 512000:
        fail("No Laying Up feed returned an invalid body")
    return body
