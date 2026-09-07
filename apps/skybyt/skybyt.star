"""
Applet: Skybyt
Summary: Bluesky follower count
Description: Displays a Bluesky user's follower count.
Author: Alex Karp
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/bluesky_icon.png", BLUESKY_ICON_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

BLUESKY_ICON = BLUESKY_ICON_ASSET.readall()

def main(config):
    handle = config.get("handle", "autistic.af")

    if handle.startswith("@"):
        handle = handle[len("@"):]
    message = "@%s" % handle
    if type(handle) != "string" or not re.match(r"^[A-Za-z0-9.-]{1,253}$", handle):
        formatted_followers_count = "Not Found"
        message = "Check your handle."
    else:
        followers_count = get_followers_count(handle)

        if followers_count == None:
            formatted_followers_count = "Not Found"
            message = "Check your handle. (%s)" % handle
        else:
            formatted_followers_count = "%s %s" % (humanize.comma(followers_count), humanize.plural_word(followers_count, "follower"))

    handle_child = render.Text(
        color = "#3c3c3c",
        content = message,
    )

    if len(message) > 12:
        handle_child = render.Marquee(
            width = 64,
            child = handle_child,
        )

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(BLUESKY_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    handle_child,
                ],
            ),
        ),
    )

def get_followers_count(handle):
    response = http.get(
        "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile",
        params = {"actor": handle},
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/activity+json",
        },
        ttl_seconds = 240,
    )

    if response.status_code == 200:
        raw = response.body()
        body = json.decode(raw, {}) if raw and len(raw) <= 64 * 1024 else {}
        count = body.get("followersCount") if type(body) == "dict" else None
        if type(count) == "int" and count >= 0:
            return count
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "handle",
                name = "Handle",
                desc = "Bluesky handle for which to display follower count.",
                icon = "user",
            ),
        ],
    )
