"""
Applet: Pokedex+
Summary: Pokémon Pokédex
Description: Displays a random Pokedex entry from any generation. This includes its name, image, number, and a scrolling PokeDex entry description. Customizable font color and background color allows users to customize the app to their liking.
Author: Forrest Syrett
Collaborators: Eric Pierce
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOR = "#000024"
DEFAULT_FONT_COLOR = "#FFFFFF"
DEFAULT_REGION = "National"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.
MAX_JSON_BYTES = 1048576
MAX_IMAGE_BYTES = 2097152
SPRITE_PREFIX = "https://raw.githubusercontent.com/PokeAPI/sprites/"

POKEMON_API = "https://pokeapi.co/api/v2/pokemon/{}"
POKEMON_SPECIES_API = "https://pokeapi.co/api/v2/pokemon-species/{}"

def main(config):
    is2x = canvas.is2x()
    scale = 2 if is2x else 1
    bgColor = config.str("bgColor", DEFAULT_COLOR)
    fontColor = config.str("fontColor", DEFAULT_FONT_COLOR)
    region = config.get("region", DEFAULT_REGION)

    min = 1
    max = 1025

    if region == "National":
        min = 1
        max = 1025
    elif region == "Kanto":
        min = 1
        max = 151
    elif region == "Johto":
        min = 152
        max = 251
    elif region == "Hoenn":
        min = 252
        max = 386
    elif region == "Sinnoh":
        min = 387
        max = 493
    elif region == "Unova":
        min = 494
        max = 649
    elif region == "Kalos":
        min = 650
        max = 721
    elif region == "Alola":
        min = 722
        max = 809
    elif region == "Galar":
        min = 810
        max = 898
    elif region == "Hisui":
        min = 899
        max = 905
    elif region == "Paldea":
        min = 906
        max = 1025
    else:
        min = 1
        max = 1025

    # Generate a random Pokémon ID based on the user's desired region.
    random.seed(time.now().unix // 15)
    random_pokemon_id = random.number(min, max)

    # staticID for testing layout.
    # random_pokemon_id = str(62)

    # Pokemon Data
    pokemon = get_pokemon(random_pokemon_id)
    species = get_species(random_pokemon_id)
    if not pokemon or not species:
        return render_message("Pokédex data unavailable", bgColor, fontColor)

    pokemonName = pokemon["name"].title()

    pokemonRawFlavorText = ""
    for flavor_entry in species["flavor_text_entries"]:
        if type(flavor_entry) != "dict" or type(flavor_entry.get("language")) != "dict":
            continue
        if flavor_entry["language"].get("name") == "en" and type(flavor_entry.get("flavor_text")) == "string":
            pokemonRawFlavorText = flavor_entry["flavor_text"]
            break
    flavor_text = pokemonRawFlavorText.replace("\n", " ")

    imageSize = 36 * scale

    # Get the Pokémon sprite. Check if there is an animated version available, if not revert to the default.
    sprites = pokemon["sprites"]
    spriteURL = sprites.get("versions", {}).get("generation-v", {}).get("black-white", {}).get("animated", {}).get("front_default")
    if spriteURL == None:
        spriteURL = sprites.get("front_default")
        # Set the animated image size to be slightly smaller so animations don't get cropped.

    else:
        imageSize = 30 * scale

    pokemonSprite = get_cacheable_data(spriteURL)
    if not pokemonSprite:
        return render_message("Pokédex image unavailable", bgColor, fontColor)
    pokemonImage = render.Image(src = pokemonSprite, width = imageSize, height = imageSize, hold_frames = scale)

    return render.Root(
        delay = 70 // scale,
        child = render.Box(
            child = render.Stack(
                children = [
                    render.Column(
                        children = [
                            render.Marquee(width = 45 * scale, child = render.Text(pokemonName, color = fontColor)),
                            render.Text("#" + str(random_pokemon_id), font = "terminus-24" if is2x else "6x13", color = fontColor),
                        ],
                        expanded = True,
                        main_align = "start",
                    ),
                    render.Column(
                        children = [
                            render.Marquee(
                                child = render.Text(flavor_text, color = fontColor, font = "terminus-14-light" if is2x else "tb-8"),
                                width = canvas.width(),
                                offset_start = canvas.width() // 2,
                                offset_end = canvas.width() // 2,
                            ),
                        ],
                        expanded = True,
                        main_align = "end",
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 28 * scale, height = 32 * scale),  # used for padding
                            render.Box(child = pokemonImage, width = 30 * scale, height = 30 * scale, padding = 0),
                        ],
                        expanded = True,
                        main_align = "end",
                    ),
                ],
            ),
            padding = scale,
            color = bgColor,
        ),
    )

def get_schema():
    regions = ["National", "Kanto", "Johto", "Hoenn", "Sinnoh", "Unova", "Kalos", "Alola", "Galar", "Hisui", "Paldea"]
    regionOptions = []
    for region in regions:
        regionOptions.append(schema.Option(display = region, value = region))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "bgColor",
                name = "Background Color",
                desc = "The background color of your Pokédex",
                icon = "brush",
                default = DEFAULT_COLOR,
                palette = [
                    "#000019",
                    "#24000D",
                    "#000000",
                ],
            ),
            schema.Color(
                id = "fontColor",
                name = "Font Color",
                desc = "The font color of your Pokédex",
                icon = "brush",
                default = DEFAULT_FONT_COLOR,
                palette = [
                    "#FFFFFF",
                    "#FECA1C",
                ],
            ),
            schema.Dropdown(
                id = "region",
                name = "Pokédex Region",
                desc = "Select a Pokédex Region",
                icon = "map",
                default = DEFAULT_REGION,
                options = regionOptions,
            ),
        ],
    )

def get_pokemon(id):
    data = get_json(POKEMON_API.format(id))
    if type(data) != "dict" or type(data.get("name")) != "string" or type(data.get("sprites")) != "dict":
        return None
    return data

def get_species(id):
    data = get_json(POKEMON_SPECIES_API.format(id))
    if type(data) != "dict" or type(data.get("flavor_text_entries")) != "list":
        return None
    return data

def get_json(url):
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_JSON_BYTES or not body.startswith("{") or not body.endswith("}"):
        return None
    return json.decode(body, None)

def get_cacheable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    if type(url) != "string" or not url.startswith(SPRITE_PREFIX):
        return None
    res = http.get(url, ttl_seconds = ttl_seconds)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_IMAGE_BYTES:
        return None
    return body

def render_message(message, background, color):
    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            color = background,
            child = render.WrappedText(message, color = color, align = "center"),
        ),
    )
