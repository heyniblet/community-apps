load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")

BORDER_SIZE = 2 if canvas.is2x() else 1

def main(config):
    URL = config.get("immich_url", "").strip().rstrip("/")
    API_KEY = config.get("immich_api_key", "")

    # SHOW_FAVORITES = config.bool("show_favorites", False)
    ALBUM = config.get("immich_album_id", "invalid")
    STATUS_URL = "%s/api/server/ping" % (URL)
    ALBUM_URL = "%s/api/albums/%s" % (URL, ALBUM)
    SHOW_DATE = config.bool("show_date", True)
    SHOW_LOCATION = config.bool("show_location", False)

    if not valid_base_url(URL) or type(API_KEY) != "string" or not API_KEY or len(API_KEY) > 2048 or not valid_id(ALBUM):
        return message("Configure public HTTPS Immich")

    res = http.get(STATUS_URL)

    if res.status_code != 200:
        return message("Server not accessible")
    else:
        headers = {
            "x-api-key": API_KEY,
        }
        res = http.get(ALBUM_URL, headers = headers)
        body = res.body()
        album = json.decode(body, {}) if res.status_code == 200 and body and len(body) <= 1024 * 1024 else {}
        assets = album.get("assets", []) if type(album) == "dict" else []
        if type(assets) != "list":
            return message("Album not accessible")
        assets = [asset for asset in assets[:1000] if type(asset) == "dict" and valid_id(asset.get("id"))]
        assetCount = len(assets) - 1
        if assetCount < 0:
            return message("Album is Empty")
        randomCount = random.number(0, assetCount)
        assetID = assets[randomCount]["id"]
        IMG_URL = "%s/api/assets/%s" % (URL, assetID)
        res_img = http.get("%s/thumbnail" % IMG_URL, headers = headers)
        res_req_metadata = http.get(IMG_URL, headers = headers)
        image = res_img.body()
        metadata_body = res_req_metadata.body()
        content_type = res_img.headers.get("Content-Type", "").lower()
        if res_img.status_code != 200 or not image or len(image) > 8 * 1024 * 1024 or not content_type.startswith("image/") or res_req_metadata.status_code != 200 or len(metadata_body) > 256 * 1024:
            return message("Unable to retrieve image")
        res_metadata = json.decode(metadata_body, {})
        exif = res_metadata.get("exifInfo") or {} if type(res_metadata) == "dict" else {}
        if type(exif) != "dict":
            exif = {}
        country = bounded_text(exif.get("country"), 80)
        state = bounded_text(exif.get("state"), 80)
        city = bounded_text(exif.get("city"), 80)
        photo_date = bounded_text(exif.get("dateTimeOriginal"), 40)
        return render.Root(
            child = render.Stack(
                children = [
                    render.Box(
                        padding = BORDER_SIZE,
                        color = "#fff",
                        child = render.Image(
                            src = image,
                            width = canvas.width() - BORDER_SIZE,
                            height = canvas.height() - BORDER_SIZE,
                        ),
                    ),
                    render.Column(
                        children = get_text(photo_date, country, state, city, SHOW_DATE, SHOW_LOCATION),
                        main_align = "end",
                        expanded = True,
                    ),
                ],
            ),
        )

def get_text(date, country, state, city, toggle_date, toggle_location):
    font = "CG-pixel-3x5-mono"
    if canvas.is2x():
        font = "terminus-12"
    bgcolor = "#00000078"
    strdate = parse_date(date)
    full_string = ""

    if toggle_date:
        full_string += "%s" % strdate

    if toggle_location and country != None:
        if toggle_date:
            full_string += " | "
        full_string += "%s, %s, %s" % (city, state, country)
    if full_string == "":
        return []
    else:
        text = render.Text(
            content = full_string,
            font = font,
        )
        _, textHeight = text.size()

        return [
            render.Padding(
                child = render.Marquee(
                    child = text,
                    width = canvas.width() - BORDER_SIZE,
                    height = textHeight,
                ),
                pad = BORDER_SIZE,
                color = bgcolor,
            ),
        ]

def parse_date(date):
    if type(date) != "string" or not re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}", date):
        return ""
    splitDate = date.split("-")
    year = splitDate[0]
    month = splitDate[1]
    day = splitDate[2].split("T")[0]

    return "%s/%s/%s" % (month, day, year)

def valid_base_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://"):
        return False
    parts = value.split("/")
    return len(parts) >= 3 and parts[2] and ":" not in parts[2] and not any([c in value for c in ["@", "\\", " ", "\t", "\r", "\n", "?", "#"]])

def valid_id(value):
    return type(value) == "string" and re.match(r"^[0-9A-Za-z_-]{1,100}$", value)

def bounded_text(value, limit):
    return value[:limit] if type(value) == "string" else None

def message(text):
    return render.Root(child = render.WrappedText(text, width = canvas.width(), align = "center"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "immich_url",
                name = "Immich Instance URL",
                desc = "The URL for your Immich Instance",
                icon = "globe",
            ),
            schema.Text(
                id = "immich_api_key",
                name = "Immich API Key",
                desc = "Your Immich API key. See Immich documentation on how you can retrieve this.",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "show_favorites",
                name = "Show Favorites",
                desc = "(Does nothing right now) Show the images that you have added to your favorites. This will override any albums you have selected to be shown",
                icon = "heart",
                default = False,
            ),
            schema.Text(
                id = "immich_album_id",
                name = "Albums",
                desc = "Enter the UUID of the Albums you would like to be displayed",
                icon = "image",
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show Date",
                desc = "Toggle to show the date that the picture shown was taken",
                icon = "calendar",
                default = True,
            ),
            schema.Toggle(
                id = "show_location",
                name = "Show Location",
                desc = "Toggle to show the location in which a picture was taken where applicable.",
                icon = "mapPin",
                default = False,
            ),
        ],
    )
