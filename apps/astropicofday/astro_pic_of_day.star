# Modified in this community-maintained version; see Git history for contributors.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Astro Pic of Day
Summary: New pic from NASA each day
Description: Displays the astronomy picture of the day from NASA.
Author: Brian Bell
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/nasa_logo.png", NASA_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NASA_LOGO = NASA_LOGO_ASSET.readall()

# NASA moved APOD to science.nasa.gov; api.nasa.gov/planetary/apod now answers
# 500 or a "NASA Science" logo placeholder. This endpoint needs no key and
# lists the newest picture first.
APOD_URL = "https://science.nasa.gov/wp-json/wp/v2/apod-basic"

# NASA's image service resizes on request, so the display never downloads the
# full-size picture. Twice the 32 pixel height keeps detail when scaled.
IMAGE_HOST = "https://assets.science.nasa.gov/"
IMAGE_SIZE = "?w=512&h=64&fit=clip"

TTL_SECONDS = 3600

def main(config):
    display_info = config.bool("display_info")
    apod = get_apod(
        APOD_URL,
        TTL_SECONDS,
    )
    title = apod["title"]
    image_src = base64.decode(apod["image_src"])

    children = [
        render.Column(
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Image(
                            src = image_src,
                            height = 32,
                        ),
                    ],
                ),
            ],
        ),
    ]

    if display_info:
        children.append(
            animation.Transformation(
                child = render.Box(
                    child = render.Box(
                        color = "#00000099",
                        width = 64,
                        child = render.Column(
                            cross_align = "center",
                            children = [
                                render.Image(
                                    src = NASA_LOGO,
                                    height = 8,
                                ),
                                render.Padding(
                                    pad = (1, 2, 1, 0),
                                    child = render.WrappedText(
                                        align = "center",
                                        content = title,
                                        font = "tom-thumb",
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                delay = 70,
                direction = "alternate",
                duration = 50,
                fill_mode = "forwards",
                origin = animation.Origin(0.5, 0.5),
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(0, 32)],
                        curve = "ease_in_out",
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [animation.Translate(0, 0)],
                    ),
                ],
            ),
        )
    return render.Root(
        child = render.Stack(
            children = children,
        ),
    )

def get_apod(url, ttl_seconds):
    # Return the newest astronomy picture of the day
    entries = get_entries(url, ttl_seconds)
    if type(entries) != "list" or len(entries) == 0 or type(entries[0]) != "dict":
        fail("NASA APOD response did not include a picture")
    apod = entries[0]
    image_url = small_image_url(apod.get("hdurl") or "")
    if not image_url or not apod.get("title"):
        fail("NASA APOD response did not include a displayable image")
    apod["image_src"] = base64.encode(get_image_src(image_url, ttl_seconds))

    return apod

def get_entries(url, ttl_seconds):
    response = http.get(url = url, params = {"per_page": "1"}, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    return response.json()

def small_image_url(url):
    # Video days carry a still in the same field. A few entries list only a
    # 48 pixel rendition under content/dam; the image service has the original.
    if not url.startswith(IMAGE_HOST):
        return url
    path = url[len(IMAGE_HOST):].split("?")[0].split("/jcr:content/")[0]
    if path.startswith("content/dam/"):
        path = "dynamicimage/assets/" + path[len("content/dam/"):]
    if not path.startswith("dynamicimage/"):
        return url
    return IMAGE_HOST + path + IMAGE_SIZE

def get_image_src(url, ttl_seconds):
    # Return and cache image data from url provided
    response = http.get(url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    image_src = response.body()
    return image_src

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "display_info",
                name = "Display Info?",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
        ],
    )
