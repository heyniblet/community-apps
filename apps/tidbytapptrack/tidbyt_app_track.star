"""Track new apps in Tidbyt's public app catalog."""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/tidbyt_logo.png", TIDBYT_LOGO_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_LOGO = TIDBYT_LOGO_ASSET.readall()
API_URL = "https://api.tidbyt.com/v0/apps"
NEW_APPS_CACHE_KEY = "NEW_APPS_CACHE_KEY"
KNOWN_APPS_CACHE_KEY = "KNOWN_APPS_CACHE_KEY"
TEAL_COLOR = "#78DECC"
PINK_COLOR = "#FFB4F5"
PURPLE_COLOR = "#7E8AF8"

def normalize_apps(value):
    if type(value) != "list":
        return []
    apps = []
    for app in value[:2000]:
        if type(app) != "dict" or app.get("private") == True:
            continue
        app_id = app.get("id")
        name = app.get("name")
        description = app.get("description")
        if type(app_id) != "string" or not app_id or len(app_id) > 128 or type(name) != "string":
            continue
        apps.append({
            "id": app_id,
            "name": name[:120],
            "description": description[:500] if type(description) == "string" else "",
        })
    return apps

def get_apps():
    response = http.get(API_URL, headers = {"Accept": "application/json"}, ttl_seconds = 3600)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 4194304:
        return []
    payload = json.decode(body, {})
    return normalize_apps(payload.get("apps") if type(payload) == "dict" else None)

def cached_apps(key):
    value = cache.get(key)
    return normalize_apps(json.decode(value, [])) if type(value) == "string" and len(value) <= 1048576 else []

def cached_ids():
    value = cache.get(KNOWN_APPS_CACHE_KEY)
    values = json.decode(value, []) if type(value) == "string" and len(value) <= 1048576 else []
    result = {}
    if type(values) == "list":
        for item in values[:2000]:
            app_id = item.get("id") if type(item) == "dict" else item
            if type(app_id) == "string" and len(app_id) <= 128:
                result[app_id] = True
    return result

def get_new_apps(apps):
    known = cached_ids()
    if not known:
        return []
    merged = {}
    for app in cached_apps(NEW_APPS_CACHE_KEY) + apps:
        if app["id"] not in known:
            merged[app["id"]] = app
    return merged.values()[:100]

def shorten_description(description):
    sentence = description.split(".")[0] + "."
    return sentence if len(sentence) <= 75 else sentence[:72] + "..."

def render_random(apps, count):
    choices = list(apps)
    children = []
    for _ in range(min(count, len(choices))):
        index = random.number(0, len(choices) - 1)
        app = choices.pop(index)
        children.append(render.Padding(child = render.Column(children = [
            render.WrappedText(app["name"], font = "tom-thumb", color = TEAL_COLOR, width = 46),
            render.WrappedText(shorten_description(app["description"]), font = "tom-thumb", color = PINK_COLOR, width = 46),
        ]), pad = (0, 0, 0, 1)))
    return children

def main(config):
    apps = get_apps()
    if not apps:
        return render.Root(child = render.WrappedText("Tidbyt catalog unavailable", width = 64, align = "center"))
    new_apps = get_new_apps(apps)
    cache.set(NEW_APPS_CACHE_KEY, json.encode(new_apps), ttl_seconds = 172800)
    cache.set(KNOWN_APPS_CACHE_KEY, json.encode([app["id"] for app in apps]), ttl_seconds = 2592000)

    header = render.Stack(children = [
        render.Box(width = 15, height = 32, color = "#000000"),
        render.Column(children = [
            render.Image(src = TIDBYT_LOGO, height = 8, width = 6),
            render.WrappedText("apps", font = "tom-thumb", width = 15),
            render.WrappedText(str(len(apps)), font = "tom-thumb", width = 15, color = TEAL_COLOR),
            render.WrappedText("new", font = "tom-thumb", width = 15),
            render.WrappedText(str(len(new_apps)), font = "tom-thumb", width = 15, color = TEAL_COLOR),
        ]),
    ])
    children = render_random(new_apps, 5) if config.bool("new_apps_first") else []
    children.extend(render_random(apps, 10))
    body = render.Marquee(width = 44, height = 128, offset_start = 8, scroll_direction = "vertical", child = render.Column(children = children))
    divider = render.Padding(render.Box(width = 1, height = 32, color = PURPLE_COLOR), pad = (1, 0, 1, 0))
    return render.Root(delay = 1, max_age = 3600, child = render.Row(children = [header, divider, body]))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Toggle(id = "new_apps_first", name = "New apps first", desc = "Display newly listed apps first.", icon = "seedling", default = False),
    ])
