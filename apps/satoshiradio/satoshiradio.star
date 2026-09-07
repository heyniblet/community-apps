"""
Applet: Satoshi Radio
Summary: SR mining pool stats
Description: Show pool and user stats for the Satoshi Radio mining pool.
Author: @redboer
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/logo.webp", LOGO_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

LOGO = LOGO_ASSET.readall()

DEFAULT_ADDRESS = ""
DEFAULT_TIMEFRAME = "hashrate5m"
DEFAULT_SHOW_POOL_HASHRATE = True
DEFAULT_SHOW_POOL_WORKERS = False
MAX_RESPONSE_BYTES = 32 * 1024

def parse_hashrate(value):
    value = str(value)
    number = re.sub(r"([A-Za-z])", "", value)
    unit = re.sub(r"(\d|\.)", "", value)[:4]
    if not re.match(r"^\d+(\.\d+)?$", number):
        return None
    return humanize.ftoa(float(number), 1), unit + "H"

def main(config):
    address = config.str("address", DEFAULT_ADDRESS).strip()
    if address and not re.match(r"^[A-Za-z0-9]{14,90}$", address):
        address = ""
    timeframe = config.get("timeframe", DEFAULT_TIMEFRAME)
    show_pool_hashrate = config.bool("show_pool_hashrate", DEFAULT_SHOW_POOL_HASHRATE)
    show_pool_workers = config.bool("show_pool_workers", DEFAULT_SHOW_POOL_WORKERS)

    info = []

    if address:
        user = user_data(address)
        if user.get("error"):
            render_info(info, False, "", user.get("error"))
        else:
            hashrate = parse_hashrate(user.get(timeframe, "0"))
            if hashrate:
                render_info(info, True, hashrate[0], hashrate[1])
            else:
                render_info(info, True, "?", "H")

    if show_pool_hashrate or show_pool_workers:
        pool = pool_data()

        if pool.get("error"):
            render_info(info, False, "", pool.get("error"))
        else:
            if show_pool_hashrate:
                hashrate = parse_hashrate(pool.get(timeframe, "0"))
                if hashrate:
                    render_info(info, (address == ""), hashrate[0], hashrate[1])
                else:
                    render_info(info, (address == ""), "?", "H")
            if show_pool_workers:
                workers = pool.get("Workers")
                render_info(info, False, humanize.ftoa(float(workers)) if type(workers) in ["int", "float"] else "?", "W")

    if not address and not show_pool_hashrate and not show_pool_workers:
        render_info(info, False, "Satoshi", "")
        render_info(info, False, "", "Radio")

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = LOGO),
                render.Column(
                    children = info,
                    main_align = "center",
                    expanded = True,
                ),
            ],
            expanded = True,
        ),
    )

def render_info(info, big, number, unit):
    if big:
        font_number = "Dina_r400-6"
        font_unit = "5x8"
        font_height = 9
    else:
        font_number = "tom-thumb"
        font_unit = "tom-thumb"
        font_height = 6

    info.append(
        render.Padding(
            child = render.Row(
                children = [
                    render.Text(number, font = font_number),
                    render.Box(width = 1, height = 1),
                    render.Text(unit, height = font_height, font = font_unit, color = "#abc"),
                ],
                main_align = "end",
                expanded = True,
            ),
            pad = (0, 0, 1, 0),
        ),
    )

def pool_data():
    return get_data("https://pool.satoshiradio.nl/api/v1/pool", 3600, "API error")

def user_data(address):
    return get_data("https://pool.satoshiradio.nl/api/v1/users/%s" % humanize.url_encode(address), 300, "no user")

def get_data(url, ttl_seconds, error):
    res = http.get(url, ttl_seconds = ttl_seconds)
    body = res.body()
    data = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return data if type(data) == "dict" else {"error": error}

def get_schema():
    options = [
        schema.Option(
            display = "1 minute",
            value = "hashrate1m",
        ),
        schema.Option(
            display = "5 minutes",
            value = "hashrate5m",
        ),
        schema.Option(
            display = "1 hour",
            value = "hashrate1hr",
        ),
        schema.Option(
            display = "1 day",
            value = "hashrate1d",
        ),
        schema.Option(
            display = "7 days",
            value = "hashrate7d",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "address",
                name = "User bitcoin address",
                desc = "Leave empty for pool only",
                icon = "bitcoin",
                default = "",
            ),
            schema.Dropdown(
                id = "timeframe",
                name = "Stats timeframe",
                desc = "Timeframe to use for hashrate stats.",
                icon = "clock",
                default = options[1].value,
                options = options,
            ),
            schema.Toggle(
                id = "show_pool_hashrate",
                name = "Pool hashrate",
                desc = "Show pool hashrate",
                icon = "gauge",
                default = True,
            ),
            schema.Toggle(
                id = "show_pool_workers",
                name = "Pool workers",
                desc = "Show pool workers",
                icon = "microchip",
                default = False,
            ),
        ],
    )
