"""
Applet: Random Slackmoji
Summary: Displays a random Slackmoji
Description: Displays a random image from slackmojis.com!
Author: btjones
"""

# Copyright 2022 Brandon Jones

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/fail_image.png", FAIL_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FAIL_IMAGE = FAIL_IMAGE_ASSET.readall()

SLACKMOJI_PAGE_COUNT = 209
SLACKMOJIS_URL_RANDOM = "https://slackmojis.com/emojis.json?page="
SLACKMOJIS_URL_QUERY = "https://slackmojis.com/emojis/search?query="
SLACKMOJI_IMAGE_PREFIX = "https://emojis.slackmojis.com/"

CACHE_SECONDS_URL = 300
CACHE_SECONDS_IMAGE = 60 * 60 * 24 * 30  # 30 days
MAX_JSON_BYTES = 1024 * 1024
MAX_HTML_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024
SCHEMA_QUERY_ID = "query"

# fetches a random slackmoji url from all slackmojis
def get_random_url():
    page_url = SLACKMOJIS_URL_RANDOM + str(random.number(0, SLACKMOJI_PAGE_COUNT))
    response = http.get(page_url, ttl_seconds = CACHE_SECONDS_URL)
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_JSON_BYTES else None
    if type(data) == "list" and len(data) > 0:
        slackmoji = data[random.number(0, len(data) - 1)]
        url = slackmoji.get("image_url") if type(slackmoji) == "dict" else None
        if valid_image_url(url):
            return url

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji url from the query results
def get_query_url(query):
    page_url = SLACKMOJIS_URL_QUERY + humanize.url_encode(query)
    response = http.get(page_url, ttl_seconds = CACHE_SECONDS_URL)
    body = response.body()
    if response.status_code == 200 and body and len(body) <= MAX_HTML_BYTES:
        html_body = html(body)
        images = html_body.find("img")
        urls = [images.eq(index).attr("src") for index in range(images.len())]
        urls = [url for url in urls if valid_image_url(url)]
        if len(urls) > 0:
            return urls[random.number(0, len(urls) - 1)]

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji image url
def get_slackmoji_url(query):
    return get_query_url(query) if len(query) > 0 else get_random_url()

# downloads an image from the provided url
def get_image(url):
    if valid_image_url(url):
        # no cache, fetch new image
        response = http.get(url, ttl_seconds = CACHE_SECONDS_IMAGE)
        body = response.body()
        if response.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES:
            return body

    # something went wrong, return the fail image
    return FAIL_IMAGE

def valid_image_url(url):
    return type(url) == "string" and url.startswith(SLACKMOJI_IMAGE_PREFIX)

def main(config):
    # get the slackmoji image url
    query = config.str(SCHEMA_QUERY_ID, "").strip()[:64]
    url = get_slackmoji_url(query)

    # if no image url was returned and we have a query, show error message
    if (url == None and len(query) > 0):
        return render.Root(
            render.Box(
                child = render.WrappedText(
                    content = "No results for: " + query,
                ),
            ),
        )

    # download the image
    image = get_image(url)

    return render.Root(
        render.Box(
            child = render.Image(
                src = image,
                height = 32,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = SCHEMA_QUERY_ID,
                name = "Search Query",
                desc = "Optional search to narrow down the image results.",
                icon = "magnifyingGlass",
                default = "",
            ),
        ],
    )
