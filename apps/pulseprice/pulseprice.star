"""
Applet: Pulse Price
Summary: Pulse Price
Description: Displays PLS, PLSX and INC prices on Pulsechain
Author: kmphua
Thanks: aschober, bretep, codeakk, Poseidon
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/inc_icon_sm.png", INC_ICON_SM_ASSET = "file")
load("images/pls_icon_sm.png", PLS_ICON_SM_ASSET = "file")
load("images/plsx_icon_sm.png", PLSX_ICON_SM_ASSET = "file")
load("render.star", "render")

INC_ICON_SM = INC_ICON_SM_ASSET.readall()
PLSX_ICON_SM = PLSX_ICON_SM_ASSET.readall()
PLS_ICON_SM = PLS_ICON_SM_ASSET.readall()

NO_DATA = "---------- "
MAX_RESPONSE_BYTES = 262144
CACHE_TTL_SECONDS = 600

DEXSCREENER_PLS_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0x6753560538ECa67617A9Ce605178F788bE7E524E"
DEXSCREENER_PLSX_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0x1b45b9148791d3a104184Cd5DFE5CE57193a3ee9"
DEXSCREENER_INC_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0xf808Bb6265e9Ca27002c0A04562Bf50d4FE37EAA"

def main():
    # Get PLS price
    pls_price = get_price(DEXSCREENER_PLS_URL)

    # Get PLS price
    plsx_price = get_price(DEXSCREENER_PLSX_URL)

    # INC price
    inc_price = get_price(DEXSCREENER_INC_URL)

    # Setup display rows
    displayRows = []

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLS_ICON_SM),
                render.Text(pls_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLSX_ICON_SM),
                render.Text(plsx_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = INC_ICON_SM),
                render.Text(inc_price),
            ],
        ),
    )

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = displayRows,
                ),
            ],
        ),
    )

def get_price(url):
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    data = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    pairs = data.get("pairs", []) if type(data) == "dict" else []
    price = pairs[0].get("priceUsd") if type(pairs) == "list" and len(pairs) > 0 and type(pairs[0]) == "dict" else None
    return "$" + price if type(price) == "string" and price and len(price) <= 24 else NO_DATA
