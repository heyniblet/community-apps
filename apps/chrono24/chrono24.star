"""
Applet: Chrono24
Summary: Watch market performance
Description: Gives ability to show watch market performance over multiple durations as well as seeing brand performance.
Author: Chase Roossin
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_WHO = "world"
BASE_URL = "https://www.chrono24.com/api/priceindex/performance-chart.json?type=Market&period="
CONFIG_TIMEFRAME = "config-timeframe"
CONFIG_VIEW_TYPE = "config-view-type"
CONFIG_VIEW_TYPE_GRAPH = "graph"
CONFIG_VIEW_TYPE_INDEXES = "indexes"
CACHE_TTL = 21600  # 6 hours; ChronoPulse is updated daily.
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
MAX_PRICE_POINTS = 1000

def error_view(message):
    return render.Root(child = two_line("Chrono24", message))

def main(config):
    timeframe = config.str(CONFIG_TIMEFRAME, "_1month")
    if timeframe not in ["_1month", "_3months", "_6months", "_1year", "_3years", "max"]:
        timeframe = "_1month"
    viewtype = config.str(CONFIG_VIEW_TYPE, CONFIG_VIEW_TYPE_GRAPH)
    if viewtype not in [CONFIG_VIEW_TYPE_GRAPH, CONFIG_VIEW_TYPE_INDEXES]:
        viewtype = CONFIG_VIEW_TYPE_GRAPH

    rep = http.get(BASE_URL + timeframe, ttl_seconds = CACHE_TTL)
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "dict":
        return error_view("Data unavailable")

    if viewtype == CONFIG_VIEW_TYPE_GRAPH:
        return market_view_render(timeframe, data)
    else:
        return watch_indexes_render(data)

def market_view_render(timeframe, data):
    # Construct graph points
    price_points = []
    price_index_data = data.get("priceIndexData")
    if type(price_index_data) != "list":
        return error_view("Data unavailable")
    lowest_price = 0
    highest_price = 0
    first_price = 0
    last_price = 0

    for price_data in price_index_data[:MAX_PRICE_POINTS]:
        if type(price_data) != "dict" or type(price_data.get("y")) != "dict" or type(price_data["y"].get("mean")) != "dict":
            continue
        value = price_data["y"]["mean"].get("value")
        if type(value) not in ["int", "float"]:
            continue
        index = len(price_points)

        # on first, set highest and lowest
        if index == 0:
            lowest_price = value
            highest_price = value
            first_price = value

        # Update highest/lowest price
        if value < lowest_price:
            lowest_price = value
        if value > highest_price:
            highest_price = value

        price_points.append((index, value))
        last_price = value

    if not price_points:
        return error_view("No market data")

    primary_color = "#0f0" if last_price > first_price else "#f00"
    percent_change = ((last_price - first_price) / first_price) * 100 if first_price != 0 else 0
    if lowest_price == highest_price:
        highest_price += 1

    return render.Root(
        child = render.Column(
            children = [
                # First row, timeframe and dollar change
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Text(content = get_pretty_timeframe_title(timeframe)),
                        render.Text(content = str(make_two_decimal(last_price - first_price)), color = primary_color),
                    ],
                ),

                # Second row, current value and percent change
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Text(content = str(make_two_decimal(last_price))),
                        render.Text(content = str(make_two_decimal(percent_change)) + "%", color = primary_color),
                    ],
                ),

                # Graph
                render.Plot(
                    data = price_points,
                    width = 66,
                    height = 15,
                    color = primary_color,
                    y_lim = (lowest_price, highest_price),
                    fill = True,
                ),
            ],
        ),
    )

def watch_indexes_render(data):
    # Take first 10 watches, eventually make configurable
    watches = data.get("indexComponents")
    if type(watches) != "list":
        return error_view("Data unavailable")

    # Generate the rows
    watch_rows = []
    for watch in watches[:10]:
        if type(watch) == "dict" and type(watch.get("change")) in ["int", "float"]:
            watch_rows.append(generate_watch_row(watch))

    if not watch_rows:
        return error_view("No watch data")

    return render.Root(
        child = render.Sequence(
            children = watch_rows,
        ),
    )

def generate_watch_row(watch):
    # TODO: ADD Images

    color = "#f00" if watch["change"] < 0 else "#0f0"

    return animation.Transformation(
        child = render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = str(watch.get("brandName") or "Unknown")[:80], color = "#636363"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(content = str(watch.get("productName") or "Unknown")[:160]),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = "Ref: " + str(watch.get("referenceNumber") or "N/A")[:80], color = "#636363"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = "$" + str(watch.get("price") or "N/A")[:40], color = color),
                            render.Text(content = str(make_one_decimal(watch["change"] * 100)) + "%", color = color),
                        ],
                    ),
                ],
            ),
        ),
        duration = 50,
        delay = 0,
        keyframes = [],
    )

def two_line(line1, line2):
    return render.Box(
        width = 64,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(content = line1, font = "CG-pixel-4x5-mono"),
                render.Text(content = line2, font = "CG-pixel-4x5-mono", height = 10),
            ],
        ),
    )

def make_two_decimal(value):
    return int(value * 100) / 100.0

def make_one_decimal(value):
    return int(value * 10) / 10.0

def get_pretty_timeframe_title(value):
    titles = {
        "_1month": "1 mo",
        "_3months": "3 mo",
        "_6months": "6 mo",
        "_1year": "1 yr",
        "_3years": "3 yr",
        "max": "Max",
    }
    return titles.get(value, "Unknown")

def get_schema():
    timeframes = [
        schema.Option(display = "1 month", value = "_1month"),
        schema.Option(display = "3 months", value = "_3months"),
        schema.Option(display = "6 months", value = "_6months"),
        schema.Option(display = "1 year", value = "_1year"),
        schema.Option(display = "3 years", value = "_3years"),
        schema.Option(display = "Max", value = "max"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = CONFIG_VIEW_TYPE,
                name = "View type",
                desc = "Overall market performance or watch index",
                icon = "eye",
                default = "graph",
                options = [
                    schema.Option(display = "Market performance graph", value = CONFIG_VIEW_TYPE_GRAPH),
                    schema.Option(display = "Watch indexes", value = CONFIG_VIEW_TYPE_INDEXES),
                ],
            ),
            schema.Dropdown(
                id = CONFIG_TIMEFRAME,
                name = "Timeframe",
                desc = "The timeframe of the market performance",
                icon = "clock",
                default = "_1month",
                options = timeframes,
            ),
        ],
    )
