"""
Applet: SF Fog Today
Summary: Satellite fog info for SF
Description: Displays GOES-16 satellite fog image for San Francisco, from fog.today.
Author: Matt Broussard
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://fog.today/"
MAX_PAGE_BYTES = 128 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024
MAX_ANIMATION_FRAMES = 12

def main(config):
    mode = config.get("mode", "current")
    if mode not in ["current", "short_list", "long_list"]:
        mode = "current"
    zoom_out = config.bool("zoom_out", False)
    if zoom_out:
        params = {"img_native_res": (1600, 2048), "img_native_origin": (600, 675), "img_display_scale": 0.35}
    else:
        params = {"img_native_res": (1600, 2048), "img_native_origin": (628, 675), "img_display_scale": 0.5}

    if mode == "current":
        image_src = load_image(image_url = BASE_URL + "current.jpg")
        if not image_src:
            return render.Root(
                child = render.WrappedText("Error loading fog.today :("),
            )

        return render.Root(
            child = render_image(image_src, **params),
        )

    else:
        image_urls = get_image_urls(mode)
        if not image_urls:
            return render.Root(child = render.WrappedText("Error loading fog.today :("))
        image_src_list = [load_image(image_url) for image_url in image_urls]
        if None in image_src_list:
            return render.Root(
                child = render.WrappedText("Error loading fog.today :("),
            )

        return render.Root(
            child = render.Animation(
                children = [render_image(image_src, **params) for image_src in image_src_list],
            ),
            delay = 300,
            show_full_animation = True,  # account for fog.today not having a fixed count of images in the cycle
        )

def get_image_urls(mode):
    resp = http.get(BASE_URL, ttl_seconds = 300)
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_PAGE_BYTES:
        return None

    lists = re.findall(r"var {} = \[(.*)\]".format(mode), body)
    if len(lists) == 0:
        return None
    image_paths_raw = lists[0]
    image_paths = re.findall(r"images/.*?\.jpg", image_paths_raw)
    if len(image_paths) > MAX_ANIMATION_FRAMES:
        step = (len(image_paths) + MAX_ANIMATION_FRAMES - 1) // MAX_ANIMATION_FRAMES
        image_paths = [image_paths[index] for index in range(0, len(image_paths), step)][:MAX_ANIMATION_FRAMES]
    image_urls = [BASE_URL + image_path for image_path in image_paths]
    return image_urls

def load_image(image_url):
    if type(image_url) != "string" or not image_url.startswith(BASE_URL):
        return None
    resp = http.get(image_url, ttl_seconds = 300)
    body = resp.body()
    return body if resp.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else None

def render_image(image_src, img_native_res, img_native_origin, img_display_scale):
    return render.Padding(
        child = render.Image(
            src = image_src,
            width = int(img_native_res[0] * img_display_scale),
            height = int(img_native_res[1] * img_display_scale),
        ),
        pad = (
            -int(img_native_origin[0] * img_display_scale),
            -int(img_native_origin[1] * img_display_scale),
            0,
            0,
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Latest image",
            value = "current",
        ),
        schema.Option(
            display = "2 hour loop",
            value = "short_list",
        ),
        schema.Option(
            display = "24 hour loop",
            value = "long_list",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "The timeframe of images to be displayed",
                icon = "gear",
                default = options[0].value,
                options = options,
            ),
            schema.Toggle(
                id = "zoom_out",
                name = "Zoom out",
                desc = "Display a zoomed out view of the map",
                icon = "magnifyingGlass",
                default = False,
            ),
        ],
    )
