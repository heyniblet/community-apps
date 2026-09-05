"""
Applet: Emoji Lingo
Summary: Random multilingual emojis
Description: Displays a random emoji and its unique short text annotation from the Unicode Consortium in a given language.
Author: Cedric Sam
"""

load("compress/gzip.star", "gzip")
load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# can be useful to change during testing
default_locale = "en"
default_vendor = "apple"  # apple, google or microsoft (added in May 2025)

# for testing, can be set to a number matching the number in Unicode release
# currently used (see that release's full emoji list)
test_emoji = None

# As of 2025-05-02, the current list of emojis and base64 are Unicode 16.0
# Emoji names are from CLDR's release 47 of 2025-03-12
# Apple emojis are from macos 15.4
# Google emojis are from Noto font's 2024-10-03 release
EMOJI_LIST_URL = "https://emoji-lingo.s3.amazonaws.com/emoji-list-%s.csv"
EMOJI_NAMES_URL = "https://emoji-lingo.s3.amazonaws.com/locale/%s.csv"
EMOJI_BASE64_URL = "https://emoji-lingo.s3.amazonaws.com/base64/%s/%s.txt"
LOCALES = ["en", "en_GB", "en_AU", "af", "da", "nl", "fi", "fil", "fr", "fr_CA", "de", "hu", "id", "ga", "it", "ms", "no", "pt", "pt_PT", "es", "es_MX", "sw", "sv", "cy"]
VENDORS = ["apple", "google", "microsoft"]
MAX_COMPRESSED_BYTES = 256 * 1024
MAX_CSV_BYTES = 2 * 1024 * 1024
MAX_ROWS = 5000
MAX_IMAGE_BASE64_BYTES = 256 * 1024

def normalizeCode(code):
    return re.sub(r" +", "-", code)

def getEmojiList(vendor):
    # No cache found, try to get the file
    emoji_list_url_vendor = EMOJI_LIST_URL % vendor
    print("Making request for emoji with base64 list to %s" % emoji_list_url_vendor)
    rep = http.get(emoji_list_url_vendor, ttl_seconds = 86400)
    if rep.status_code != 200 or len(rep.body()) < 18 or len(rep.body()) > MAX_COMPRESSED_BYTES or rep.body()[:1] != "\u001f":
        return []
    rep_body_raw = rep.body()
    rep_body = str(gzip.decompress(rep_body_raw))  # the emoji list emoji is gzipped, despite url
    if len(rep_body) > MAX_CSV_BYTES:
        return []

    return csv.read_all(rep_body, skip = 1)[:MAX_ROWS]

def getEmojiNames(locale):
    # No cache found, try to get the file
    print("Making request for emoji names to %s" % (EMOJI_NAMES_URL % locale))
    rep_names = http.get(EMOJI_NAMES_URL % locale, ttl_seconds = 86400)
    if rep_names.status_code != 200 or len(rep_names.body()) < 18 or len(rep_names.body()) > MAX_COMPRESSED_BYTES or rep_names.body()[:1] != "\u001f":
        return []
    rep_names_body_raw = rep_names.body()
    rep_names_body = str(gzip.decompress(rep_names_body_raw))  # the names csv is gzipped, despite url

    if len(rep_names_body) > MAX_CSV_BYTES:
        return []
    return csv.read_all(rep_names_body, skip = 1)[:MAX_ROWS]

def error_root(message):
    return render.Root(child = render.Box(render.WrappedText(message, font = "tom-thumb")))

def valid_base64(value):
    if type(value) != "string" or not value or len(value) > MAX_IMAGE_BASE64_BYTES or len(value) % 4 != 0:
        return False
    return all([char in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=" for char in value.elems()])

def main(config):
    locale = config.str("locale", default_locale)
    if locale not in LOCALES:
        locale = default_locale
    vendor = config.str("vendor", default_vendor)
    if vendor not in VENDORS:
        vendor = default_vendor

    emoji_list = getEmojiList(vendor)
    if not emoji_list:
        return error_root("Emoji data unavailable")
    emoji_names = getEmojiNames(locale)
    available_codes = {}
    for row in emoji_list:
        if len(row) >= 2:
            available_codes[row[1]] = True

    valid_emoji_data = []
    for row in emoji_names:
        if len(row) >= 2 and normalizeCode(row[0]) in available_codes:
            valid_emoji_data.append(row)

    name_item = None
    if test_emoji != None:
        test_code = None
        for row in emoji_list:
            if len(row) >= 2 and str(test_emoji) == row[0]:
                test_code = row[1]
                break
        for row in valid_emoji_data:
            if normalizeCode(row[0]) == test_code:
                name_item = row
                break
    if name_item == None and valid_emoji_data:
        name_item = valid_emoji_data[random.number(0, len(valid_emoji_data) - 1)]
    if name_item == None:
        return error_root("Emoji data unavailable")

    rep_base64 = http.get(EMOJI_BASE64_URL % (vendor, normalizeCode(name_item[0])), ttl_seconds = 86400)
    random_emoji_base64 = rep_base64.body().strip() if rep_base64.status_code == 200 else ""
    if not valid_base64(random_emoji_base64):
        return error_root("Emoji image unavailable")
    shortName = str(name_item[1])[:120]

    # Finally decode the emoji's base64
    decoded_emoji = base64.decode(random_emoji_base64)

    # Do options

    # Small text or not
    if config.bool("small"):
        font_face = "tom-thumb"
    else:
        font_face = "tb-8"

    # Setup the images and marquee
    img = render.Image(
        width = 24,
        height = 24,
        src = decoded_emoji,
    )
    emoji_text_render = render.Text(
        shortName,
        font = font_face,
    )
    marquee_vertical = render.Marquee(
        width = 64,
        offset_start = 32,
        offset_end = 32,
        child = emoji_text_render,
        align = "center",
    )
    marquee_horizontal = render.Marquee(
        width = 36,
        offset_start = 18,
        offset_end = 18,
        child = emoji_text_render,
        align = "center",
    )
    contents_vertical = render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            img,
            marquee_vertical,
        ],
    )
    contents_horizontal = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            img,
            marquee_horizontal,
        ],
    )
    if config.str("textPosition") == "bottom":
        contents = contents_vertical
    elif config.str("textPosition") == "right":
        contents = contents_horizontal
    else:
        contents = contents_vertical

    # On screen
    return render.Root(
        child = render.Box(
            contents,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # Names from: https://unicode-org.github.io/cldr-staging/charts/latest/summary/root.html
            # Only latin1 (ISO-8859-1) languages are supported
            schema.Dropdown(
                id = "locale",
                name = "Locale",
                desc = "Local language in which to display the emoji short names",
                icon = "language",
                default = default_locale,
                options = [
                    schema.Option(
                        display = "English",
                        value = "en",
                    ),
                    schema.Option(
                        display = "British English",
                        value = "en_GB",
                    ),
                    schema.Option(
                        display = "Australian English",
                        value = "en_AU",
                    ),
                    schema.Option(
                        display = "Afrikaans",
                        value = "af",
                    ),
                    schema.Option(
                        display = "Danish",
                        value = "da",
                    ),
                    schema.Option(
                        display = "Dutch",
                        value = "nl",
                    ),
                    schema.Option(
                        display = "Finnish",
                        value = "fi",
                    ),
                    schema.Option(
                        display = "Filipino",
                        value = "fil",
                    ),
                    schema.Option(
                        display = "French",
                        value = "fr",
                    ),
                    schema.Option(
                        display = "Canadian French",
                        value = "fr_CA",
                    ),
                    schema.Option(
                        display = "German",
                        value = "de",
                    ),
                    schema.Option(
                        display = "Hungarian",
                        value = "hu",
                    ),
                    schema.Option(
                        display = "Indonesian",
                        value = "id",
                    ),
                    schema.Option(
                        display = "Irish",
                        value = "ga",
                    ),
                    schema.Option(
                        display = "Italian",
                        value = "it",
                    ),
                    schema.Option(
                        display = "Malay",
                        value = "ms",
                    ),
                    schema.Option(
                        display = "Norwegian",
                        value = "no",
                    ),
                    schema.Option(
                        display = "Portuguese",
                        value = "pt",
                    ),
                    schema.Option(
                        display = "European Portuguese",
                        value = "pt_PT",
                    ),
                    schema.Option(
                        display = "Spanish",
                        value = "es",
                    ),
                    schema.Option(
                        display = "Mexican Spanish",
                        value = "es_MX",
                    ),
                    schema.Option(
                        display = "Swahili",
                        value = "sw",
                    ),
                    schema.Option(
                        display = "Swedish",
                        value = "sv",
                    ),
                    schema.Option(
                        display = "Welsh",
                        value = "cy",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "textPosition",
                name = "Text Position",
                desc = "Where the emoji short names will appear",
                icon = "arrowsUpDownLeftRight",
                default = "bottom",
                options = [
                    schema.Option(
                        display = "Right of",
                        value = "right",
                    ),
                    schema.Option(
                        display = "Under",
                        value = "bottom",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "vendor",
                name = "Emoji Style",
                desc = "Emoji as seen on a given platform",
                icon = "icons",
                default = default_vendor,
                options = [
                    schema.Option(
                        display = "Apple",
                        value = "apple",
                    ),
                    schema.Option(
                        display = "Google",
                        value = "google",
                    ),
                    schema.Option(
                        display = "Microsoft",
                        value = "microsoft",
                    ),
                ],
            ),
            schema.Toggle(
                id = "small",
                name = "Display small text",
                desc = "A toggle to display smaller text.",
                icon = "compress",
                default = False,
            ),
        ],
    )
