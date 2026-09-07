"""
Applet: Nouns
Summary: Show current Noun auction
Description: Displays the Noun currently under auction and bid details.
Author: miracle2k
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")

AUCTION_HOUSE = "0x830BD73E4184ceF73443c15111a1DF14e495C706"
AUCTION_SELECTOR = "0x7d9f6db5"
ETHEREUM_RPC_URL = "https://ethereum-rpc.publicnode.com"

def main():
    screen = render_screen()
    return render.Root(child = screen)

def render_screen():
    rep = http.post(
        ETHEREUM_RPC_URL,
        body = json.encode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_call",
            "params": [{"to": AUCTION_HOUSE, "data": AUCTION_SELECTOR}, "latest"],
        }),
        headers = {
            "content-type": "application/json",
        },
        ttl_seconds = 60,
    )
    if rep.status_code != 200:
        return render.WrappedText("API Error: %d" % rep.status_code, color = "#ff0000")
    body = rep.body()
    if not body or len(body) > 65536:
        return render.WrappedText("Auction unavailable", color = "#ff0000")
    payload = json.decode(body)
    result = payload.get("result", "") if type(payload) == "dict" else ""
    if type(result) != "string" or not result.startswith("0x") or len(result) < 386:
        return render.WrappedText("Auction unavailable", color = "#ff0000")

    noun_id = int(result[2:66], 16)
    amount = int(result[66:130], 16)
    end_time = int(result[194:258], 16)

    img_rep = http.get("https://images.weserv.nl/?url=noun.pics/{}.jpg&w=32&h=32&fit=cover".format(noun_id), ttl_seconds = 3600 * 6)
    img_data = img_rep.body() if img_rep.status_code == 200 else None
    img = render.Image(src = img_data, width = 32) if img_data and len(img_data) <= 2000000 else render.Box(width = 32, height = 32)

    ether = amount / 1000000000000000000

    time_text = humanize.relative_time(time.now(), time.from_timestamp(end_time))
    time_text = time_text.replace(" hours", "h")
    time_text = time_text.replace(" hour", "h")
    time_text = time_text.replace(" minutes", "m")
    time_text = time_text.replace(" minute", "m")
    time_text = time_text.replace(" seconds", "s")
    time_text = time_text.replace(" second", "s")

    # render two columns
    return render.Row(
        expanded = True,
        children = [
            img,
            render.Box(
                color = "#000000",
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    #main_align="space_around",
                    main_align = "space_evenly",
                    children = [
                        # Without this box, the text centering
                        # of the middle row depends on the length
                        # of the last row...
                        render.Box(
                            height = 6,
                            child = render.Text("{}".format(noun_id), font = "tom-thumb", color = "#ffffff"),
                        ),
                        render.Row(
                            children = [
                                render.Text("Ξ", font = "5x8", color = "#ffffffcc"),
                                render.Text("{}".format(humanize.comma(ether)), font = "tb-8", color = "#ffffff"),
                            ],
                        ),
                        render.Text("{}".format(time_text), font = "tom-thumb", color = "#ffffff77"),
                    ],
                ),
            ),
        ],
    )
