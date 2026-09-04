load("http.star", "http")
load("images/pokt_icon.png", POKT_ICON_ASSET = "file")
load("render.star", "render")

POKT_ICON = POKT_ICON_ASSET.readall()

PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=pocket-network&vs_currencies=usd"

def main():
    rep = http.get(PRICE_URL, ttl_seconds = 7200)
    if rep.status_code != 200:
        fail("Price request failed with status %d", rep.status_code)
    price = rep.json().get("pocket-network", {}).get("usd", "0.00")

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
                            render.Text("$%s" % price),
                            render.Text("USD"),
                        ],
                    ),
                ],
            ),
        ),
    )
