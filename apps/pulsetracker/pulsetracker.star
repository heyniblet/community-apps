"""
Applet: Pulse Tracker
Summary: Pulse Tracker
Description: Displays Pulsechain token prices and price changes in USD over the last 24 hours.
Author: kmphua
Thanks: playak
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

# CONFIG
TTL = 300
MAX_RESPONSE_BYTES = 256 * 1024
NO_DATA = "---"

# INIT
COINCOLORS = {}  # define matching font colors for top coins
COINCOLORS["WPLS"] = "#0AF"
COINCOLORS["PLSX"] = "#F00"
COINCOLORS["INC"] = "#0F0"
COINCOLORS["HEX"] = "#F50"
COINCOLORS["EHEX"] = "#F50"
COINCOLORS["HELGO"] = "#F00"
COINCOLORS["PKTTN"] = "#F0F"
COINCOLORS["LOAN"] = "#F5F"
COINCOLORS["USDL"] = "#05F"
COINCOLORS["ICSA"] = "#0AF"
COINCOLORS["HDRN"] = "#05F"
COINCOLORS["B9"] = "#050"
COINCOLORS["PHUX"] = "#F00"
COINCOLORS["PHIAT"] = "#0AF"
COINCOLORS["PHAME"] = "#0AF"
COINCOLORS["MINT"] = "#0A0"
COINCOLORS["WATT"] = "#FFF"
COINCOLORS["9INCH"] = "#F00"
COINCOLORS["BBC"] = "#F00"
COINCOLORS["RBC"] = "#FA0"
COINCOLORS["CST"] = "#0FF"
COINCOLORS["SOIL"] = "#0FF"
COINCOLORS["SOLIDX"] = "#0FF"
COINCOLORS["BEAR"] = "#0FF"
COINCOLORS["MOST"] = "#0FF"
COINCOLORS["ATROPA"] = "#0FF"
COINCOLORS["SPARTA"] = "#0FF"
COINCOLORS["PUMP"] = "#0FF"
COINCOLORS["DOUBT"] = "#0FF"
COINCOLORS["BEST"] = "#0FF"
COINCOLORS["TRUMP"] = "#0FF"
COINCOLORS["UFO"] = "#0FF"

# MAIN
def main(config):
    token = config.get("token", "0x6753560538ECa67617A9Ce605178F788bE7E524E")  # Default PLS
    if not valid_pair_id(token):
        return render.Root(renderbox({"ticker": NO_DATA, "price": NO_DATA, "change": None}))
    API = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/" + token
    price_data = get_json_from_cache_or_http(API, TTL)
    price = NO_DATA
    ticker = NO_DATA
    change = NO_DATA
    pairs = price_data.get("pairs", []) if type(price_data) == "dict" else []
    pair = pairs[0] if type(pairs) == "list" and len(pairs) > 0 and type(pairs[0]) == "dict" else {}
    base_token = pair.get("baseToken", {})
    price_change = pair.get("priceChange", {})
    price_usd = pair.get("priceUsd")
    symbol = base_token.get("symbol") if type(base_token) == "dict" else None
    if type(price_usd) == "string" and len(price_usd) <= 24:
        price = "$" + price_usd
    if type(symbol) == "string" and len(symbol) <= 12:
        ticker = symbol
    if type(price_change) == "dict" and type(price_change.get("h24")) in ["int", "float"]:
        change = price_change["h24"]
    coininfo = {"ticker": ticker, "price": price, "change": change}
    coinlines = renderbox(coininfo)
    return render.Root(
        coinlines,
    )

# FUNCTIONS

def get_json_from_cache_or_http(url, timeout):
    res = http.get(url, ttl_seconds = timeout)
    body = res.body()
    if res.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    return json.decode(body, None)

def valid_pair_id(value):
    return type(value) == "string" and len(value) == 42 and value.startswith("0x") and not any([c not in "0123456789abcdefABCDEF" for c in value[2:].codepoints()])

def renderpercentage(p):
    if type(p) not in ["int", "float"]:
        return render.Text(NO_DATA, color = "#888")
    color = "#888"
    if p > 0.1:
        color = "#07C18E"
    elif p < -0.1:
        color = "#FF5550"
    pabs = math.fabs(p)
    if pabs > 10:
        decimals = 1
    else:
        decimals = 2
    fact = math.pow(10, decimals)
    p = math.round(p * fact) / fact
    return render.Text(str(p) + "%", color = color)

def renderbox(coin, color = "#FFF"):
    if "price" in coin:  # coin["price"] is set. must be coin data
        children = [
            render.Text(coin["ticker"], color = coincolor(coin["ticker"]), font = "6x13"),
            render.Text(coin["price"]),
            renderpercentage(coin["change"]),
        ]
    else:  # must be some lines of text, ie the credits
        children = []
        for textline in coin:
            children.append(render.Text(textline, color = color, font = "tom-thumb"))
    toreturn = render.Box(
        render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = children,
        ),
        color = "#000",  # black background, to clean the rest of the screen
    )
    return toreturn

def coincolor(ticker):
    toreturn = "#AAA"
    if ticker in COINCOLORS:
        toreturn = COINCOLORS[ticker]
    return toreturn

def get_schema():
    tokenoptions = [
        schema.Option(
            display = "PLS",
            value = "0x6753560538ECa67617A9Ce605178F788bE7E524E",
        ),
        schema.Option(
            display = "PLSX",
            value = "0x1b45b9148791d3a104184Cd5DFE5CE57193a3ee9",
        ),
        schema.Option(
            display = "INC",
            value = "0xf808Bb6265e9Ca27002c0A04562Bf50d4FE37EAA",
        ),
        schema.Option(
            display = "HEX",
            value = "0xf1F4ee610b2bAbB05C635F726eF8B0C568c8dc65",
        ),
        schema.Option(
            display = "EHEX",
            value = "0x1dA059091d5fe9F2d3781e0FdA238BB109FC6218",
        ),
        schema.Option(
            display = "HELGO",
            value = "0x2772Cb1AC353b4ae486f5baC196f20DcBd8A097F",
        ),
        schema.Option(
            display = "PKTTN",
            value = "0xF996eD564568a70280A284c12F5405a507CD1300",
        ),
        schema.Option(
            display = "LOAN",
            value = "0x6D69654390c70D9e8814B04c69a542632DC93161",
        ),
        schema.Option(
            display = "USDL",
            value = "0x27557d148293d1C8e8f8c5DEEAb93545B1Eb8410",
        ),
        schema.Option(
            display = "ICSA",
            value = "0xe5bb65e7a384D2671C96cfE1Ee9663F7B03a573e",
        ),
        schema.Option(
            display = "HDRN",
            value = "0xbaE2b1aC914255AbE40eBE308458D592A0A9F44b",
        ),
        schema.Option(
            display = "B9",
            value = "0x05c4CB83895D284525DcAB245631cE504740931B",
        ),
        schema.Option(
            display = "PHUX",
            value = "0x9A2F5B8DFE4AD4c3d7A3bf41240694f91aCC2c0d",
        ),
        schema.Option(
            display = "PHIAT",
            value = "0xfe75839c16a6516149D0F7B2208395F54A5e16e8",
        ),
        schema.Option(
            display = "PHAME",
            value = "0xF64602fd08245d1D27F7D9452814BEa1451BD502",
        ),
        schema.Option(
            display = "RBC",
            value = "0x27290772EA970e3D0A82583Ff5b00d4ee9C812A0",
        ),
        schema.Option(
            display = "MINT",
            value = "0x5F2D8624e6aBEA8F679a1095182f4bC84fe148e0",
        ),
        schema.Option(
            display = "WATT",
            value = "0x956f097E055Fa16Aad35c339E17ACcbF42782DE6",
        ),
        schema.Option(
            display = "9INCH",
            value = "0x1164daB36Cd7036668dDCBB430f7e0B15416EF0b",
        ),
        schema.Option(
            display = "BBC",
            value = "0xb543812ddEbC017976f867Da710ddb30cCA22929",
        ),
        schema.Option(
            display = "CST",
            value = "0x284a7654B90D3c2e217B6da9fAc010e6C4b54610",
        ),
        schema.Option(
            display = "SOIL",
            value = "0xbd63FA573A120013804e51B46C56F9b3e490f53C",
        ),
        schema.Option(
            display = "SOLIDX",
            value = "0x89cffFB84016FBf4da34B400e847A61be1a7Fe34",
        ),
        schema.Option(
            display = "BEAR",
            value = "0xd6c31bA0754C4383A41c0e9DF042C62b5e918f6d",
        ),
        schema.Option(
            display = "MOST",
            value = "0x908B5490414518981ce5c473Ff120A6b338feF67",
        ),
        schema.Option(
            display = "ATROPA",
            value = "0x5EF7AaC0DE4F2012CB36730Da140025B113FAdA4",
        ),
        schema.Option(
            display = "SPARTA",
            value = "0xf3E1E07A463d27100404B7A4bdF7E3De5DD748be",
        ),
        schema.Option(
            display = "PUMP",
            value = "0x96Fefb743B1D180363404747bf09BD32657D8B78",
        ),
        schema.Option(
            display = "DOUBT",
            value = "0x6ba0876e30CcE2A9AfC4B82D8BD8A8349DF4Ca96",
        ),
        schema.Option(
            display = "BEST",
            value = "0x94670dB3BA08cbf045bc843B45e9125a33d777e9",
        ),
        schema.Option(
            display = "TRUMP",
            value = "0x2e2A603a35bff3c3e6a21A289Dfd5144d921d3a0",
        ),
        schema.Option(
            display = "UFO",
            value = "0x9aBD84EAE174c6cf7FBf67cBb550930845866e05",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "token",
                name = "Token",
                desc = "Pulsechain token",
                icon = "moneyBill",
                default = tokenoptions[0].value,
                options = tokenoptions,
            ),
        ],
    )
