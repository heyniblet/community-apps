"""
Applet: CraftNFT
Summary: Craft NFT Display
Description: Display random Craft NFT owned by a user.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_USER_ADDRESS = "hx5c9d08a9d85539760b69e160d9376bc5eed948f5"

USER_URL = "https://api.craft.network/user/{}"

TOKEN_URL = "https://utils.craft.network/metadata/{}/{}"

DEFAULT_TTL = 300  #300

def main(config):
    nft_ttl_seconds = int(config.get("nft_cycle_seconds", DEFAULT_TTL))  # default 5 minutes
    address = config.str("user_address", DEFAULT_USER_ADDRESS)
    if not re.match(r"^hx[0-9a-fA-F]{40}$", address):
        return error_screen("Invalid wallet address")

    nft_image_url = fetch_random_nft(address)
    if nft_image_url != None:
        image_response = http.get(nft_image_url, ttl_seconds = nft_ttl_seconds)
        nft_image_src = image_response.body() if image_response.status_code == 200 and len(image_response.body()) <= 4194304 else None
    else:
        nft_image_src = None

    # Here is the error screen
    if nft_image_src == None:
        return error_screen("No Displayable NFTs Found")
    else:
        # Here is the main render screen.
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = nft_image_src,
                        height = 32,
                    ),
                ],
            ),
        )

def fetch_random_nft(address):
    token_keys = fetch_token_keys(address)
    if not token_keys:
        return None
    start = random.number(0, len(token_keys) - 1)
    for offset in range(min(10, len(token_keys))):
        collection, token_id = token_keys[(start + offset) % len(token_keys)]
        response = http.get(TOKEN_URL.format(collection, token_id), ttl_seconds = 3600)
        if response.status_code != 200 or len(response.body()) > 262144:
            continue
        metadata = json.decode(response.body())
        image_url = metadata.get("cloudinary", "") if type(metadata) == "dict" else ""
        if valid_image_url(image_url):
            return image_url
    return None

def fetch_token_keys(address):
    response = http.get(USER_URL.format(address), ttl_seconds = 300)
    if response.status_code != 200 or len(response.body()) > 1048576:
        return []
    user = json.decode(response.body())
    user_data = user.get("userData") if type(user) == "dict" else None
    token_map = user_data.get("tokenMap") if type(user_data) == "dict" else None
    if type(token_map) != "dict":
        return []

    keys = []
    for collection, tokens in token_map.items():
        if type(collection) != "string" or not re.match(r"^[A-Za-z0-9._-]{1,128}$", collection) or type(tokens) != "dict":
            continue
        for token_id in tokens.keys():
            if type(token_id) == "string" and re.match(r"^[A-Za-z0-9._-]{1,128}$", token_id):
                keys.append((collection, token_id))
                if len(keys) == 200:
                    return keys
    return keys

def valid_image_url(url):
    return type(url) == "string" and len(url) <= 2048 and url.startswith("https://res.cloudinary.com/") and all([c not in url for c in [" ", "\t", "\r", "\n"]])

def error_screen(message):
    return render.Root(
        render.Box(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [render.WrappedText(content = message, font = "tb-8", color = "#FF0000", align = "center")],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_address",
                name = "User Address",
                desc = "The user address.",
                icon = "user",
            ),
            # schema.Text(
            #     id = "nft_cycle_seconds",
            #     name = "Display Time",
            #     desc = "How long to display each NFT",
            #     icon = "clock"
            # )
        ],
    )
