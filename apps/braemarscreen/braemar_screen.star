"""
Applet: Braemar Screen
Summary: View dry bulk futures
Description: Allows you to see the top 3 dry bulk futures from Braemarscreen.
Author: Ali-Mahmood
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

BRAEMAR_PRICES_URL = "https://api.braemarscreen.com/api/graphql"

BRAEMAR_QUERY = json.encode(
    {
        "query": "query HomepageMarkets { brokerSite { ticker { name products { name price prevClose } } }}",
    },
)

PRODUCT_HEIGHT = 60
FONT = "tom-thumb"
GREEN = "#008000"
RED = "#FF0000"
MAX_RESPONSE_BYTES = 256 * 1024

# renders the index/tick name as a heading
def render_heading_name(tick):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Padding(
                pad = (1, 1, 1, 0),
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 50,
                    height = 6,
                    child = render.Text(
                        content = tick["name"],
                        font = FONT,
                    ),
                ),
            ),
        ],
    )

# renders the line to separate the header name to the values
def render_separator():
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Box(
            height = 1,
            color = GREEN,
        ),
    )

def render_values(name, price, prevClose, config):
    price_color = "%s" % config.str("price_color", "#0000FF")

    change = float(price) - float(prevClose)

    change_color = GREEN

    if change >= 0:
        change_color = GREEN
    else:
        change_color = RED

    return render.Row(
        expanded = True,
        children = [
            render.WrappedText(
                content = str(name),
                width = 12,
                font = FONT,
            ),
            render.WrappedText(
                content = str(int(math.round(float(price)))),
                width = 20,
                color = price_color,
                font = FONT,
            ),
            render.Row(
                main_align = "end",
                expanded = True,
                children = [
                    render.Text(
                        content = str(math.round(change)),
                        color = change_color,
                        font = FONT,
                    ),
                ],
            ),
        ],
    )

def render_values_section(products, config):
    return render.Padding(
        pad = (1, 0, 1, 0),
        child = render.Box(
            height = PRODUCT_HEIGHT,
            child = render.Column(
                main_align = "start",
                expanded = True,
                children = [
                    render_values(a["name"], a["price"], a["prevClose"], config)
                    for a in products
                ],
            ),
        ),
    )

# renders a box for an index/tick thats passed in
def render_each_index(tick, config):
    products = tick["products"]
    return render.Box(
        render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                # Top part is the name of the index
                render_heading_name(tick),
                render_separator(),
                # Bottom part shows prices for each product
                render_values_section(products, config),
            ],
        ),
        padding = 0,
        height = 45,
        width = 64,
    )

def main(config):
    ttl = config.get("ttl", "60")
    if ttl not in ["10", "20", "30", "60"]:
        ttl = "60"
    rep = http.post(
        BRAEMAR_PRICES_URL,
        body = BRAEMAR_QUERY,
        ttl_seconds = int(ttl),
        headers = {
            "content-type": "application/json",
        },
    )  # cache for 1 minute
    if rep.status_code != 200:
        return render.Root(child = render.WrappedText(content = "Market data unavailable", align = "center"))
    body = rep.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return render.Root(child = render.WrappedText(content = "Market data unavailable", align = "center"))
    data = json.decode(body)
    data = data.get("data") if type(data) == "dict" else None
    broker_site = data.get("brokerSite") if type(data) == "dict" else None
    tickers = broker_site.get("ticker") if type(broker_site) == "dict" else None
    if type(tickers) != "list":
        return render.Root(child = render.WrappedText(content = "Market data unavailable", align = "center"))

    indexes = []
    for tick in tickers[:3]:
        products = tick.get("products") if type(tick) == "dict" else None
        name = tick.get("name") if type(tick) == "dict" else None
        if type(name) != "string" or type(products) != "list":
            continue
        clean_products = []
        for product in products[:5]:
            product_name = product.get("name") if type(product) == "dict" else None
            price = product.get("price") if type(product) == "dict" else None
            previous = product.get("prevClose") if type(product) == "dict" else None
            price = str(price) if type(price) in ["int", "float"] else price
            previous = str(previous) if type(previous) in ["int", "float"] else previous
            if type(product_name) == "string" and type(price) == "string" and type(previous) == "string" and re.match(r"^-?[0-9]+(\.[0-9]+)?$", price) and re.match(r"^-?[0-9]+(\.[0-9]+)?$", previous):
                clean_products.append({"name": product_name[:80], "price": price, "prevClose": previous})
        if clean_products:
            indexes.append(render_each_index({"name": name[:120], "products": clean_products}, config))

    if not indexes:
        return render.Root(child = render.WrappedText(content = "Market data unavailable", align = "center"))

    return render.Root(
        max_age = 120,
        delay = 100,
        show_full_animation = True,
        child = render.Marquee(
            height = 34,
            offset_start = 5,
            offset_end = 0,
            scroll_direction = "vertical",
            child = render.Column(
                children = indexes,
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "10 seconds",
            value = "10",
        ),
        schema.Option(
            display = "20 seconds",
            value = "20",
        ),
        schema.Option(
            display = "30 seconds",
            value = "30",
        ),
        schema.Option(
            display = "60 seconds",
            value = "60",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "price_color",
                name = "Price Colour",
                desc = "Colour for the prices",
                icon = "palette",
                default = "#0000FF",
                palette = [
                    "#0000FF",
                    "#FF0000",
                    "#FFFF00",
                    "#00FF00",
                    "#FFAA00",
                    "#00FFFF",
                    "#FF00FF",
                    "#FFFFFF",
                ],
            ),
            schema.Dropdown(
                id = "ttl",
                name = "Refresh",
                desc = "How often to refresh the values",
                icon = "arrowsRotate",
                default = options[0].value,
                options = options,
            ),
        ],
    )
