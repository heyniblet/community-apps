"""
Applet: Fortnite Store
Summary: Preview the Fortnite store
Description: See items currently featured in the Fortnite store.
Author: naomi-nori
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/default_item.png", DEFAULT_ITEM_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

color_key = {
    "handmade": "#fff",
    "uncommon": "#31923b",
    "rare": "#4e51f4",
    "epic": "#9c4cb9",
    "legendary": "#f1af2c",
    "mythic": "#fcd03e",
    "exotic": "#0abfd0",
    "transcendent": "#da505d",
}

def main(config):
    api_key = config.get("api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return render.Root(child = render.WrappedText("Add API key", color = "#ff6666"))

    items_resp = http.get(
        "https://prod.api-fortnite.com/api/v1/shop",
        headers = {"x-api-key": api_key},
        params = {"lang": "en"},
    )
    if items_resp.status_code != 200 or len(items_resp.body()) > 2 * 1024 * 1024:
        return render.Root(child = render.WrappedText("Shop unavailable", color = "#ff6666"))

    payload = json.decode(items_resp.body(), {})
    storefronts = payload.get("storefronts", []) if type(payload) == "dict" else []
    items = []
    if type(storefronts) == "list":
        for storefront in storefronts[:50]:
            entries = storefront.get("catalogEntries", []) if type(storefront) == "dict" else []
            if type(entries) != "list":
                continue
            for entry in entries[:500]:
                item = normalize_item(entry)
                if item:
                    items.append(item)
                if len(items) >= 1000:
                    break
            if len(items) >= 1000:
                break

    if not items:
        return render.Root(child = render.WrappedText("No shop items", color = "#ffcc66"))

    picked_item = items[random.number(0, len(items) - 1)]

    color = color_key.get(picked_item["rarity"].lower())
    if color == None:
        color = "#fff"

    image = picked_item["image"]

    return render.Root(
        render.Stack(
            children = [
                render.Column(
                    main_align = "end",
                    children = [render.Image(src = image, height = 32)],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 32,
                    offset_end = 32,
                    align = "end",
                    child = render.Padding(
                        pad = (0, 2, 2, 0),
                        child = render.Text(
                            content = picked_item["name"],
                            color = color,
                        ),
                    ),
                ),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    children = [
                        render.Padding(
                            pad = (0, 0, 2, 2),
                            child = render.Row(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Text(content = "V", color = "#34c0eb"),
                                    render.Text(content = str(picked_item["vBucks"])),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def normalize_item(entry):
    if type(entry) != "dict":
        return None
    grants = entry.get("itemGrants", [])
    cosmetic = grants[0].get("cosmetic", {}) if type(grants) == "list" and grants and type(grants[0]) == "dict" else {}
    prices = entry.get("prices", [])
    price = prices[0].get("finalPrice", 0) if type(prices) == "list" and prices and type(prices[0]) == "dict" else 0
    name = cosmetic.get("displayName") or cosmetic.get("name") or entry.get("title")
    rarity = cosmetic.get("rarity", "handmade")
    if type(name) != "string" or not name or type(rarity) != "string" or type(price) not in ["int", "float"] or price < 0:
        return None
    return {
        "vBucks": min(int(price), 1000000),
        "rarity": rarity[:32],
        "name": name[:120],
        "image": DEFAULT_ITEM_IMAGE_ASSET.readall(),
    }

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your api-fortnite.com API key.",
                icon = "key",
                secret = True,
            ),
        ],
    )
