"""
Applet: National Pokedex
Summary: Display a random Pokemon from Gen I - IX
Description: Display a random Pokemon from your region of choice
Author: Lauren Kopac
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon?limit=1&offset={}"
SPRITE_URL = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{}.png"
REGIONAL_DEX_ID = "regional_dex_code"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

NAME_FONT_1X = "tb-8"
NAME_FONT_2X = "terminus-14"
NAME_FONT_SMALL = "tb-8"
NUMBER_FONT_1X = "tb-8"
NUMBER_FONT_2X = "terminus-14"

REGION_RANGES = {
    "Kanto": (1, 151),
    "Johto": (152, 251),
    "Hoenn": (252, 386),
    "Sinnoh": (387, 493),
    "Unova": (494, 649),
    "Kalos": (650, 721),
    "Alola": (722, 809),
    "Galar": (810, 905),
    "Paldea": (906, 1025),
}

def get_regions():
    regions = ["National"] + list(REGION_RANGES.keys())
    region_options = []
    for x in regions:
        region_options.append(
            schema.Option(
                display = x,
                value = x,
            ),
        )
    return region_options

def get_schema():
    regions = get_regions()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = REGIONAL_DEX_ID,
                name = "Regional Pokedex",
                desc = "Which Pokedex do you want to pull from?",
                icon = "book",
                default = regions[0].value,
                options = regions,
            ),
        ],
    )

def main(config):
    dex_region = config.get(REGIONAL_DEX_ID)
    MIN, MAX = 1, max([r[1] for r in REGION_RANGES.values()])
    if dex_region in REGION_RANGES:
        MIN, MAX = REGION_RANGES[dex_region]

    random.seed(time.now().unix // 15)
    dex_number = random.number(MIN, MAX)
    pokemon = get_pokemon(dex_number)
    if pokemon == None:
        return render_error("Pokémon unavailable")
    name = pokemon["name"].title()

    scale = 2 if canvas.is2x() else 1

    size = 30 * scale
    sprite_url = SPRITE_URL.format(dex_number)
    sprite = get_cachable_data(sprite_url)
    if sprite == None:
        return render_error("Sprite unavailable")
    name_font = NAME_FONT_2X if scale == 2 else NAME_FONT_1X
    number_font = NUMBER_FONT_2X if scale == 2 else NUMBER_FONT_1X

    display_width = 64 * scale

    sprite_img = render.Image(src = sprite, width = size, height = size)
    sprite_width, _ = sprite_img.size()

    name_text = render.Text(content = name, font = name_font)
    name_width, _ = name_text.size()

    if name_width + sprite_width > display_width:
        name_widget = render.Marquee(
            width = display_width - sprite_width,
            align = "end",
            child = render.Text(content = name, font = NAME_FONT_SMALL),
        )
        number_font = NAME_FONT_SMALL
    else:
        name_widget = name_text

    number_text = render.Text(content = "#{}".format(dex_number), font = number_font)
    _, number_height = number_text.size()
    number_top_padding = (32 * scale) - number_height

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = 32 * scale,
                    height = 32 * scale,
                    child = sprite_img,
                ),
                render.Row(
                    expanded = True,
                    main_align = "end",
                    cross_align = "start",
                    children = [
                        name_widget,
                    ],
                ),
                render.Padding(
                    pad = (0, number_top_padding, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            number_text,
                        ],
                    ),
                ),
            ],
        ),
    )

def get_pokemon(id):
    res = http.get(
        url = POKEAPI_URL.format(id - 1),
        headers = {"User-Agent": "Niblet natdex/1 (+https://heyniblet.com)"},
        ttl_seconds = CACHE_TTL_SECONDS,
    )
    if res.status_code != 200:
        return None
    data = res.json()
    if type(data) != "dict" or type(data.get("results")) != "list" or len(data["results"]) != 1:
        return None
    pokemon = data["results"][0]
    if type(pokemon) != "dict" or type(pokemon.get("name")) != "string":
        return None
    return pokemon

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        return None

    return res.body()

def render_error(message):
    return render.Root(
        child = render.WrappedText(
            message,
            width = 64,
            align = "center",
            color = "#ff8888",
        ),
    )
