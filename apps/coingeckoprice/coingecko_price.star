"""
Applet: CoinGecko Price
Summary: Crypto price from CoinGecko
Description: Displays the current price of any coin supported by CoinGecko against one or two other currencies. Crypto price data updated every 10 minutes. Data provided by CoinGecko.
Author: Allen Schober (@aschober)
Thanks: @saltedlolly as this is based on the digibyteprice app.
"""

load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

URL_COINGECKO_PRICE = "https://api.coingecko.com/api/v3/coins/{}?localization=false&tickers=false&community_data=false&developer_data=false"

SELECTED_CURRENCY_NONE = "[none]"
CURRENCY_SYMBOL_SETTINGS = ("left", "right", "hidden")

DEFAULT_COIN_ID = "bitcoin"
DEFAULT_FIRST_CURRENCY = "usd"
DEFAULT_SECOND_CURRENCY = "eth"
DEFAULT_CURRENCY_SYMBOL_SETTING = CURRENCY_SYMBOL_SETTINGS[0]
DEFAULT_CURRENCY_CODE_SETTING = True

SCHEMA_ID_COIN_ID = "coin_id"
SCHEMA_ID_FIRST_CURRENCY = "first_currency"
SCHEMA_ID_SECOND_CURRENCY = "second_currency"
SCHEMA_ID_FIRST_CURRENCY_SYMBOL_SETTING = "first_currency_symbol_setting"
SCHEMA_ID_FIRST_CURRENCY_CODE_SETTING = "first_currency_code_setting"
SCHEMA_ID_SECOND_CURRENCY_SYMBOL_SETTING = "second_currency_symbol_setting"
SCHEMA_ID_SECOND_CURRENCY_CODE_SETTING = "second_currency_code_setting"

SCHEMA_DESC_COIN_ID = "The name of the cryptocurrency to display."
SCHEMA_DESC_CURRENCY = "Choose another currency to display the price in. Select [NONE] to hide."
SCHEMA_DESC_CURRENCY_SYMBOL_SETTING = "Choose to show the currency symbol (e.g. $) on left, right, or not at all. If a symbol is not available, nothing will be shown."
SCHEMA_DESC_CURRENCY_CODE_SETTING = "Choose to display the currency code. Useful when displaying two dollar currencies together (e.g. USD and AUD)."

def get_schema():
    # add [NONE] option to supported_currencies to give option to hide
    currency_options = [
        schema.Option(display = currency.upper(), value = currency)
        for currency in [SELECTED_CURRENCY_NONE] + sorted(SUPPORTED_CURRENCIES)
    ]
    currency_symbol_options = [
        schema.Option(display = option.capitalize(), value = option)
        for option in CURRENCY_SYMBOL_SETTINGS
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = SCHEMA_ID_COIN_ID,
                name = "Cryptocurrency",
                desc = SCHEMA_DESC_COIN_ID + " Enter its CoinGecko API ID.",
                icon = "coins",
                default = DEFAULT_COIN_ID,
            ),
            schema.Dropdown(
                id = SCHEMA_ID_FIRST_CURRENCY,
                name = "Currency A",
                desc = SCHEMA_DESC_CURRENCY,
                icon = "moneyBill",
                default = DEFAULT_FIRST_CURRENCY,
                options = currency_options,
            ),
            schema.Dropdown(
                id = SCHEMA_ID_FIRST_CURRENCY_SYMBOL_SETTING,
                name = "Currency A: Show Symbol",
                desc = SCHEMA_DESC_CURRENCY_SYMBOL_SETTING,
                icon = "moneyBill",
                default = DEFAULT_CURRENCY_SYMBOL_SETTING,
                options = currency_symbol_options,
            ),
            schema.Toggle(
                id = SCHEMA_ID_FIRST_CURRENCY_CODE_SETTING,
                name = "Currency A: Show Code",
                desc = SCHEMA_DESC_CURRENCY_CODE_SETTING,
                icon = "toggleOn",
                default = DEFAULT_CURRENCY_CODE_SETTING,
            ),
            schema.Dropdown(
                id = SCHEMA_ID_SECOND_CURRENCY,
                name = "Currency B",
                desc = SCHEMA_DESC_CURRENCY,
                icon = "moneyBill",
                default = DEFAULT_SECOND_CURRENCY,
                options = currency_options,
            ),
            schema.Dropdown(
                id = SCHEMA_ID_SECOND_CURRENCY_SYMBOL_SETTING,
                name = "Currency B: Show Symbol",
                desc = SCHEMA_DESC_CURRENCY_SYMBOL_SETTING,
                icon = "moneyBill",
                default = DEFAULT_CURRENCY_SYMBOL_SETTING,
                options = currency_symbol_options,
            ),
            schema.Toggle(
                id = SCHEMA_ID_SECOND_CURRENCY_CODE_SETTING,
                name = "Currency B: Show Code",
                desc = SCHEMA_DESC_CURRENCY_CODE_SETTING,
                icon = "toggleOn",
                default = DEFAULT_CURRENCY_CODE_SETTING,
            ),
        ],
    )

def main(config):
    # Get data out of config
    coin_id = selected_coin_id(config.get(SCHEMA_ID_COIN_ID, DEFAULT_COIN_ID))

    first_currency = config.get(SCHEMA_ID_FIRST_CURRENCY, DEFAULT_FIRST_CURRENCY)
    first_currency_symbol_setting = config.get(SCHEMA_ID_FIRST_CURRENCY_SYMBOL_SETTING, DEFAULT_CURRENCY_SYMBOL_SETTING)
    first_currency_code_bool = config.bool(SCHEMA_ID_FIRST_CURRENCY_CODE_SETTING, DEFAULT_CURRENCY_CODE_SETTING)

    second_currency = config.get(SCHEMA_ID_SECOND_CURRENCY, DEFAULT_SECOND_CURRENCY)
    second_currency_symbol_setting = config.get(SCHEMA_ID_SECOND_CURRENCY_SYMBOL_SETTING, DEFAULT_CURRENCY_SYMBOL_SETTING)
    second_currency_code_bool = config.bool(SCHEMA_ID_SECOND_CURRENCY_CODE_SETTING, DEFAULT_CURRENCY_CODE_SETTING)
    if first_currency not in SUPPORTED_CURRENCIES + [SELECTED_CURRENCY_NONE]:
        first_currency = DEFAULT_FIRST_CURRENCY
    if second_currency not in SUPPORTED_CURRENCIES + [SELECTED_CURRENCY_NONE]:
        second_currency = DEFAULT_SECOND_CURRENCY
    if first_currency_symbol_setting not in CURRENCY_SYMBOL_SETTINGS:
        first_currency_symbol_setting = DEFAULT_CURRENCY_SYMBOL_SETTING
    if second_currency_symbol_setting not in CURRENCY_SYMBOL_SETTINGS:
        second_currency_symbol_setting = DEFAULT_CURRENCY_SYMBOL_SETTING

    # Get coin data for selected coin from CoinGecko
    coin_data = get_json_from_cache_or_http(URL_COINGECKO_PRICE.format(coin_id), ttl_seconds = 600)

    #Setup price display variable
    display_vec = []

    # Check for catastrophic data failure (i.e. failed to get data from CoinGecko and no cache data is available to fall back on)
    if type(coin_data) != "dict" or type(coin_data.get("market_data")) != "dict" or type(coin_data["market_data"].get("current_price")) != "dict":
        display_error = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
                render.Text("CoinGecko API", font = "CG-pixel-3x5-mono"),
                render.Text("unvailable", font = "CG-pixel-3x5-mono"),
            ],
        )
        display_vec.append(display_error)
        return render.Root(
            child = render.Box(
                display_error,
            ),
        )

    # Setup first currency price
    if first_currency != SELECTED_CURRENCY_NONE:
        if first_currency not in coin_data["market_data"]["current_price"]:
            return render.Root(child = render.Text("Price unavailable"))
        first_currency_price = float(coin_data["market_data"]["current_price"][first_currency])
        first_currency_symbol = CURRENCY_SYMBOLS_MAP.get(first_currency.upper(), "")
        first_currency_code = first_currency.upper()

        display_first_currency_price = format_price_string(
            first_currency_price,
            first_currency_symbol,
            first_currency_symbol_setting,
            first_currency_code,
            first_currency_code_bool,
        )
        display_vec.append(display_first_currency_price)

    # Setup second currency price
    if second_currency != SELECTED_CURRENCY_NONE:
        if second_currency not in coin_data["market_data"]["current_price"]:
            return render.Root(child = render.Text("Price unavailable"))
        second_currency_price = float(coin_data["market_data"]["current_price"][second_currency])
        second_currency_symbol = CURRENCY_SYMBOLS_MAP.get(second_currency.upper(), "")
        second_currency_code = second_currency.upper()

        display_second_currency_price = format_price_string(
            second_currency_price,
            second_currency_symbol,
            second_currency_symbol_setting,
            second_currency_code,
            second_currency_code_bool,
        )
        display_vec.append(display_second_currency_price)

    # get coin image
    image_data = coin_data.get("image", {})
    coin_image_url = image_data.get("large", "") if type(image_data) == "dict" else ""
    coin_image = get_body_from_cache_or_http(coin_image_url, ttl_seconds = 86400)

    # build render objects
    row_children = []

    # build row with coin image
    if (len(coin_image) > 0):
        row_image = render.Image(
            src = coin_image,
            width = 18,
            height = 18,
        )
        row_children.append(row_image)

    # build row with price
    if (len(display_vec) > 0):
        row_price = render.Column(
            main_align = "space_evenly",
            expanded = True,
            children = display_vec,
        )
        row_children.append(row_price)

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = row_children,
            ),
        ),
    )

def selected_coin_id(raw):
    value = raw or DEFAULT_COIN_ID
    if value.startswith("{"):
        legacy_values = re.findall(r"\"value\"\s*:\s*\"([a-z0-9-]+)\"", value)
        value = legacy_values[0] if legacy_values else DEFAULT_COIN_ID
    return value if re.search(r"^[a-z0-9-]{1,100}$", value) else DEFAULT_COIN_ID

def get_json_from_cache_or_http(url, ttl_seconds):
    http_response = http.get(url, ttl_seconds = ttl_seconds)
    if http_response.status_code != 200:
        return None
    if len(http_response.body()) > 1048576:
        return None

    return http_response.json()

def get_body_from_cache_or_http(url, ttl_seconds):
    if not (url.startswith("https://assets.coingecko.com/") or url.startswith("https://coin-images.coingecko.com/")):
        return ""
    http_response = http.get(url, ttl_seconds = ttl_seconds)
    if http_response.status_code != 200:
        return ""
    if len(http_response.body()) > 2097152:
        return ""

    return http_response.body()

def format_price_string(currency_price, currency_symbol, currency_symbol_setting, currency_code, currency_code_setting):
    # Round price to nearest whole number (used to decide how many decimal places to leave)
    currency_price_integer = str(int(math.round(float(currency_price))))

    # Trim and format price
    if currency_price < 0.001:
        # values is a small decimal, display in sci notation
        #print("displaying in sci notation")
        currency_price = str(currency_price)

    elif len(currency_price_integer) <= 1:
        currency_price = str(int(math.round(currency_price * 1000)))
        if len(currency_price) < 4:
            currency_price = "0" + currency_price
        if len(currency_price) < 4:
            currency_price = "0" + currency_price
        if len(currency_price) < 4:
            currency_price = "0" + currency_price
        if len(currency_price) < 4:
            currency_price = "0" + currency_price
        currency_price = (currency_price[0:-3] + "." + currency_price[-3:])
    elif len(currency_price_integer) == 2:
        currency_price = str(int(math.round(currency_price * 1000)))
        currency_price = (currency_price[0:-3] + "." + currency_price[-3:])
    elif len(currency_price_integer) == 3:
        currency_price = str(int(math.round(currency_price * 100)))
        currency_price = (currency_price[0:-2] + "." + currency_price[-2:])
    elif len(currency_price_integer) == 4:
        currency_price = str(int(math.round(currency_price * 10)))
        currency_price = (currency_price[0:-1] + "." + currency_price[-1:])
    elif len(currency_price_integer) == 5:
        currency_price = str(int(math.round(currency_price)))
    elif len(currency_price_integer) >= 6:
        currency_price = str(int(math.round(currency_price)))

        # if price is a long string and symbol is not hidden, then don't show currency code
        if currency_symbol_setting != CURRENCY_SYMBOL_SETTINGS[2]:
            currency_code_setting = False

    if currency_symbol_setting == CURRENCY_SYMBOL_SETTINGS[0]:
        # if currency_symbol_setting == left
        currency_price = (currency_symbol + currency_price)
    elif currency_symbol_setting == CURRENCY_SYMBOL_SETTINGS[1]:
        # elif currency_symbol_setting == right
        currency_price = (currency_price + currency_symbol)

    if currency_code_setting == True:
        display_currency_price = render.Row(
            cross_align = "center",
            children = [
                render.Text("%s" % currency_price),
                render.Box(width = 1, height = 1),
                render.Text("%s" % currency_code, font = "CG-pixel-3x5-mono", color = "#2962fe"),
            ],
        )
    else:
        display_currency_price = render.Text(currency_price)

    return display_currency_price

# Currency symbol map
# from https://github.com/arshadkazmi42/currency-symbols
CURRENCY_SYMBOLS_MAP = {
    "AED": "د.إ",
    "AFN": "؋",
    "ALL": "L",
    "AMD": "֏",
    "ANG": "ƒ",
    "AOA": "Kz",
    "ARS": "$",
    "AUD": "$",
    "AWG": "ƒ",
    "AZN": "₼",
    "BAM": "KM",
    "BBD": "$",
    "BDT": "৳",
    "BGN": "лв",
    "BHD": ".د.ب",
    "BIF": "FBu",
    "BMD": "$",
    "BND": "$",
    "BOB": "$b",
    "BRL": "R$",
    "BSD": "$",
    "BTC": "฿",
    "BTN": "Nu.",
    "BWP": "P",
    "BYR": "Br",
    "BYN": "Br",
    "BZD": "BZ$",
    "CAD": "$",
    "CDF": "FC",
    "CHF": "CHF",
    "CLP": "$",
    "CNY": "¥",
    "COP": "$",
    "CRC": "₡",
    "CUC": "$",
    "CUP": "₱",
    "CVE": "$",
    "CZK": "Kč",
    "DJF": "Fdj",
    "DKK": "kr",
    "DOP": "RD$",
    "DZD": "دج",
    "EEK": "kr",
    "EGP": "£",
    "ERN": "Nfk",
    "ETB": "Br",
    "ETH": "Ξ",
    "EUR": "€",
    "FJD": "$",
    "FKP": "£",
    "GBP": "£",
    "GEL": "₾",
    "GGP": "£",
    "GHC": "₵",
    "GHS": "GH₵",
    "GIP": "£",
    "GMD": "D",
    "GNF": "FG",
    "GTQ": "Q",
    "GYD": "$",
    "HKD": "$",
    "HNL": "L",
    "HRK": "kn",
    "HTG": "G",
    "HUF": "Ft",
    "IDR": "Rp",
    "ILS": "₪",
    "IMP": "£",
    "INR": "₹",
    "IQD": "ع.د",
    "IRR": "﷼",
    "ISK": "kr",
    "JEP": "£",
    "JMD": "J$",
    "JOD": "JD",
    "JPY": "¥",
    "KES": "KSh",
    "KGS": "лв",
    "KHR": "៛",
    "KMF": "CF",
    "KPW": "₩",
    "KRW": "₩",
    "KWD": "KD",
    "KYD": "$",
    "KZT": "лв",
    "LAK": "₭",
    "LBP": "£",
    "LKR": "₨",
    "LRD": "$",
    "LSL": "M",
    "LTC": "Ł",
    "LTL": "Lt",
    "LVL": "Ls",
    "LYD": "LD",
    "MAD": "MAD",
    "MDL": "lei",
    "MGA": "Ar",
    "MKD": "ден",
    "MMK": "K",
    "MNT": "₮",
    "MOP": "MOP$",
    "MRO": "UM",
    "MRU": "UM",
    "MUR": "₨",
    "MVR": "Rf",
    "MWK": "MK",
    "MXN": "$",
    "MYR": "RM",
    "MZN": "MT",
    "NAD": "$",
    "NGN": "₦",
    "NIO": "C$",
    "NOK": "kr",
    "NPR": "₨",
    "NZD": "$",
    "OMR": "﷼",
    "PAB": "B/.",
    "PEN": "S/.",
    "PGK": "K",
    "PHP": "₱",
    "PKR": "₨",
    "PLN": "zł",
    "PYG": "Gs",
    "QAR": "﷼",
    "RMB": "￥",
    "RON": "lei",
    "RSD": "Дин.",
    "RUB": "₽",
    "RWF": "R₣",
    "SAR": "﷼",
    "SBD": "$",
    "SCR": "₨",
    "SDG": "ج.س.",
    "SEK": "kr",
    "SGD": "$",
    "SHP": "£",
    "SLL": "Le",
    "SOS": "S",
    "SRD": "$",
    "SSP": "£",
    "STD": "Db",
    "STN": "Db",
    "SVC": "$",
    "SYP": "£",
    "SZL": "E",
    "THB": "฿",
    "TJS": "SM",
    "TMT": "T",
    "TND": "د.ت",
    "TOP": "T$",
    "TRL": "₤",
    "TRY": "₺",
    "TTD": "TT$",
    "TVD": "$",
    "TWD": "NT$",
    "TZS": "TSh",
    "UAH": "₴",
    "UGX": "USh",
    "USD": "$",
    "UYU": "$U",
    "UZS": "лв",
    "VEF": "Bs",
    "VND": "₫",
    "VUV": "VT",
    "WST": "WS$",
    "XAF": "FCFA",
    "XBT": "Ƀ",
    "XCD": "$",
    "XOF": "CFA",
    "XPF": "₣",
    "YER": "﷼",
    "ZAR": "R",
    "ZWD": "Z$",
}

# source: https://api.coingecko.com/api/v3/simple/supported_vs_currencies
SUPPORTED_CURRENCIES = [
    "btc",
    "eth",
    "ltc",
    "bch",
    "bnb",
    "eos",
    "xrp",
    "xlm",
    "link",
    "dot",
    "yfi",
    "usd",
    "aed",
    "ars",
    "aud",
    "bdt",
    "bhd",
    "bmd",
    "brl",
    "cad",
    "chf",
    "clp",
    "cny",
    "czk",
    "dkk",
    "eur",
    "gbp",
    "hkd",
    "huf",
    "idr",
    "ils",
    "inr",
    "jpy",
    "krw",
    "kwd",
    "lkr",
    "mmk",
    "mxn",
    "myr",
    "ngn",
    "nok",
    "nzd",
    "php",
    "pkr",
    "pln",
    "rub",
    "sar",
    "sek",
    "sgd",
    "thb",
    "try",
    "twd",
    "uah",
    "vef",
    "vnd",
    "zar",
    "xdr",
    "xag",
    "xau",
    "bits",
    "sats",
]
