"""
Applet: NFT
Summary: Random Opensea NFT
Description: Displays a random NFT associated with an Ethereum public address.
Author: nipterink
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

NFTS_URL = "https://api.opensea.io/api/v2/chain/ethereum/account/{}/nfts?limit=50"
COLLECTION_STATS_URL = "https://api.opensea.io/api/v2/collections/{}/stats"
ETHEREUM_ADDRESS_LENGTH = 42

def main(config):
    api_key = config.get("opensea-api-key") or ""
    public_address = (config.get("public_address") or "").strip()

    if not api_key:
        return render_error("Add an OpenSea API key")
    if len(public_address) != ETHEREUM_ADDRESS_LENGTH or not public_address.startswith("0x") or any([char not in "0123456789abcdefABCDEF" for char in public_address[2:].codepoints()]):
        return render_error("Invalid Ethereum address")

    nfts = fetch_opensea_nfts(public_address, api_key)
    if nfts == -1:
        return render_error("Unable to connect to OpenSea")
    if len(nfts) == 0:
        return render_error("No NFTs to display")

    nft = nfts[random.number(0, len(nfts) - 1)]
    (nft_name, nft_thumbnail) = fetch_nft_thumbnail(nft)
    if nft_thumbnail == -1:
        return render_error("Unable to connect to OpenSea")
    if not nft_thumbnail:
        return render_error("No image to display")

    floor_price = None
    display_floor = config.bool("display_floor", False)
    if display_floor:
        collection_stats = fetch_collection_stats(nft, api_key)
        if collection_stats:
            total = collection_stats.get("total") or {}
            floor_price = str(total.get("floor_price"))[:4] if total.get("floor_price") else None

    return render.Root(
        child = render.Box(
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Marquee(
                        offset_start = 64,
                        width = 64,
                        child = render.Text(nft_name),
                    ),
                    render.Row(
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = nft_thumbnail,
                                height = 24,
                                width = 24,
                            ),
                            render.Text(" Ξ%s" % floor_price) if display_floor and floor_price else None,
                        ],
                    ),
                ],
            ),
        ),
    )

def fetch_opensea_nfts(public_address, api_key):
    fetch_url = NFTS_URL.format(public_address)
    nfts_resp = http.get(fetch_url, headers = {"X-API-KEY": api_key}, ttl_seconds = 3600)
    if (nfts_resp.status_code != 200):
        print("OpenSea request failed with status", nfts_resp.status_code)
        return -1

    body = nfts_resp.json()
    return body.get("nfts", []) if type(body) == "dict" and type(body.get("nfts", [])) == "list" else []

def fetch_nft_thumbnail(nft):
    if type(nft) != "dict":
        return ("", None)
    nft_name = nft.get("name") or "Untitled NFT"
    thumbnail_url = nft.get("image_url") or ""
    if not thumbnail_url.startswith("https://i.seadn.io/"):
        print("NFT has no image to display")
        return (nft_name, None)

    # request a much smaller thumbnail than the default
    thumbnail_url = thumbnail_url.replace("?w=500", "?w=64")
    thumbnail_resp = http.get(thumbnail_url, ttl_seconds = 3600)
    if (thumbnail_resp.status_code != 200):
        print("Failed to fetch thumbnail with status", thumbnail_resp.status_code)
        return (nft_name, -1)

    return (nft_name, thumbnail_resp.body())

def fetch_collection_stats(nft, api_key):
    collection_slug = nft.get("collection") if type(nft) == "dict" else None
    if not collection_slug:
        return None
    collection_url = COLLECTION_STATS_URL.format(collection_slug)

    collection_resp = http.get(collection_url, headers = {"X-API-KEY": api_key}, ttl_seconds = 3600)
    if (collection_resp.status_code != 200):
        print("OpenSea request failed with status", collection_resp.status_code)
        return -1

    collection_stats = collection_resp.json()
    return collection_stats if type(collection_stats) == "dict" else None

def render_error(error_message):
    return render.Root(
        child = render.Box(
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Marquee(
                        offset_start = 64,
                        width = 64,
                        child = render.Text("NFT: {}".format(error_message)),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "public_address",
                name = "Public Address",
                desc = "Ethereum Public Address",
                icon = "ethereum",
                default = "0xd6a984153acb6c9e2d788f08c2465a1358bb89a7",
            ),
            schema.Toggle(
                id = "display_floor",
                name = "Display Floor",
                desc = "A toggle to display the collection's floor price.",
                icon = "chartLine",
                default = False,
            ),
            schema.Text(
                id = "opensea-api-key",
                name = "OpenSea API Key",
                desc = "An OpenSea API key to access the OpenSea API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
