"""
Applet: Geeky Hotness
Summary: Geeky Hotness
Description: Shows the top items from BoardGameGeek's Board Game Hotness list. Powered by BGG.
Author: Henry So, Jr.
"""

# Geeky Hotness - Powered by BGG
#
# Copyright (c) 2022, 2025 Henry So, Jr.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# This app uses the BoardGameGeek XML API 2
# (https://boardgamegeek.com/wiki/page/BGG_XML_API2)
# to show BoardGameGeek's Board Game Hotness list

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/logo.png", LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

LOGO = LOGO_ASSET.readall()

def main(config):
    api_key = config.get("bgg_api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return render.Root(child = render.WrappedText(content = "BGG API token required", align = "center"))

    now = time.now().unix

    data = cache.get(KEY)
    data = json.decode(data, None) if data else None
    data = data if valid_cached_data(data) else None

    if not data or (now - data["timestamp"]) > EXPIRY:
        content = http.get(URL, headers = {"Authorization": "Bearer %s" % api_key})
        if content.status_code == 200:
            body = content.body()
            content = xpath.loads(body) if body and len(body) <= MAX_XML_BYTES else None
        else:
            content = None
        if content:
            content = {
                "timestamp": now,
                "list": [
                    {
                        "name": "%d. %s (%s)" % (
                            rank,
                            str(content.query(NAME_PATH_FMT % rank) or "{no name}")[:120],
                            str(content.query(YEAR_PATH_FMT % rank) or "????")[:8],
                        ),
                        "image_url": content.query(IMAGE_PATH_FMT % rank),
                    }
                    for rank in RANKS
                ],
            }

            loaded = {
                d["image_url"]: d["image"]
                for d in data["list"]
                if "image_url" in d and "image" in d
            } if data else {}

            for c in content["list"]:
                image_url = c["image_url"]
                if image_url:
                    image = loaded.get(image_url) or get_image(image_url)
                    if image:
                        c["image"] = image
            data = content

            cache.set(KEY, json.encode(data), TTL)

    if not data:
        # dummy data
        data = {
            "timestamp": now,
            "list": [
                {
                    "name": "Failed to retrieve the BoardGameGeek hotness",
                }
                for rank in RANKS
            ],
        }

    hotness = data["list"]

    for h in hotness:
        image = h.get("image")
        if image:
            h["image"] = base64.decode(image)

    hotness = [data_frame(i, h) for i, h in enumerate(hotness)]
    logo_frame = render.Image(
        width = WIDTH,
        height = HEIGHT,
        src = LOGO,
    )

    frames = []
    for i, h in enumerate(hotness):
        frames.extend([h] * PAUSE_F)
        frames.extend(scroll_frames(h, hotness[i + 1] if i + 1 < COUNT else logo_frame))
    frames.extend([logo_frame] * (PAUSE_F // 2))

    return render.Root(
        delay = DELAY_MS,
        child = render.Animation(frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bgg_api_key",
                name = "BoardGameGeek API Key",
                desc = "Your BoardGameGeek API key. See https://boardgamegeek.com/wiki/page/BGG_XML_API2 for details.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def get_image(url):
    if type(url) == "string" and url.startswith("https://cf.geekdo-images.com/") and len(url) <= 2048:
        response = http.get(url)
        if response.status_code == 200:
            body = response.body()
            return base64.encode(body) if body and len(body) <= MAX_IMAGE_BYTES else None

    return None

def valid_cached_data(data):
    if type(data) != "dict" or type(data.get("timestamp")) != "int" or type(data.get("list")) != "list" or len(data.get("list")) > COUNT:
        return False
    for item in data.get("list"):
        if type(item) != "dict" or type(item.get("name")) != "string" or len(item.get("name")) > 160:
            return False
        image = item.get("image")
        if image and (type(image) != "string" or len(image) > 6 * 1024 * 1024):
            return False
    return True

def data_frame(i, item):
    name = item.get("name", "")
    black_text = render.WrappedText(
        color = "#000",
        width = WIDTH,
        height = HEIGHT,
        content = name,
    )

    return render.Stack(
        [
            render.Box(
                width = WIDTH,
                height = HEIGHT,
                color = "#000",
            ),
        ] + [
            render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Image(
                        width = IM_W,
                        height = IM_H,
                        src = item["image"],
                    ),
                ],
            ) if item.get("image") else None,
        ] + [
            render.Padding(
                pad = p,
                child = black_text,
            )
            for p in SHADOW_PADDING
        ] + [
            render.WrappedText(
                color = COLORS[i],
                content = name,
            ),
        ],
    )

def scroll_frames(item, next_item):
    return [
        render.Padding(
            pad = (0, offset, 0, 0),
            child = render.Stack([
                item,
                render.Padding(
                    pad = (0, HEIGHT, 0, 0),
                    child = next_item,
                ),
            ]),
        )
        for offset in range(SCROLL_SIZE, SCROLL_LIMIT, SCROLL_SIZE)
    ]

URL = "https://boardgamegeek.com/xmlapi2/hot?type=boardgame"
MAX_XML_BYTES = 2 * 1024 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024

NAME_PATH_FMT = "/items/item[@rank=%s]/name/@value"
YEAR_PATH_FMT = "/items/item[@rank=%s]/yearpublished/@value"
IMAGE_PATH_FMT = "/items/item[@rank=%s]/thumbnail/@value"

WIDTH = 64
HEIGHT = 32

IM_W = 32
IM_H = 32
IM_H_PAD = 32

COUNT = 5

DELAY_MS = 30
PAUSE_MS = 2000
PAUSE_F = PAUSE_MS // DELAY_MS
SCROLL_SIZE = -4
SCROLL_LIMIT = -HEIGHT - 1

RANKS = range(1, COUNT + 1)

SHADOW_PADDING = [
    (x, y, 0, 0)
    for x in [-1, 0, 1]
    for y in [-1, 0, 1]
    if x != 0 or y != 0
]

COLORS = [
    "#f44",
    "#bb0",
    "#3d3",
    "#3df",
    "#26f",
]

KEY = "hotness"
TTL = 48 * 60 * 60
EXPIRY = 3 * 60 * 60
