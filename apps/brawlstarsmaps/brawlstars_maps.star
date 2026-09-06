"""
Applet: BrawlStars Maps
Summary: Current Brawl Stars maps
Description: Shows a random map from the current maps available in the game Brawl Stars Powered by Brawlify.
Author: Lucas Farah
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAPS_URL = "https://api.brawlapi.com/v1/maps"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024
MAX_MAPS = 2000

def render_error(message):
    return render.Root(child = render.WrappedText(content = message, width = 62, align = "center", color = "#ff6666"))

def fetch_image(url):
    if type(url) != "string" or not (url.startswith("https://cdn.brawlify.com/") or url.startswith("https://cdn-misc.brawlify.com/")):
        return None
    resp = http.get(url, ttl_seconds = 3600)
    body = resp.body()
    return body if resp.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else None

def main(_config):
    random.seed(time.now().unix // 3600)
    resp = http.get(MAPS_URL, ttl_seconds = 3600)
    body = resp.body()
    data = json.decode(body, None) if resp.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    raw_maps = data.get("list", []) if type(data) == "dict" else []
    maps = [item for item in raw_maps[:MAX_MAPS] if type(item) == "dict" and not item.get("disabled") and type(item.get("gameMode")) == "dict"]

    if len(maps) == 0:
        return render_error("No Brawl Stars maps found")

    num = random.number(0, len(maps) - 1)
    random_map = maps[num]
    map_info = str(random_map.get("name") or "Unknown map")[:80]
    map_image = fetch_image(random_map.get("imageUrl"))
    game_image = fetch_image(random_map["gameMode"].get("imageUrl"))
    if not map_image:
        return render_error("Map image unavailable")

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = map_image, width = 20, height = 40),
                    render.Column(
                        children = [
                            render.Image(src = game_image, width = 10, height = 10) if game_image else render.Box(width = 10, height = 10),
                            render.WrappedText(map_info),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
