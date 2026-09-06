load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://shouldideploy.today/api"

DEFAULT_LOCATION = json.encode({"timezone": "UTC"})
DEFAULT_DESIGN = "thumbs"

DESIGNS = {
    "thumbs": {
        True: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f44d.png",
            "color": "#144E00",
        },
        False: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f44e.png",
            "color": "#B41414",
        },
    },
    "symbols": {
        True: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/2705.png",
            "color": "#000000",
        },
        False: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/274c.png",
            "color": "#000000",
        },
    },
    "error": {
        "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/2049-fe0f.png",
        "color": "#000000",
    },
}

def main(config):
    design = config.get("design-choice", DEFAULT_DESIGN)
    if design not in ["thumbs", "symbols"]:
        design = DEFAULT_DESIGN

    location_cfg = config.get("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg, {}) if type(location_cfg) == "string" and len(location_cfg) <= 4096 else {}
    timezone = location.get("timezone", "UTC") if type(location) == "dict" else "UTC"
    if type(timezone) != "string" or len(timezone) > 100 or (timezone != "UTC" and not re.match(r"^[A-Za-z0-9_+.-]+(/[A-Za-z0-9_+.-]+)+$", timezone)):
        timezone = "UTC"

    image_to_use = None
    color_to_use = None

    resp = http.get(API_URL, params = {"tz": timezone}, ttl_seconds = 120)
    body = resp.body()
    data = json.decode(body, {}) if body and len(body) <= 16 * 1024 else {}
    if resp.status_code != 200 or type(data) != "dict":
        error = data.get("error", {}) if type(data) == "dict" else {}
        error_message = error.get("message", "") if type(error) == "dict" else ""
        if type(error_message) == "string" and "does not exist" in error_message:
            image_to_use = DESIGNS["error"]["url"]
            color_to_use = DESIGNS["error"]["color"]
            data = {"shouldideploy": False, "message": "Timezone '%s' is not supported" % timezone}
        else:
            data = {"shouldideploy": False, "message": "Deployment advice unavailable"}

    shouldideploy = data.get("shouldideploy")
    message = data.get("message")
    if type(shouldideploy) != "bool" or type(message) != "string":
        shouldideploy = False
        message = "Deployment advice unavailable"
    message = message[:300]
    image_to_use = image_to_use or DESIGNS[design][shouldideploy]["url"]
    color_to_use = color_to_use or DESIGNS[design][shouldideploy]["color"]

    image_response = http.get(image_to_use, ttl_seconds = 86400)
    image = image_response.body()
    if image_response.status_code != 200 or not image or len(image) > 512 * 1024 or not image_response.headers.get("Content-Type", "").lower().startswith("image/"):
        return render.Root(child = render.WrappedText(message, width = 64, align = "center"))

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(
                        width = 24,
                        height = 24,
                        src = image,
                    ),
                    render.Marquee(
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        child = render.Text(
                            message,
                            font = "tom-thumb",
                        ),
                        align = "center",
                    ),
                ],
            ),
            color = color_to_use,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to determine ideal deployment.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "design-choice",
                name = "Thumbs or Symbols",
                desc = "Use thumbs with background color or Symbols with no background color",
                icon = "wandMagicSparkles",
                default = "thumbs",
                options = [
                    schema.Option(
                        display = "Thumbs",
                        value = "thumbs",
                    ),
                    schema.Option(
                        display = "Symbols",
                        value = "symbols",
                    ),
                ],
            ),
        ],
    )
