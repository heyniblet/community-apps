# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: CraftNFT
Summary: Craft NFT Display
Description: Display random Craft NFT owned by a user.
Author: tavdog
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_USER_ADDRESS = "hx5c9d08a9d85539760b69e160d9376bc5eed948f5"

DEFAULT_TTL = 300  #300

def main(config):
    nft_ttl_seconds = int(config.get("nft_cycle_seconds", DEFAULT_TTL))  # default 5 minutes
    address = config.str("user_address", DEFAULT_USER_ADDRESS)
    if not re.match(r"^hx[0-9a-fA-F]{40}$", address):
        return error_screen("Invalid wallet address")

    image_response = http.get("https://api.dicebear.com/9.x/shapes/png?seed=" + address, ttl_seconds = nft_ttl_seconds)
    nft_image_src = image_response.body() if image_response.status_code == 200 and len(image_response.body()) <= 4194304 else None

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
