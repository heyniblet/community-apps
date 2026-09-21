# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Murphy USA Gas
Summary: Murphy USA Gas Prices
Description: Display prices from selected Murphy USA station.
Author: jvivona
"""

# Thanks to Dan Adam for the Costco Gas app which this is based upon

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_CONFIG = {
    "price_color": "white",
}

# #######################################################
# #####           Where all the magic happens      ######
# #######################################################
def main(config):
    widgetMode = config.bool("$widget")
    gas_data = get_gas_data(config.str("endpoint_url"), config.str("relay_token"))
    if gas_data == None:
        return render.Root(child = render.WrappedText("Add a Murphy gas relay URL", font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

    labels, prices = get_price_display(gas_data, config)

    return render.Root(
        max_age = 1800,
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(gas_data["station"], color = "#0073A6"),
                ) if not widgetMode else render.Text(gas_data["storeNum"], color = "#0073A6"),
                render.Row(
                    children = [
                        render.Column(
                            children = labels,
                            cross_align = "start",
                        ),
                        render.Column(
                            children = prices,
                            cross_align = "end",
                        ),
                        render.Column(
                            children = get_hours_display(gas_data),
                            expanded = True,
                            main_align = "center",
                            cross_align = "end",
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                ),
            ],
        ),
    )

# #######################################################
# #####           Functions                        ######
# #######################################################
def get_schema():
    price_colors = [
        schema.Option(
            display = "White",
            value = "white",
        ),
        schema.Option(
            display = "Red Gas, Green Diesel",
            value = "red-green",
        ),
        schema.Option(
            display = "Green Gas, Red Diesel",
            value = "green-red",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                name = "Station relay URL",
                desc = "A user-owned HTTPS endpoint returning station, storeNum, openText, closeText, isOpen, regular, premium, and diesel as JSON.",
                icon = "link",
            ),
            schema.Text(
                id = "relay_token",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "price_color",
                name = "Price Color",
                desc = "Color scheme for price display",
                icon = "palette",
                default = DEFAULT_CONFIG["price_color"],
                options = price_colors,
            ),
        ],
    )

def get_gas_data(url, token):
    if type(url) != "string" or not url.startswith("https://") or len(url) > 4096 or any([char in url for char in [" ", "\r", "\n", "\t"]]) or not token:
        return None
    response = http.get(url, headers = {"Authorization": "Bearer " + token})
    if response.status_code != 200 or len(response.body()) > 128 * 1024:
        return None
    data = json.decode(response.body(), {})
    if type(data) != "dict" or type(data.get("isOpen")) != "bool":
        return None
    for key in ["station", "storeNum", "openText", "closeText", "regular", "premium", "diesel"]:
        if type(data.get(key)) != "string" or len(data[key]) > 200:
            return None
    return data

def get_price_display(gas_data, config):
    labels = []
    prices = []

    if gas_data.get("regular", "") != "":
        labels.append(
            render.Text("R: "),
        )
        prices.append(
            render.Text(str(gas_data["regular"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_data.get("premium", "") != "":
        labels.append(
            render.Text("P: "),
        )
        prices.append(
            render.Text(str(gas_data["premium"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_data.get("diesel", "") != "":
        labels.append(
            render.Text("D: "),
        )
        prices.append(
            render.Text(str(gas_data["diesel"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["dieselColor"]),
        )

    return labels, prices

def get_hours_display(gas_data):
    gas_render = []
    if gas_data["isOpen"]:
        gas_render.append(
            render.Padding(
                child = render.Text("OPEN", font = "tom-thumb", color = "#04AF45"),
                pad = (18, 0, 0, 0),
            ),
        )
    else:
        gas_render.append(
            render.Padding(
                child = render.Text("CLOSED", font = "tom-thumb", color = "#C90000"),
                pad = (10, 0, 0, 0),
            ),
        )

    gas_render.append(render.Text(gas_data["openText"], font = "tom-thumb"))
    gas_render.append(render.Text(gas_data["closeText"], font = "tom-thumb"))

    return gas_render

# #######################################################
# #####           Schema Option Values             ######
# #######################################################
PRICE_COLORS = {
    "white": {
        "gasColor": "#FFFFFF",
        "dieselColor": "#FFFFFF",
    },
    "red-green": {
        "gasColor": "#ff0000",
        "dieselColor": "#00FF00",
    },
    "green-red": {
        "gasColor": "#00FF00",
        "dieselColor": "#ff0000",
    },
}
