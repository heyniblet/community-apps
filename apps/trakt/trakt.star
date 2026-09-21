# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Trakt
Summary: Trakt info on your display
Description: Shows Trakt trending titles or personal watching activity with user-owned API credentials.
Author: cbattlegear
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://api.trakt.tv"
MAX_RESPONSE_BYTES = 512 * 1024

def main(config):
    client_id = (config.str("client_id") or "").strip()
    if not client_id:
        return message("Add your Trakt client ID")
    token = config.str("auth") or ""
    count = int(config.str("recent_items", "1"))
    media = personal_media(client_id, token, count) if token else trending_media(client_id, count)
    if not media:
        return message("Trakt data unavailable")
    return render.Root(child = render.Sequence(children = [media_card(item) for item in media]))

def request(path, client_id, token = ""):
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "trakt-api-key": client_id,
        "trakt-api-version": "2",
    }
    if token:
        headers["Authorization"] = "Bearer " + token
    response = http.get(API + path, headers = headers, ttl_seconds = 600)
    if response.status_code not in [200, 204] or len(response.body()) > MAX_RESPONSE_BYTES:
        return None
    return [] if response.status_code == 204 else response.json()

def personal_media(client_id, token, count):
    watching = request("/users/me/watching", client_id, token)
    if type(watching) == "dict":
        watching["label"] = "WATCHING"
        return [watching]
    history = request("/users/me/history?limit=%d" % count, client_id, token)
    if type(history) != "list":
        return []
    for item in history[:count]:
        item["label"] = "WATCHED"
    return history[:count]

def trending_media(client_id, count):
    kind = "shows" if time.now().minute < 30 else "movies"
    items = request("/%s/trending?limit=%d" % (kind, count), client_id)
    if type(items) != "list":
        return []
    for item in items[:count]:
        item["label"] = "TRENDING"
    return items[:count]

def media_card(item):
    media = item.get("movie") or item.get("show") or {}
    title = str(media.get("title") or "Unknown title")[:100]
    detail = str(item.get("watchers") or media.get("year") or "")
    return render.Column(
        children = [
            render.Text(item.get("label", "TRAKT"), font = "tom-thumb", color = "#ed1c24"),
            render.Marquee(child = render.Text(title, font = "tb-8"), width = 64, align = "center"),
            render.Text(detail, font = "tom-thumb", color = "#aaaaaa"),
        ],
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
    )

def message(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#ed1c24"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "client_id", name = "Trakt client ID", desc = "Create an API application in Trakt and paste its client ID.", icon = "key"),
            schema.Text(id = "auth", name = "Trakt access token", desc = "Optional access token for your personal watching activity; omit for trending titles.", icon = "lock", secret = True),
            schema.Dropdown(
                id = "recent_items",
                name = "Items",
                desc = "Number of titles to rotate.",
                icon = "listOl",
                default = "1",
                options = [schema.Option(display = str(value), value = str(value)) for value in [1, 2, 3]],
            ),
        ],
    )
