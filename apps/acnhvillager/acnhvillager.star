"""
Applet: AC:NH Villager
Summary: Random AC:NH villager
Description: See your favorite villagers from Animal Crossing New Horizons.
Author: colinscruggs
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/fail.png", FAIL_IMAGE = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL_SECONDS = 3600 * 24 * 7
MAX_DATA_BYTES = 1024 * 1024
MAX_ICON_BYTES = 1024 * 1024
MAX_VILLAGERS = 500
MAX_TEXT_LENGTH = 120
ICON_WIDTH = 26
ICON_HEIGHT = 26

FONTS = ["CG-pixel-3x5-mono", "tb-8", "tom-thumb", "Dina_r400-6", "5x8"]
FONT_DEFAULT = FONTS[0]

ACNH_DATA_REVISION = "6df0d7318a97ab8d0e4a5646bff57180fde1eec5"
ACNH_API_VILLAGERS = "https://cdn.jsdelivr.net/gh/alexislours/ACNHAPI@{}/villagers.json".format(ACNH_DATA_REVISION)
ACNH_API_ICON_TEMPLATE = "https://cdn.jsdelivr.net/gh/alexislours/ACNHAPI@{}/icons/villagers/{{}}.png".format(ACNH_DATA_REVISION)
LANGUAGES = ["USen", "USes", "EUfr", "EUit", "EUde", "EUnl"]

def main(config):
    language = config.get("language") or "USen"
    if language not in LANGUAGES:
        language = "USen"
    name_key = "name-" + language
    catch_phrase_key = "catch-" + language

    # Fetch and cache villager data; pick one at random
    villager_data = get_villager_data()
    if len(villager_data) == 0:
        return render_error("Villagers unavailable")
    random_index = random.number(0, len(villager_data) - 1)
    _, villager = list(villager_data.items())[random_index]
    if not valid_villager(villager, name_key, catch_phrase_key):
        return render_error("Bad villager data")

    # Set villager icon
    villager_icon = ACNH_API_ICON_TEMPLATE.format(villager["file-name"])
    villager_icon = get_villager_icon(villager_icon)

    return render.Root(
        delay = 100,
        child =
            render.Padding(
                pad = (0, 2, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "space_around",
                        children = [
                            # Left column - Name and Icon
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_name(villager["name"][name_key][:MAX_TEXT_LENGTH]),
                                                font = FONT_DEFAULT,
                                                color = villager["bubble-color"],
                                            ),
                                        width = 28,
                                    ),
                                    render.Image(
                                        src = villager_icon,
                                        width = ICON_WIDTH,
                                        height = ICON_HEIGHT,
                                    ),
                                ],
                            ),
                            # Right column - Personality, Species, and Catch Phrase
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = villager["personality"][:MAX_TEXT_LENGTH],
                                        font = FONT_DEFAULT,
                                        width = 28,
                                        align = "right",
                                    ),
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_species(villager["species"][:MAX_TEXT_LENGTH]),
                                                font = FONT_DEFAULT,
                                            ),
                                        width = 28,
                                        scroll_direction = "horizontal",
                                    ),
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_catch_phrase(villager["catch-translations"][catch_phrase_key][:MAX_TEXT_LENGTH]),
                                                font = FONT_DEFAULT,
                                                color = villager["text-color"],
                                            ),
                                        width = 28,
                                        scroll_direction = "horizontal",
                                    ),
                                ],
                            ),
                        ],
                    ),
            ),
    )

# Cache and encode villager data
def get_villager_data():
    rep = http.get(ACNH_API_VILLAGERS, ttl_seconds = CACHE_TTL_SECONDS)
    body = rep.body()
    if rep.status_code != 200 or len(body) > MAX_DATA_BYTES:
        return {}
    data = json.decode(body, None)
    return data if type(data) == "dict" and len(data) <= MAX_VILLAGERS else {}

# Cache and encode villager icon
def get_villager_icon(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_ICON_BYTES:
        return FAIL_IMAGE.readall()
    return body

def valid_villager(villager, name_key, catch_phrase_key):
    if type(villager) != "dict":
        return False
    names = villager.get("name")
    catches = villager.get("catch-translations")
    required = [villager.get("file-name"), villager.get("personality"), villager.get("species"), villager.get("bubble-color"), villager.get("text-color")]
    if type(names) != "dict" or type(catches) != "dict" or type(names.get(name_key)) != "string" or type(catches.get(catch_phrase_key)) != "string":
        return False
    return all([type(value) == "string" and 0 < len(value) and len(value) <= MAX_TEXT_LENGTH for value in required])

def render_error(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Image(src = FAIL_IMAGE.readall(), width = 20, height = 20),
                render.Text(message, font = FONT_DEFAULT, color = "#fff"),
            ],
        ),
    )

# Adds padding for villager names that are less than 7 characters
def get_villager_name(str):
    diff = 7 - len(str)
    if diff <= 0:
        return str
    elif diff == 1:
        return str + " "
    elif diff == 2:
        return " " + str + " "
    elif diff == 3:
        return " " + str + " "
    elif diff == 4:
        return "  " + str + "  "
    elif diff == 5:
        return "  " + str + "   "
    elif diff == 6:
        return "   " + str + "   "
    else:
        return str

# Adds quotes; left-padding added for catch phrases that are less than 5 characters
def get_villager_catch_phrase(str):
    padding_right = 5 - len(str)
    if padding_right > 0:
        return padding_right * " " + '"' + str + '"'
    else:
        return '"' + str + '"'

# Adds left-padding added for specifies that are less than 7 characters
def get_villager_species(str):
    padding_right = 7 - len(str)
    if padding_right > 0:
        return padding_right * " " + str
    else:
        return str

def get_schema():
    dialectOptions = [
        schema.Option(
            display = "English (US)",
            value = "USen",
        ),
        schema.Option(
            display = "Spanish (US)",
            value = "USes",
        ),
        schema.Option(
            display = "French",
            value = "EUfr",
        ),
        schema.Option(
            display = "Italian",
            value = "EUit",
        ),
        schema.Option(
            display = "German",
            value = "EUde",
        ),
        schema.Option(
            display = "Dutch",
            value = "EUnl",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "language",
                name = "Language",
                icon = "language",
                desc = "Select language",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
        ],
    )
