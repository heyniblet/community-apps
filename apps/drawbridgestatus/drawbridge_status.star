"""
Applet: Drawbridge Status
Summary: Display Drawbridge Status
Description: Shows whether a drawbridge is open or not, and when it is expected to rise again. For now, only the Saint-Louis-de-Gonzague bridge (QC) is supported.
Author: sumara523
"""

load("html.star", "html")
load("http.star", "http")
load("images/boat_icon_base64_str.png", BOAT_ICON_BASE64_STR_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BOAT_ICON_BASE64_STR = BOAT_ICON_BASE64_STR_ASSET.readall()

BRIDGE_API_URL = "https://www.seaway-greatlakes.com/bridgestatus/detailsmai2?key=BridgeSBS"
MAX_RESPONSE_BYTES = 128 * 1024

LANGUAGE_LOCALES = {
    "not_200_error": {
        "fr": "Tenté de contacter l'API ayant l'info du pont, mais reçu un statut %d.",
        "en": "Tried to fetch the API for bridge information, but got status %d.",
    },
    "no_bridge_item_found_error": {
        "fr": "Aucune information sur le pont reçue dans la réponse.",
        "en": "No bridge item found when parsing the bridge information response",
    },
    "accept_language_header": {
        "fr": "fr-CA, fr-FR",
        "en": "en-CA, en-US",
    },
}

# Values should match the keys in the locales map above.
LANGUAGE_OPTIONS = [
    schema.Option(display = "Français", value = "fr"),
    schema.Option(display = "English", value = "en"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "lang",
                name = "Language",
                desc = "The language to display the information",
                icon = "language",
                default = LANGUAGE_OPTIONS[0].value,
                options = LANGUAGE_OPTIONS,
            ),
        ],
    )

def fetch_bridge_status(config):
    lang = config.get("lang", LANGUAGE_OPTIONS[0].value)
    if lang not in ["fr", "en"]:
        lang = "fr"
    accept_language_header = LANGUAGE_LOCALES["accept_language_header"][lang]
    response = http.get(
        BRIDGE_API_URL,
        headers = {"Accept-Language": accept_language_header},
        ttl_seconds = 60,
    )
    if response.status_code != 200:
        return None, LANGUAGE_LOCALES["not_200_error"][lang] % response.status_code

    body = response.body()
    if not body or len(body) > MAX_RESPONSE_BYTES:
        return None, LANGUAGE_LOCALES["no_bridge_item_found_error"][lang]
    doc = html(body)

    bridge_items = doc.find("div.bridge-item")
    if bridge_items.len() < 1:
        return None, LANGUAGE_LOCALES["no_bridge_item_found_error"][lang]
    first_bridge_item = bridge_items.eq(0)

    background_color = None

    # Extract all h1 tags with the class 'status-title' within the first bridge-item.
    status_titles_elems = first_bridge_item.find("h1.status-title")
    status_titles_len = status_titles_elems.len()
    status_titles = [status_titles_elems.eq(i).text().strip()[:120] for i in range(min(status_titles_len, 2))]
    if not status_titles or not status_titles[0]:
        return None, LANGUAGE_LOCALES["no_bridge_item_found_error"][lang]

    status_elems = first_bridge_item.find("p.item-data")
    status = status_elems.first().text().strip()[:240] if status_elems.len() > 0 else ""

    banner_elems = first_bridge_item.find("div.item-title-banner")
    if banner_elems.len() > 0 and banner_elems.attr("style"):
        # Split the style attribute to find the background-color value.
        for attr in banner_elems.attr("style").split(";"):
            parts = attr.split(":", 1)
            if len(parts) == 2 and parts[0].strip() == "background-color":
                candidate = parts[1].strip()
                if valid_color(candidate):
                    background_color = candidate
                break

    if not background_color:
        background_color = "#C1D6A8"

    return {
        "status_titles": status_titles,
        "status": status,
        "background_color": background_color,
    }, None

def valid_color(value):
    if len(value) != 7 or not value.startswith("#"):
        return False
    for char in value[1:].lower().elems():
        if char not in "0123456789abcdef":
            return False
    return True

def render_view(bridge_status):
    # Decode the boat icon image from Base64.
    imgBase64 = BOAT_ICON_BASE64_STR

    # Create banner_row list, with the boat icon image to start with.
    banner_row = [render.Image(src = imgBase64)]

    # Add availability status to the status column.
    status_column = [render.Text(content = bridge_status["status_titles"][0], font = "tom-thumb", color = bridge_status["background_color"])]

    # Add the optional 2nd status title to the status column.
    if len(bridge_status["status_titles"]) > 1:
        status_column.append(render.Marquee(width = 50, child = render.Text(content = bridge_status["status_titles"][1], font = "tom-thumb", color = bridge_status["background_color"])))

    # Append the status column to the banner_row.
    banner_row.append(render.Column(children = status_column))

    # Create the canvas list, starting with the banner_row.
    canvas = [render.Row(children = banner_row, expanded = True, main_align = "space_evenly")]

    # Add the anticipated status to the canvas.
    canvas.append(render.WrappedText(content = bridge_status["status"], linespacing = 0, font = "tom-thumb", align = "center"))

    # Render the composed canvas.
    return render.Root(
        child = render.Column(
            children = canvas,
            cross_align = "center",
            main_align = "space_evenly",
            expanded = True,
        ),
    )

def render_error(err):
    # Decode the boat icon image from Base64.
    imgBase64 = BOAT_ICON_BASE64_STR

    # Create banner_row list, with the boat icon image to start with.
    banner_row = [render.Image(src = imgBase64)]

    status_column = [render.Marquee(width = 64, offset_start = 64, offset_end = 0, child = render.Text(content = err, font = "tom-thumb", color = "#F00"))]
    banner_row.append(render.Column(children = status_column))

    # Render the error.
    return render.Root(
        child = render.Column(
            children = banner_row,
            cross_align = "center",
            main_align = "space_evenly",
            expanded = True,
        ),
    )

def main(config):
    bridge_status, err = fetch_bridge_status(config)
    if err:
        return render_error(err)

    return render_view(bridge_status)
