# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Coinbase Portfolio
Summary: Value crypto with Coinbase
Description: Values manually configured holdings with Coinbase public exchange rates.
Author: harrywynn
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/coinbase_logo.png", COINBASE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

COINBASE_LOGO = COINBASE_LOGO_ASSET.readall()
RATES_URL = "https://api.coinbase.com/v2/exchange-rates?currency=USD"

def main(config):
    holdings = parse_holdings(config.str("holdings", "BTC:0.01,ETH:0.1"))
    if not holdings:
        return message("Add holdings like BTC:0.01")
    response = http.get(RATES_URL, ttl_seconds = 900)
    if response.status_code != 200 or len(response.body()) > 1024 * 1024:
        return message("Coinbase rates unavailable")
    payload = response.json()
    data = payload.get("data", {}) if type(payload) == "dict" else {}
    rates = data.get("rates", {}) if type(data) == "dict" else {}
    if type(rates) != "dict":
        return message("Invalid Coinbase rates")

    balance = 0.0
    currencies = []
    for currency, amount in holdings:
        rate = rates.get(currency)
        if rate:
            balance += amount / float(rate)
            currencies.append(currency)
    if not currencies:
        return message("No supported currencies")
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [render.Image(src = COINBASE_LOGO, width = 12), render.Text("$" + humanize.ftoa(balance, digits = 2), font = "6x13")],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
                render.Marquee(child = render.Text(" | ".join(currencies), font = "tom-thumb"), width = 64, align = "center"),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def parse_holdings(value):
    holdings = []
    for raw in value.split(",")[:20]:
        parts = raw.strip().split(":", 1)
        if len(parts) != 2:
            continue
        currency = parts[0].strip().upper()
        amount = parts[1].strip()
        if currency.replace("-", "").isalnum() and len(currency) <= 12 and amount:
            decimal_parts = amount.split(".")
            if len(decimal_parts) > 2 or any([part and not part.isdigit() for part in decimal_parts]) or all([not part for part in decimal_parts]):
                continue
            number = float(amount)
            if number >= 0 and number <= 1000000000:
                holdings.append((currency, number))
    return holdings

def message(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#1652f0"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "holdings",
                name = "Holdings",
                desc = "Comma-separated currency and amount pairs, for example BTC:0.01,ETH:0.1.",
                icon = "coins",
                default = "BTC:0.01,ETH:0.1",
            ),
        ],
    )
