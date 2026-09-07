load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/farcaster_icon_dark_bg.png", FARCASTER_ICON_DARK_BG_ASSET = "file")
load("images/farcaster_icon_light_bg.png", FARCASTER_ICON_LIGHT_BG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

FARCASTER_ICON_DARK_BG = FARCASTER_ICON_DARK_BG_ASSET.readall()
FARCASTER_ICON_LIGHT_BG = FARCASTER_ICON_LIGHT_BG_ASSET.readall()
MAX_RESPONSE_BYTES = 128 * 1024

# 1. Copy logo from Figma as SVG: https://www.figma.com/file/E1RJ5DNTM8eHZpJI1bcaP3/Public-logo?node-id=1-2&t=4PuwjeL9pH70lnxv-0
# 2. Crop & revert the colors (for dark), export to PNG.
# 2. Resize to 19x19, using nearest neighbour (looks better than then the fuzzyness of bilinear)
# 3. Copy to clipboard and convert to base64 using: https://onlineimagetools.com/convert-image-to-base64

def main(config):
    username = config.str("who", "nix").strip()
    count = get_followercount(username)
    if count == None:
        return render.Root(child = render.WrappedText("Farcaster profile unavailable", color = "#ff5555"))

    scheme = config.str("scheme", "default")

    if scheme == "purple":
        # purple (works with different bg)
        bg = "#8a63d2"
        textColor = "#fff"
        textColorLabel = "#ffffff"
        textColorUsername = "#ffffff88"
        icon = FARCASTER_ICON_DARK_BG
    else:
        bg = "#000"
        textColor = "#8a63d2"
        textColorLabel = textColor
        textColorUsername = "#ffffff66"
        icon = FARCASTER_ICON_LIGHT_BG

    # make the count bigger if we have the space, but left-align
    # if larger number, make the font smaller, and center-align
    if count < 100000:
        count_font = "6x13"
        count_align = "left"
    else:
        count_font = "tb-8"
        count_align = "center"

    top_row = render.Row(
        children = [
            render.Image(src = icon),
            render.Column(
                cross_align = count_align,
                children = [
                    render.Text(humanize.comma(count), font = count_font, color = textColor),
                    render.Text("followers", font = "tom-thumb", color = textColorLabel),
                ],
            ),
        ],
        main_align = "space_around",
        cross_align = "center",
        expanded = True,
    )

    child = render.Column(
        children = [
            top_row,
            render.Marquee(
                width = 64,
                child = render.Text("@" + username, font = "tb-8", color = textColorUsername),
                align = "center",
                offset_start = 1,
                offset_end = 1,
            ),
        ],
        main_align = "space_between",
        expanded = True,
    )

    box = render.Box(child = render.Padding(child = child, pad = (0, 2, 0, 2)), padding = 0, color = bg)

    return render.Root(child = box)

def get_followercount(username):
    if not username or len(username) > 64:
        return None
    rep = http.get("https://api.warpcast.com/v2/user-by-username?username=%s" % humanize.url_encode(username))
    body = rep.body()
    payload = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    result = payload.get("result") if type(payload) == "dict" else None
    user = result.get("user") if type(result) == "dict" else None
    count = user.get("followerCount") if type(user) == "dict" else None
    return count if type(count) == "int" and count >= 0 and count <= 1000000000 else None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "farcaster_api_key",
                name = "Legacy Farcaster API Key",
                desc = "Optional legacy setting; public follower counts no longer require this key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "who",
                name = "Who?",
                desc = "Farcaster profile to display.",
                icon = "user",
            ),
            schema.Dropdown(
                id = "scheme",
                name = "Style",
                desc = "Pick a color scheme to use",
                icon = "user",
                default = "default",
                options = [
                    schema.Option(
                        display = "Default",
                        value = "default",
                    ),
                    schema.Option(
                        display = "Purple",
                        value = "purple",
                    ),
                ],
            ),
        ],
    )
