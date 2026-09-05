"""
Applet: Beli Feed
Summary: Displays activity from Beli
Description: Displays activity from your friends on Beli (beliapp.com).
Author: leoadberg
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def Text(text, **kwargs):
    return render.Text(content = str(text), **kwargs)

def WrappedText(text, **kwargs):
    return render.WrappedText(content = str(text), **kwargs)

def Marquee(child, **kwargs):
    return render.Marquee(child = child, **kwargs)

def Row(*children, **kwargs):
    return render.Row(children = list(children), **kwargs)

def Column(*children, **kwargs):
    return render.Column(children = list(children), **kwargs)

def Animation(*children):
    return render.Animation(children = list(children))

def Box(child):
    return render.Box(child = child)

def Stack(*children):
    return render.Stack(children = list(children))

def Pad(child, pad):
    return render.Padding(child = child, pad = pad)

DEFAULT_WHO = "lad"

modes = [
    schema.Option(
        display = "My Activity",
        value = "mine",
    ),
    schema.Option(
        display = "My Friends' Activity",
        value = "friends",
    ),
]

orderings = [
    schema.Option(
        display = "Most Recent",
        value = "recent",
    ),
    schema.Option(
        display = "Random",
        value = "random",
    ),
]

API = "https://backoffice-service-t57o3dxfca-nn.a.run.app/api/"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_ITEMS = 200
MAX_TEXT_LENGTH = 240

def get(path, api_token):
    response = http.get(API + path, headers = {"Authorization": "Bearer " + api_token})
    if response.status_code != 200:
        return None
    body = response.body()
    return json.decode(body) if len(body) <= MAX_RESPONSE_BYTES else None

def username_to_id(user, api_token):
    data = get("user/member/?username__iexact=" + humanize.url_encode(user), api_token)

    results = data.get("results") if type(data) == "dict" else None
    if type(results) != "list" or len(results) != 1 or type(results[0]) != "dict":
        return None
    user_id = results[0].get("id")
    return str(user_id) if type(user_id) in ["string", "int"] else None

def renderRating(rating):
    if rating == -1:
        s = "?"
        color = "#fff"
    else:
        rating = math.round(rating * 10) / 10
        s = str(rating)
        if s[:2] == "10":
            s = "10"
        if rating >= 6.7:
            color = "#0f0"
        elif rating >= 3.5:
            color = "#fe1"
        else:
            color = "#f00"

    return Stack(
        Pad(render.Circle(color = "#fff", diameter = 15), (49, 17, 0, 0)),
        Pad(render.Circle(color = "#111", diameter = 13), (50, 18, 0, 0)),
        Pad(Text(s, color = color), (51, 21, 0, 0)),
    )

def getFriendsActivity(id, cutoff, index, api_token):
    data = get("newsfeed-old/" + id + "/?max_items=30", api_token)
    scores = get("newsfeed-scores/" + id, api_token)
    results = data.get("results") if type(data) == "dict" else None
    if type(results) != "list" or type(scores) != "list":
        return None
    scoremap = {}
    for score in scores[:MAX_ITEMS]:
        if type(score) == "dict" and type(score.get("user_id")) == "string" and type(score.get("business_id")) in ["string", "int"] and type(score.get("value")) in ["int", "float"]:
            scoremap[score["user_id"] + str(score["business_id"])] = score["value"]

    results = [x for x in results[:MAX_ITEMS] if type(x) == "dict" and x.get("event_type") == "ADD"]
    if cutoff > 0:
        results = [x for x in results if type(x.get("sent_dt")) == "string" and len(x["sent_dt"]) <= 40 and (time.now() - time.parse_time(x["sent_dt"])) < time.minute * cutoff]

    if len(results) == 0:
        return None

    item = results[index % len(results)]

    text = item.get("body")
    parts = text.split(" ranked ") if type(text) == "string" else []
    if len(parts) != 2:
        return None
    user, business = parts
    user = user[:MAX_TEXT_LENGTH]
    business = business[:MAX_TEXT_LENGTH]

    key = str(item.get("user1", "")) + str(item.get("business", ""))
    rating = -1
    if key in scoremap:
        rating = scoremap[key]

    return Stack(
        Column(
            Marquee(Text(user, color = "#8ff"), width = 64),
            Text("ranked", color = "#aaa"),
            WrappedText(business, width = 52),
        ),
        renderRating(rating),
    )

def getMyActivity(id, cutoff, index, api_token):
    profile_data = get("user/member/?id=" + id, api_token)
    rank_data = get("rank-list/" + id, api_token)
    profiles = profile_data.get("results") if type(profile_data) == "dict" else None
    data = rank_data.get("results") if type(rank_data) == "dict" else None
    if type(profiles) != "list" or not profiles or type(profiles[0]) != "dict" or type(data) != "list":
        return None
    profile = profiles[0]
    data = [item for item in data[:MAX_ITEMS] if type(item) == "dict" and type(item.get("created_dt")) == "string"]
    data = sorted(data, key = lambda x: x["created_dt"], reverse = True)

    first_name = profile.get("first_name")
    last_name = profile.get("last_name")
    if type(first_name) != "string" or type(last_name) != "string":
        return None
    name = (first_name + " " + last_name)[:MAX_TEXT_LENGTH]

    if cutoff > 0:
        data = [x for x in data if (time.now() - time.parse_time(x["created_dt"])) < time.minute * cutoff]

    if len(data) == 0:
        return None

    item = data[index % len(data)]
    business = item.get("business__name")
    score = item.get("score")
    if type(business) != "string" or type(score) not in ["int", "float"]:
        return None
    return Stack(
        Column(
            Marquee(Text(name, color = "#8ff"), width = 64),
            Text("ranked", color = "#aaa"),
            WrappedText(business[:MAX_TEXT_LENGTH], width = 52),
        ),
        renderRating(score),
    )

def main(config):
    api_token = config.get("api_token")
    if type(api_token) != "string" or not api_token or len(api_token) > 2048 or "\r" in api_token or "\n" in api_token:
        return render.Root(child = WrappedText("Beli API token required", width = 64, align = "center"))

    user = config.get("user") or DEFAULT_WHO
    if type(user) != "string" or not user or len(user) > 80:
        return render.Root(child = WrappedText("Invalid Beli username", width = 64, align = "center"))
    id = username_to_id(user, api_token)
    if not id:
        return render.Root(child = Text("Unknown user"))

    mode = config.str("mode", modes[0].value)
    order = config.str("order", orderings[0].value)
    if mode not in [option.value for option in modes]:
        mode = modes[0].value
    if order not in [option.value for option in orderings]:
        order = orderings[0].value
    cutoff_str = config.str("time", "0")
    cutoff = 0
    if cutoff_str.isdigit():
        cutoff = min(int(cutoff_str), 525600)

    indexkey = "beli:" + user + ":" + mode + ":" + order + ":" + str(cutoff)
    cached_index = cache.get(indexkey) or "0"
    index = int(cached_index) if cached_index.isdigit() else 0

    cache.set(indexkey, str(index + 1), 600)  # Keep position in list for 10m

    if order == "random":
        index = random.number(0, 100000)

    if mode == "mine":
        frame = getMyActivity(id, cutoff, index, api_token)
    else:
        frame = getFriendsActivity(id, cutoff, index, api_token)

    if frame == None:
        return []

    return render.Root(delay = 100, child = frame)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user",
                name = "Beli Username",
                desc = "Your username on Beli",
                icon = "user",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "Which activity to display",
                icon = "peopleGroup",
                default = modes[0].value,
                options = modes,
            ),
            schema.Dropdown(
                id = "order",
                name = "Ordering",
                desc = "Order to show activity",
                icon = "arrowUpWideShort",
                default = orderings[0].value,
                options = orderings,
            ),
            schema.Text(
                id = "time",
                name = "Time Cutoff",
                desc = "Only display ratings within the last N minutes. The app will be skipped if there are none. '0' or any non-number will show ratings from any time.",
                icon = "clock",
                default = "0",
            ),
            schema.Text(
                id = "api_token",
                name = "Beli API token",
                desc = "Bearer token for Beli's authenticated API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
