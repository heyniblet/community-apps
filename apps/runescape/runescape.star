"""
Applet: OS Runescape Grand Exchange
Summary: Shows item information from OSRS's Grand Exchange
Description: Shows item information from Runescape using the Runescape API.
Author: blakekwehrle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/down_carrot_icon.gif", DOWN_CARROT_ICON_ASSET = "file")
load("images/line_icon.gif", LINE_ICON_ASSET = "file")
load("images/up_carrot_icon.gif", UP_CARROT_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")

DOWN_CARROT_ICON = DOWN_CARROT_ICON_ASSET.readall()
LINE_ICON = LINE_ICON_ASSET.readall()
UP_CARROT_ICON = UP_CARROT_ICON_ASSET.readall()

CACHE_TTL_SECONDS = 3600
MAX_JSON_BYTES = 64 * 1024
MAX_IMAGE_BYTES = 256 * 1024
IMAGE_PREFIX = "https://secure.runescape.com/"
RUNESCAPEAPI_ITEMLIST_URL = "https://secure.runescape.com/m=itemdb_oldschool/api/catalogue/items.json?category=1&alpha={0}&page={1}"
PAGE_LENGTH_BY_LETTER = {
    "a": 30,
    "b": 40,
    "c": 16,
    "d": 20,
    "e": 11,
    "f": 8,
    "g": 18,
    "h": 5,
    "i": 10,
    "j": 4,
    "k": 4,
    "l": 7,
    "m": 25,
    "n": 3,
    "o": 9,
    "p": 13,
    "r": 25,
    "s": 44,
    "t": 22,
    "u": 5,
    "v": 5,
    "w": 11,
    "x": 1,
    "y": 3,
    "z": 5,
}

def main():
    random_letter = pick_letter()
    item_list = get_item_list(random_letter)
    if type(item_list) != "dict" or type(item_list.get("items")) != "list" or len(item_list["items"]) == 0:
        return render.Root(child = render.WrappedText("Exchange unavailable", width = 64, align = "center"))
    number_of_items = len(item_list["items"])
    random_item_index = random.number(0, number_of_items - 1)
    item = item_list["items"][random_item_index]
    if type(item) != "dict":
        return render.Root(child = render.WrappedText("Exchange unavailable", width = 64, align = "center"))
    item_name = str(item.get("name", "Unknown item"))[:80]
    today = item.get("today", {})
    current = item.get("current", {})
    item_trend = today.get("trend", "neutral") if type(today) == "dict" else "neutral"
    item_price = str(current.get("price", "?"))[:20] + " gp" if type(current) == "dict" else "? gp"
    sprite_url = item.get("icon", "")
    sprite = get_cachable_data(sprite_url, ttl_seconds = 2592000, max_bytes = MAX_IMAGE_BYTES) if type(sprite_url) == "string" and sprite_url.startswith(IMAGE_PREFIX) else None
    if (item_trend == "positive"):
        selected_image = UP_CARROT_ICON
    elif (item_trend == "negative"):
        selected_image = DOWN_CARROT_ICON
    else:
        selected_image = LINE_ICON
    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 32),
                        render.Box(render.Image(sprite)) if sprite else render.Box(width = 32),
                    ],
                ),
                render.Column(
                    children = [
                        render.WrappedText(
                            content = item_name,
                            width = 64,
                            font = "tom-thumb",
                        ),
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = selected_image),
                                render.WrappedText(
                                    content = item_price,
                                    width = 64,
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def pick_letter():
    page_total = 0
    for page_count in PAGE_LENGTH_BY_LETTER.values():
        page_total += page_count
    random_page_index = random.number(0, page_total - 1)
    pages_seen = 0
    for letter, page_count in PAGE_LENGTH_BY_LETTER.items():
        if random_page_index < pages_seen + page_count:
            return letter
        pages_seen += page_count
    return "a"

def get_item_list(letter):
    url = RUNESCAPEAPI_ITEMLIST_URL.format(letter, random.number(1, PAGE_LENGTH_BY_LETTER[letter]))
    data = get_cachable_data(url, max_bytes = MAX_JSON_BYTES)
    return json.decode(data, None) if data else None

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS, max_bytes = MAX_JSON_BYTES):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    body = res.body()
    return body if res.status_code == 200 and body and len(body) <= max_bytes else None
