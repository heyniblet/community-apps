"""
Applet: PulseChain
Summary: Price of PLS, PLSX, and HEX
Description: Display the price of PLS, PLSX, and HEX. Choose between testnet and mainnet prices. After PulseChain mainnet launch, an update will be pushed to this app to display the correct mainnet price.
Author: bretep
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/hex_icon_sm.png", HEX_ICON_SM_ASSET = "file")
load("images/pls_icon_sm.png", PLS_ICON_SM_ASSET = "file")
load("images/plsx_icon_sm.png", PLSX_ICON_SM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

HEX_ICON_SM = HEX_ICON_SM_ASSET.readall()
PLSX_ICON_SM = PLSX_ICON_SM_ASSET.readall()
PLS_ICON_SM = PLS_ICON_SM_ASSET.readall()

NO_PRICE = "$  ------- "
COINGECKO_URL = "https://api.coingecko.com/api/v3/simple/price?ids=pulsechain,pulsex,hex&vs_currencies=usd"
DEFAULT_PULSE_URL = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-main"
DEFAULT_TESTNET_URL = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-testnet-v4"
DEFAULT_QUERY = """{"query":"{\n  pls: bundle(id: \"1\") {\n    derivedUSD\n  }\n  plsx: token(id: \"0x07890c29ed6dcf8cc59a686b24a317924d63a923\") {\n    derivedUSD\n  }\n}","variables":null}"""
MAX_RESPONSE_BYTES = 262144
CACHE_TTL_SECONDS = 300

POST_HEADERS = {
    "Content-Type": "application/json",
}

def main(config):
    prices = coingecko_prices()
    is_testnet = config.bool("testnet")
    pulse_url = config.str("pulse_testnet_url", DEFAULT_TESTNET_URL) if is_testnet else config.str("pulse_url", DEFAULT_PULSE_URL)
    default_url = DEFAULT_TESTNET_URL if is_testnet else DEFAULT_PULSE_URL

    if pulse_url != default_url:
        custom = graph_prices(pulse_url, config.str("pulse_query", DEFAULT_QUERY))
        prices["pls"] = custom.get("pls", NO_PRICE)
        prices["plsx"] = custom.get("plsx", NO_PRICE)
    elif is_testnet:
        # The retired default testnet feed has no trustworthy replacement.
        prices["pls"] = NO_PRICE
        prices["plsx"] = NO_PRICE

    display_pls_price = prices.get("pls", NO_PRICE)
    display_plsx_price = prices.get("plsx", NO_PRICE)
    display_eth_hex_price = prices.get("hex", NO_PRICE)

    defaultDisplayRows = [
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLS_ICON_SM),
                render.Text(display_pls_price),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLSX_ICON_SM),
                render.Text(display_plsx_price),
            ],
        ),
    ]

    displayRows = []

    if config.bool("hex"):
        displayRows.append(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = HEX_ICON_SM),
                    render.Text(display_eth_hex_price),
                ],
            ),
        )

    displayRows.extend(defaultDisplayRows)

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

def coingecko_prices():
    response = http.get(COINGECKO_URL, ttl_seconds = CACHE_TTL_SECONDS)
    data = decode_response(response)
    return {
        "pls": coin_price(data, "pulsechain"),
        "plsx": coin_price(data, "pulsex"),
        "hex": coin_price(data, "hex"),
    }

def coin_price(data, coin):
    item = data.get(coin, {}) if type(data) == "dict" else {}
    return format_price(item.get("usd") if type(item) == "dict" else None)

def graph_prices(url, query):
    if not url.startswith("https://") or not query or len(query) > 16384:
        return {}
    response = http.post(url, body = query, headers = POST_HEADERS, ttl_seconds = CACHE_TTL_SECONDS)
    payload = decode_response(response)
    data = payload.get("data", {}) if type(payload) == "dict" else {}
    pls = data.get("pls", {}) if type(data) == "dict" else {}
    plsx = data.get("plsx", {}) if type(data) == "dict" else {}
    return {
        "pls": format_decimal_price(pls.get("derivedUSD") if type(pls) == "dict" else None),
        "plsx": format_decimal_price(plsx.get("derivedUSD") if type(plsx) == "dict" else None),
    }

def decode_response(response):
    body = response.body()
    return json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None

def format_price(value):
    return "$" + humanize.float("#.########", value) if type(value) in ("int", "float") and value > 0 else NO_PRICE

def format_decimal_price(value):
    if type(value) != "string" or len(value) == 0 or len(value) > 32:
        return NO_PRICE
    parts = value.split(".")
    if len(parts) > 2 or not parts[0].isdigit() or (len(parts) == 2 and (not parts[1] or not parts[1].isdigit())):
        return NO_PRICE
    return format_price(float(value))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pulse_url",
                name = "PulseChain Mainnet API URL",
                desc = "The API URL for PulseChain mainnet. Obtain this from a trusted source.",
                icon = "link",
                default = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-main",
            ),
            schema.Text(
                id = "pulse_testnet_url",
                name = "PulseChain Testnet API URL",
                desc = "The API URL for PulseChain testnet. Obtain this from a trusted source.",
                icon = "link",
                default = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-testnet-v4",
            ),
            schema.Text(
                id = "pulse_query",
                name = "PulseChain GraphQL Query",
                desc = "The GraphQL query for PulseChain data. Do not modify unless you know what you're doing.",
                icon = "code",
                default = """{"query":"{\n  pls: bundle(id: \"1\") {\n    derivedUSD\n  }\n  plsx: token(id: \"0x07890c29ed6dcf8cc59a686b24a317924d63a923\") {\n    derivedUSD\n  }\n}","variables":null}""",
            ),
            schema.Toggle(
                id = "testnet",
                name = "Testnet",
                desc = "Turn on to see testnet tickers",
                icon = "flaskVial",
                default = False,
            ),
            schema.Toggle(
                id = "hex",
                name = "Show HEX",
                desc = "Display price of HEX",
                icon = "star",
                default = True,
            ),
        ],
    )
