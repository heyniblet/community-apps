"""
Applet: Unsplash
Summary: Shows random photos
Description: Displays a random image from Unsplash.
Author: zephyern, gabe565
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_CACHE_MINS = 5

UNSPLASH_URL = "https://api.unsplash.com"
DEFAULT_IMAGE_URL = "https://images.unsplash.com/photo-1645069258059-6f5a71256c4a"

def parse_imgix_params(raw):
    if type(raw) != "string" or not raw or len(raw) > 512:
        return {}

    params = {}
    for entry in raw.split("&")[:20]:
        item = entry.strip()
        if not item or "=" not in item:
            continue
        key, value = item.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key and len(key) <= 32 and len(value) <= 128 and all([char.isalnum() or char in "_-" for char in key.elems()]):
            params[key] = value

    return params

def get_topic_id(slug, key):
    if len(slug) > 64 or not all([char.isalnum() or char in "_-" for char in slug.elems()]):
        return None
    cache_key = "topic:" + slug
    id = cache.get(cache_key)
    if id:
        return id

    res = http.get(
        UNSPLASH_URL + "/topics/" + slug,
        headers = {
            "Accept-Version": "v1",
            "Authorization": "Client-ID %s" % key,
        },
    )

    if res.status_code != 200:
        return None

    data = res.json()
    id = data.get("id") if type(data) == "dict" else None
    if type(id) != "string" or len(id) > 128:
        return None
    cache.set(cache_key, id, ttl_seconds = 86400)
    return id

def get_image(url, params = {}, ttl_seconds = DEFAULT_CACHE_MINS * 60):
    if type(url) != "string" or not url.startswith("https://images.unsplash.com/"):
        return None
    if "fit" not in params:
        params["fit"] = "crop"
    if "crop" not in params:
        params["crop"] = "edges"
    params["w"] = str(canvas.width())
    params["h"] = str(canvas.height())
    params["fm"] = "png"

    res = http.get(url, params = params, ttl_seconds = ttl_seconds)

    if res.status_code != 200:
        return None

    return res.body()

def main(config):
    cache_mins_str = config.str("cache_mins", str(DEFAULT_CACHE_MINS))
    cache_mins = int(cache_mins_str) if cache_mins_str.isdigit() else DEFAULT_CACHE_MINS
    cache_mins = max(1, min(cache_mins, 1440))
    cache_sec = cache_mins * 60

    image = None
    image_params = parse_imgix_params(config.get("imgix_params"))

    key = bounded_text(config.get("unsplash_access_key"), 256)
    if key:
        topics_raw = bounded_text(config.get("topics"), 512)
        topics = [get_topic_id(v.strip(), key) for v in topics_raw.split(",")[:10] if v.strip()] if topics_raw else []
        topics = [id for id in topics if id]
        params = {
            "orientation": "landscape",
            "collections": bounded_text(config.get("collections"), 512),
            "topics": ",".join(topics),
            "username": bounded_text(config.get("username"), 100),
            "query": bounded_text(config.get("query"), 200),
            "content_filter": config.get("content_filter") if config.get("content_filter") in ["low", "high"] else "low",
        }
        params = {k: v for k, v in params.items() if v}
        res = http.get(
            UNSPLASH_URL + "/photos/random",
            headers = {
                "Accept-Version": "v1",
                "Authorization": "Client-ID %s" % key,
            },
            params = params,
        )

        if res.status_code == 200:
            data = res.json()
            urls = data.get("urls") if type(data) == "dict" else None
            image_url = urls.get("raw") if type(urls) == "dict" else None
            image = get_image(image_url, params = image_params, ttl_seconds = cache_sec)

    if not image:
        image = get_image(DEFAULT_IMAGE_URL, params = image_params, ttl_seconds = cache_sec)
    if not image:
        return render.Root(child = render.WrappedText("Could not load Unsplash image", width = canvas.width(), align = "center"))

    return render.Root(
        child = render.Image(src = image),
    )

def bounded_text(value, limit):
    return value[:limit] if type(value) == "string" else ""

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "unsplash_access_key",
                name = "Access Key",
                desc = "Your Unsplash API Access Key. See https://unsplash.com/developers for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "query",
                name = "Query",
                desc = "Limit selection to photos matching a search term.",
                icon = "magnifyingGlass",
                default = "",
            ),
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Limit selection to a single user.",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "collections",
                name = "Collections",
                desc = "Comma-separated collection IDs to filter selection. To find the ID, open a collection and copy the numbers in the URL.",
                icon = "folderTree",
                default = "",
            ),
            schema.Text(
                id = "topics",
                name = "Topics",
                desc = "Comma-separated topic slugs to filter selection. To find the slug, open a topic and copy the last part of the URL.",
                icon = "shapes",
                default = "",
            ),
            schema.Dropdown(
                id = "content_filter",
                name = "Content Filter",
                desc = "Limit results by content safety. See https://unsplash.com/documentation#content-safety for details.",
                icon = "filter",
                default = "low",
                options = [
                    schema.Option(
                        display = "Low",
                        value = "low",
                    ),
                    schema.Option(
                        display = "High",
                        value = "high",
                    ),
                ],
            ),
            schema.Text(
                id = "imgix_params",
                name = "Imgix Render Params",
                desc = "Query parameters to pass to Imgix. See https://docs.imgix.com/apis/rendering for details. (e.g. \"con=20&sat=20\")",
                icon = "image",
                default = "",
            ),
            schema.Text(
                id = "cache_mins",
                name = "Cache Duration",
                desc = "How long to cache images (in minutes)",
                icon = "clock",
                default = str(DEFAULT_CACHE_MINS),
            ),
        ],
    )
