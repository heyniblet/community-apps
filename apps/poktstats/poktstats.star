load("encoding/json.star", "json")
load("http.star", "http")
load("images/pokt_icon.png", POKT_ICON_ASSET = "file")
load("render.star", "render")

POKT_ICON = POKT_ICON_ASSET.readall()

PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=pocket-network&vs_currencies=usd"
TTL_SECONDS = 300
MAX_RESPONSE_BYTES = 4096

def main():
    rep = http.get(PRICE_URL, ttl_seconds = TTL_SECONDS)
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES and body.startswith("{") and body.endswith("}") else {}
    price = data.get("pocket-network", {}).get("usd") if type(data) == "dict" else None
    price_text = "$%s" % price if type(price) in ("int", "float") else "Unavailable"

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Padding(
                        # Pad a LR border around the POKT logo
                        pad = (5, 0, 5, 0),
                        child = render.Image(src = POKT_ICON),
                    ),
                    render.Column(
                        # Arrange price above height beside the logo
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "start",  # Controls vertical alignment
                        children = [
                            render.Text(content = "POKT", font = "Dina_r400-6"),
                            render.Text(price_text),
                            render.Text("USD"),
                        ],
                    ),
                ],
            ),
        ),
    )
