"""
Applet: GoldpriceTicker
Summary: Precious Metal Quotes
Description: Shows near-realtime precious metal prices and change over the selected period.
Author: Aaron Brace
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

HISTORY_URL = "https://dpms.mcio.org/metals/v1/"
LATEST_URL = "https://dpms.mcio.org/metals/v1/latest"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_HISTORY_POINTS = 5000
METALS = ["gold", "silver", "platinum", "palladium", "rhodium", "copper"]
PERIODS = {
    "twentyfourhour": (30 * 3600, 20 * 60, "24h"),
    "30day": (30 * 86400, 6 * 3600, "30d"),
    "90day": (90 * 86400, 6 * 3600, "90d"),
    "1year": (365 * 86400, 6 * 3600, "1y"),
}
NAMES = {"gold": "Gold", "silver": "Silver", "platinum": "Platnm", "palladium": "Palladm", "rhodium": "Rhodium", "copper": "Copper"}

def main(config):
    metal = config.get("metal", "gold")
    period = config.get("period", "twentyfourhour")
    if metal == "version":
        return render_message("GoldpriceTicker 2.1")
    metal = metal if metal in METALS else "gold"
    period = period if period in PERIODS else "twentyfourhour"
    api_key = config.get("dev_api_key")
    if not valid_key(api_key):
        return render_message("Configure metals API key")

    history = fetch_json(HISTORY_URL + period + "/" + metal + "?API_KEY=" + api_key)
    latest = fetch_json(LATEST_URL + "?API_KEY=" + api_key)
    if type(history) != "list" or latest == None:
        return render_message("Metal prices unavailable")

    window, bucket_size, period_label = PERIODS[period]
    cutoff_ms = (time.now().unix - window) * 1000
    prices = {}
    for entry in history[:MAX_HISTORY_POINTS]:
        if type(entry) != "dict":
            continue
        timestamp = safe_number(entry.get("timestamp"))
        price = safe_number(entry.get("price"))
        if timestamp == None or price == None or timestamp < cutoff_ms or price <= 0:
            continue
        prices[int(timestamp / 1000 / bucket_size)] = price

    keys = sorted(prices)
    current_price = latest_price(latest, metal)
    if not keys or current_price == None or current_price <= 0:
        return render_message("Invalid metal price data")

    baseline = prices[keys[0]]
    amount_change = current_price - baseline
    percentage_change = amount_change / baseline * 100
    points = [(key, (prices[key] / baseline - 1) * 100) for key in keys]
    color = "#006000" if percentage_change >= 0 else "#aa0000"
    graph = render.Plot(
        data = points,
        width = 64,
        height = 20,
        x_lim = (keys[0], max(keys[-1], keys[0] + 1)),
        color = "#0f0",
        color_inverted = "#f00",
        fill = True,
    )
    return render.Root(
        child = render.Column(
            cross_align = "start",
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Row(main_align = "space_between", children = [
                        render.Text(NAMES[metal] + "-" + period_label, font = "tom-thumb", color = "#cccccc"),
                        render.Text(humanize.float("#.##", amount_change), font = "tom-thumb", color = color),
                    ]),
                ),
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Row(main_align = "space_between", children = [
                        render.Text(humanize.float("#.##", current_price), font = "tom-thumb", color = "#cccccc"),
                        render.Text(humanize.float("#.##", percentage_change) + "%", font = "tom-thumb", color = color),
                    ]),
                ),
                graph,
            ],
        ),
    )

def fetch_json(url):
    response = http.get(url)
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return None
    return json.decode(body, None)

def latest_price(payload, metal):
    values = payload if type(payload) == "list" else [payload] if type(payload) == "dict" else []
    for entry in values[:100]:
        value = safe_number(entry.get(metal)) if type(entry) == "dict" else None
        if value != None:
            return value
    return None

def safe_number(value):
    if type(value) == "int" or type(value) == "float":
        return float(value)
    if type(value) != "string" or len(value) > 32:
        return None
    cleaned = value.strip()
    unsigned = cleaned[1:] if cleaned.startswith("-") or cleaned.startswith("+") else cleaned
    parts = unsigned.split(".")
    if len(parts) > 2 or not "".join(parts):
        return None
    for char in "".join(parts).elems():
        if char not in "0123456789":
            return None
    return float(cleaned)

def valid_key(value):
    if type(value) != "string" or not value or len(value) > 256:
        return False
    return all([char.isalnum() or char in "-_" for char in value.elems()])

def render_message(message):
    return render.Root(child = render.WrappedText(content = message, width = 62, align = "center"))

def get_schema():
    metals = [
        schema.Option(display = "Silver", value = "silver"),
        schema.Option(display = "Gold", value = "gold"),
        schema.Option(display = "Platinum", value = "platinum"),
        schema.Option(display = "Palladium", value = "palladium"),
        schema.Option(display = "Rhodium", value = "rhodium"),
        schema.Option(display = "Copper", value = "copper"),
        schema.Option(display = "Version & Credits", value = "version"),
    ]
    periods = [
        schema.Option(display = "24 Hours", value = "twentyfourhour"),
        schema.Option(display = "30 Days", value = "30day"),
        schema.Option(display = "90 Days", value = "90day"),
        schema.Option(display = "1 Year", value = "1year"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(id = "metal", name = "Precious Metal", desc = "Metal to quote and graph.", icon = "coins", options = metals, default = "gold"),
            schema.Dropdown(id = "period", name = "Graph Period", desc = "Time period used for the chart and change.", icon = "clock", options = periods, default = "twentyfourhour"),
            schema.Text(id = "dev_api_key", name = "API Key", desc = "Your metals-dev API key.", icon = "key", secret = True),
        ],
    )
