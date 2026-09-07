"""
Applet: Marvel of the Day
Summary: A Marvel character a day
Description: Shows the name and image of a Marvel Comics character using the Marvel API.
Author: flynnt
"""

load("hash.star", "hash")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://gateway.marvel.com/v1/public/characters"

def main(config):
    """
    App entrypoint.
    Retrieves and parses a single Marvel character.
    Returns rendered application root.
    """
    if config.get("public_key") == None or config.get("private_key") == None:
        image = http.get("https://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body()
        name = "Something went wrong, enjoy this image of Wolverine while we fix it."

        return render_data(image, name)
    else:
        random.seed(time.now().unix // 86400)
        params = {"limit": "1", "offset": str(random.number(0, 1562))} | get_auth_params(config)
        req = http.get(BASE_URL, params = params)
        if req.status_code != 200:
            return render_data(http.get("https://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body(), "Marvel API unavailable")

        results = req.json().get("data", {}).get("results", [])
        if not results:
            return render_data(http.get("https://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body(), "No Marvel character found")
        item = results[0]
        name = item.get("name", "Marvel character")
        thumbnail = item.get("thumbnail", {})
        image_url = thumbnail.get("path", "").replace("http:", "https:") + "." + thumbnail.get("extension", "jpg")
        if not image_url.startswith("https://i.annihil.us/"):
            image_url = "https://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg"
        image_response = http.get(image_url)
        image = image_response.body() if image_response.status_code == 200 else http.get("https://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body()

        return render_data(image, name)

def render_data(image, name):
    return render.Root(
        render.Row(
            children = [
                render.Box(
                    height = 32,
                    width = 28,
                    child = render.Image(
                        src = image,
                        height = 28,
                    ),
                ),
                render.Box(
                    height = 32,
                    child = render.Marquee(
                        align = "center",
                        width = 35,
                        child = render.Text(name),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "public_key",
                name = "Marvel API Public Key",
                desc = "Your Marvel API public key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "private_key",
                name = "Marvel API Private Key",
                desc = "Your Marvel API private key.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def get_auth_params(config):
    """
    Returns Marvel API authentication params.
    """
    timestamp = str(1699392191)
    params = {
        "ts": timestamp,
        "apikey": config.get("public_key"),
        "hash": hash.md5(timestamp + config.get("private_key") + config.get("public_key")),
    }

    return params
