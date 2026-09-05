"""
Applet: Random Cats
Summary: Shows pictures of cats
Description: Shows random pictures of cats/gifs of cats from Cats as a Service (cataas.com).
Author: mrrobot245
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

MAX_IMAGE_BYTES = 4 * 1024 * 1024
TTL_SECONDS = 300

def main(config):
    height = canvas.height()
    width = canvas.width()

    cat_type = "/gif" if config.bool("gifs", True) else ""
    url = "https://cataas.com/cat{}?width={}&height={}".format(cat_type, width, height)

    # Preview
    # url = https://cataas.com/cat/vHWxUr3RH8Gp0bke?height=" + str(height)

    imgSrc = get_cached(url)
    if imgSrc == None:
        return render.Root(child = render.WrappedText(content = "Cat unavailable", align = "center"))

    return render.Root(
        child = render.Box(
            child = render.Image(
                src = imgSrc,
                height = height,
            ),
        ),
    )

def get_cached(url, ttl_seconds = TTL_SECONDS):
    res = http.get(url, ttl_seconds = ttl_seconds)
    body = res.body()
    return body if res.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "gifs",
                name = "Animated Gifs",
                desc = "Show Animated Gifs",
                icon = "codeFork",
                default = True,
            ),
        ],
    )
