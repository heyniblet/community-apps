load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

API_URL = "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=fredscanner.bsky.social&limit=1&filter=posts_no_replies"
MAX_RESPONSE_BYTES = 256 * 1024

def main():
    rep = http.get(API_URL, ttl_seconds = 60)
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    feed = data.get("feed") if type(data) == "dict" else None
    post = feed[0].get("post") if type(feed) == "list" and feed and type(feed[0]) == "dict" else None
    record = post.get("record") if type(post) == "dict" else None
    alert = record.get("text") if type(record) == "dict" else None
    if type(alert) != "string" or not alert.strip():
        alert = "No current alert"
    alert = " ".join(alert.split())[:500]

    return render.Root(
        delay = 25,
        child = render.Column(
            children = [
                render.Text("  FredScanner", color = "#00FFFF"),
                render.Text("  Latest Alert", color = "#cc0000"),
                render.Text("-------------------", color = "#3944BC"),
                render.Marquee(
                    width = 64,
                    child = render.Text(alert, color = "#FFFFFF"),
                ),
            ],
        ),
    )
