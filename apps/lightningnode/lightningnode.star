"""Show public Bitcoin Lightning network or node statistics."""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://mempool.space/api/v1/lightning"
SATS_IN_BITCOIN = 100000000
LABEL_COLOR = "#fff9"
LABEL_FONT = "tb-8"

NETWORK_OPTIONS = [
    ("Nodes", "nodes"),
    ("Channels", "channels"),
    ("Capacity", "capacity"),
    ("Average", "average"),
    ("Median", "median"),
    ("Avg Fee Rate", "avg_fee_rate"),
    ("Avg Base Fee", "avg_base_fee"),
    ("-empty-", "empty"),
]
NODE_OPTIONS = [
    ("Alias", "alias"),
    ("Capacity", "capacity"),
    ("Channels", "channels"),
    ("Sunrise", "sunrise"),
    ("Updated", "updated"),
    ("-empty-", "empty"),
]

def fetch_json(path):
    response = http.get(API_URL + path, headers = {"Accept": "application/json"}, ttl_seconds = 3600)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 1048576:
        return None
    value = json.decode(body, None)
    return value if type(value) == "dict" else None

def number(value):
    if type(value) in ["int", "float"] and value >= 0:
        return int(value)
    if type(value) == "string" and len(value) <= 24 and value.isdigit():
        return int(value)
    return 0

def valid_pubkey(value):
    if len(value) != 66 or value[:2] not in ["02", "03"]:
        return False
    chars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    return all([value[i].lower() in chars for i in range(len(value))])

def network_values(interval):
    payload = fetch_json("/statistics/" + interval)
    data = payload.get("latest") if payload != None else None
    if type(data) != "dict":
        return None
    return {
        "nodes": ("nodes", humanize.comma(number(data.get("node_count")))),
        "channels": ("channels", humanize.comma(number(data.get("channel_count")))),
        "capacity": ("capacity", humanize.comma(int(number(data.get("total_capacity")) / SATS_IN_BITCOIN)) + " BTC"),
        "average": ("average", humanize.comma(number(data.get("avg_capacity"))) + " sats"),
        "median": ("median", humanize.comma(number(data.get("med_capacity"))) + " sats"),
        "avg_fee_rate": ("avg fee rate", humanize.comma(number(data.get("avg_fee_rate"))) + " ppm"),
        "avg_base_fee": ("avg base fee", humanize.comma(number(data.get("avg_base_fee_mtokens"))) + " mSats"),
        "empty": ("", ""),
    }

def node_values(pubkey):
    data = fetch_json("/nodes/" + pubkey)
    if data == None:
        return None
    return {
        "alias": ("alias", str(data.get("alias") or "Unknown")[:80]),
        "capacity": ("capacity", humanize.ftoa(number(data.get("capacity")) / float(SATS_IN_BITCOIN), 2) + " BTC"),
        "channels": ("channels", humanize.comma(number(data.get("active_channel_count")))),
        "sunrise": ("sunrise", humanize.time(time.from_timestamp(number(data.get("first_seen"))))),
        "updated": ("updated", humanize.time(time.from_timestamp(number(data.get("updated_at"))))),
        "empty": ("", ""),
    }

def stat(value):
    return render.Column(children = [
        render.Text(value[0], font = LABEL_FONT, color = LABEL_COLOR),
        render.Text(value[1]),
    ])

def display(values, primary, secondary, animate):
    if values == None:
        return render.WrappedText("Lightning data unavailable", width = 64, align = "center")
    if animate:
        frames = [stat(value) for key, value in values.items() if key != "empty"]
        return render.Column(children = [render.Animation(children = frames)], main_align = "space_around", expanded = True)
    selected = [values.get(primary, values["empty"])]
    if secondary != "empty":
        selected.append(values.get(secondary, values["empty"]))
    return render.Column(children = [stat(value) for value in selected], expanded = True, main_align = "center")

def main(config):
    pubkey = config.str("node_pubkey", "").strip()
    animate = config.bool("will_animate", True)
    if pubkey and not valid_pubkey(pubkey):
        return render.Root(child = render.WrappedText("Invalid node pubkey", width = 64, align = "center"))
    if pubkey:
        values = node_values(pubkey)
        child = display(values, config.str("node_data_primary", "alias"), config.str("node_data_secondary", "capacity"), animate)
    else:
        interval = config.str("interval", "latest")
        interval = "24h" if interval == "1d" else interval
        allowed = ["latest", "24h", "3d", "1w", "1m", "3m", "6m", "1y", "2y", "3y"]
        interval = interval if interval in allowed else "latest"
        values = network_values(interval)
        child = display(values, config.str("network_data_primary", "nodes"), config.str("network_data_secondary", "channels"), animate)
    return render.Root(delay = 1200, show_full_animation = True, max_age = 3600, child = child)

def dropdown(field_id, name, options, default, icon):
    return schema.Dropdown(
        id = field_id,
        name = name,
        desc = "Choose the statistic to display.",
        default = default,
        options = [schema.Option(display = label, value = value) for label, value in options],
        icon = icon,
    )

def get_schema():
    intervals = [("Latest", "latest"), ("1 day", "24h"), ("3 days", "3d"), ("1 week", "1w"), ("1 month", "1m"), ("3 months", "3m"), ("6 months", "6m"), ("1 year", "1y"), ("2 years", "2y"), ("3 years", "3y")]
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "node_pubkey", name = "Node pubkey (optional)", desc = "Public 66-character node key; leave empty for network statistics.", icon = "key"),
        dropdown("interval", "Network interval", intervals, "latest", "clock"),
        dropdown("network_data_primary", "Network top row", NETWORK_OPTIONS, "nodes", "1"),
        dropdown("network_data_secondary", "Network bottom row", NETWORK_OPTIONS, "channels", "2"),
        dropdown("node_data_primary", "Node top row", NODE_OPTIONS, "alias", "1"),
        dropdown("node_data_secondary", "Node bottom row", NODE_OPTIONS, "capacity", "2"),
        schema.Toggle(id = "will_animate", name = "Animate all stats?", desc = "Animate every statistic instead of the selected rows.", icon = "clapperboard", default = True),
    ])
