load("http.star", "http")
load("render.star", "render")

API_URL = "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=fredscanner.bsky.social&limit=1&filter=posts_no_replies"

def main():
    rep = http.get(API_URL)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    config = {}
    data = rep.json()
    tweet = data["feed"][0]["post"]["record"]["text"]

    return render.Root(
        delay = int(config.get("scroll", 25)),
        child = render.Column(
            children = [
                render.Text("  FredScanner", color = "#00FFFF"),
                render.Text("  Latest Alert", color = "#cc0000"),
                render.Text("-------------------", color = "#3944BC"),
                render.Marquee(
                    width = 64,
                    child = render.Text("%s" % tweet, color = "#FFFFFF"),
                ),
            ],
        ),
    )
