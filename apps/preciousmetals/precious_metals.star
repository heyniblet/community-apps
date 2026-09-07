"""
Applet: Precious Metals
Summary: Quotes on precious metals
Description: Quotes for gold, platinum and silver.
Author: threeio
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/image.png", IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE = IMAGE_ASSET.readall()

METALS_PRICE_URL = "https://api.gold-api.com/price/{}"
TTL_SECONDS = 300
MAX_RESPONSE_BYTES = 4096

def main():
    gold = get_price("XAU")
    silver = get_price("XAG")
    platinum = get_price("XPT")

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 14,
                        child = render.Image(src = IMAGE),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#FFD700", font = "tom-thumb", content = "Au %s" % gold),
                            render.Text(height = 10, color = "#C0C0C0", font = "tom-thumb", content = "Ag %s" % silver),
                            render.Text(height = 10, color = "#E5E4E2", font = "tom-thumb", content = "Pt %s" % platinum),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_price(symbol):
    rep = http.get(METALS_PRICE_URL.format(symbol), ttl_seconds = TTL_SECONDS)
    body = rep.body()
    if rep.status_code != 200 or len(body) > MAX_RESPONSE_BYTES or not body.startswith("{") or not body.endswith("}"):
        return "--"
    data = json.decode(body, None)
    price = data.get("price") if type(data) == "dict" and data.get("symbol") == symbol else None
    return humanize.float("#,###.##", price) if type(price) in ("int", "float") and price > 0 else "--"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
