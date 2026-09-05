"""
Applet: Random Pokedex
Summary: Random Pokedex entry
Description: Display a random Pokemon along with its typing and optional shiny version.
Author: Kerry Bassett
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

NUM_POKEMON = 1025
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
SPRITE_PREFIX = "https://raw.githubusercontent.com/PokeAPI/sprites/"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.
REFRESH_SECONDS = 300
MAX_JSON_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024

TYPE_COLORS = {
    "normal": "#AA9",
    "fire": "#F40",
    "water": "#39F",
    "electric": "#FC3",
    "grass": "#7C5",
    "ice": "#6CF",
    "fighting": "#B54",
    "poison": "#A59",
    "ground": "#DB5",
    "flying": "#89F",
    "psychic": "#F59",
    "bug": "#AB2",
    "rock": "#BA6",
    "ghost": "#66B",
    "dragon": "#76E",
    "dark": "#754",
    "steel": "#AAB",
    "fairy": "#E9E",
    "": "#000",
}

def main(config):
    is2x = canvas.is2x()
    scale = 2 if is2x else 1
    random.seed(time.now().unix // REFRESH_SECONDS)
    id_ = random.number(1, NUM_POKEMON)
    pokemon = get_pokemon(id_)
    if pokemon == None:
        return message("Pokémon unavailable")
    name = pokemon.get("name", "")
    types = pokemon.get("types", [])
    sprites = pokemon.get("sprites", {})
    other = sprites.get("other", {}) if type(sprites) == "dict" else {}
    home = other.get("home", {}) if type(other) == "dict" else {}
    if type(name) != "string" or not name or type(types) != "list" or len(types) == 0 or type(sprites) != "dict":
        return message("Pokémon unavailable")
    name = name[:32].title()
    type1 = pokemon_type(types[0])
    type2 = ""
    numTypes = len(types)
    shiny = config.bool("shiny", False)
    sprite_url = sprites.get("front_shiny") if shiny else sprites.get("front_default")
    if not sprite_url and type(home) == "dict":
        sprite_url = home.get("front_shiny") if shiny else home.get("front_default")
    if not sprite_url and type(other) == "dict":
        artwork = other.get("official-artwork", {})
        if type(artwork) == "dict":
            sprite_url = artwork.get("front_shiny") if shiny else artwork.get("front_default")

    if numTypes > 1:
        type2 = pokemon_type(types[1])

    sprite = get_image(sprite_url)
    if sprite == None:
        return message("Sprite unavailable")

    return render.Root(
        max_age = REFRESH_SECONDS,
        child = render.Stack(
            children = [
                render.Row(
                    # Pokemon image
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(width = 43 * scale),
                        render.Column(
                            children = [
                                render.Box(height = 10 * scale),
                                render.Image(
                                    src = sprite,
                                    width = 20 * scale,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "space_between",
                    expanded = True,
                    children = [
                        render.Box(
                            # Pokemon name
                            width = canvas.width(),
                            height = 10 * scale,
                            color = config.str("titleBackground", "#999"),
                            child = render.Marquee(
                                scroll_direction = "horizontal",
                                width = 60 * scale,
                                child = render.Text(
                                    content = "# " + str(id_) + " | " + name.upper(),
                                    color = config.str("titleForeground", "#000"),
                                    font = "terminus-18" if is2x else "tb-8",
                                ),
                            ),
                        ),
                        render.Box(
                            # Pokemon type 1
                            width = 42 * scale,
                            height = 10 * scale,
                            padding = 1 * scale,
                            color = TYPE_COLORS.get(type1, "#000"),
                            child = render.Text(
                                content = type1.upper(),
                                color = "#000",
                                font = "terminus-18" if is2x else "CG-pixel-3x5-mono",
                            ),
                        ),
                        render.Box(
                            # Pokemon type 2
                            width = 42 * scale,
                            height = 10 * scale,
                            padding = 1 * scale,
                            color = TYPE_COLORS.get(type2, "#000"),
                            child = render.Text(
                                content = type2.upper(),
                                color = "#000",
                                font = "terminus-18" if is2x else "CG-pixel-3x5-mono",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "titleBackground",
                name = "Title Background",
                desc = "Color of title background.",
                icon = "brush",
                default = "#999",
            ),
            schema.Color(
                id = "titleForeground",
                name = "Title Foreground",
                desc = "Color of title foreground.",
                icon = "brush",
                default = "#FFF",
            ),
            schema.Toggle(
                id = "shiny",
                name = "Shiny Pokemon",
                desc = "Show shiny variant of Pokemon",
                icon = "star",
                default = False,
            ),
        ],
    )

def get_pokemon(id):
    url = POKEAPI_URL.format(id)
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    data = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_JSON_BYTES else None
    return data if type(data) == "dict" else None

def get_image(url):
    if type(url) != "string" or not url.startswith(SPRITE_PREFIX):
        return None
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    return body if res.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else None

def pokemon_type(entry):
    value = entry.get("type", {}) if type(entry) == "dict" else {}
    name = value.get("name", "") if type(value) == "dict" else ""
    return name.lower() if type(name) == "string" and name.lower() in TYPE_COLORS else ""

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, align = "center")))
