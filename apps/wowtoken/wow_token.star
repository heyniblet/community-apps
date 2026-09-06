"""
Applet: WoW Token
Summary: Display WoW Token Price
Description: Displays the current price of the World of Warcraft token in various regions. Data provided by wowtoken.app.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/token.png", GOLD_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GOLD_ICON = GOLD_ICON_ASSET.readall()

WOW_TOKEN_URL = "https://data.wowtoken.app/v2/current/retail.json"
REGION_LIST = ["us", "eu", "kr", "tw"]

def get_schema():
    region_options = [
        schema.Option(display = region, value = region)
        for region in REGION_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Choose the World of Warcraft region.",
                icon = "moneyBill",
                default = "us",
                options = region_options,
            ),
        ],
    )

def main(config):
    region = config.get("region", "us")
    if region not in REGION_LIST:
        region = "us"

    query = http.get(WOW_TOKEN_URL, ttl_seconds = 600)
    body = query.body()
    data = json.decode(body, {}) if query.status_code == 200 and body and len(body) <= 16 * 1024 else {}
    price = data.get(region) if type(data) == "dict" else None
    if type(price) != "list" or len(price) < 2 or type(price[1]) not in ["int", "float"] or price[1] < 0:
        return render.Root(child = render.WrappedText(content = "Token price unavailable", width = 64, color = "#f00"))
    token_price = int(price[1])

    display = []
    display.append(render.Row(
        children = [
            render.Text("{}".format(humanize.comma(token_price))),
        ],
    ))

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = GOLD_ICON),
                    render.Column(
                        main_align = "space_evenly",
                        expanded = True,
                        children = display,
                    ),
                ],
            ),
        ),
    )
