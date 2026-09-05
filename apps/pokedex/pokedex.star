"""
Applet: Pokedex
Summary: Display a random Pokemon
Description: Display a random Pokemon along with its height and weight.
Author: Mack Ward
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

NUM_POKEMON = 386
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.
MAX_JSON_BYTES = 1048576
MAX_IMAGE_BYTES = 1048576
SPRITE_PREFIX = "https://raw.githubusercontent.com/PokeAPI/sprites/"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "metric",
                name = "Use metric units",
                desc = "Which measurement system to use.",
                icon = "ruler",
                default = True,
            ),
        ],
    )

def main(config):
    id_ = random.number(1, NUM_POKEMON)
    pokemon = get_pokemon(id_)
    if not pokemon:
        return render_message("Pokémon data unavailable")
    name = pokemon["name"].title()
    height = pokemon["height"] / 10
    weight = pokemon["weight"] / 10

    if config.bool("metric"):
        height = "%s m" % height
        weight = "%s kg" % weight
    else:
        height = "%s ft" % round(height * 3.281)
        weight = "%s lbs" % round(weight * 2.205)

    sprites = pokemon["sprites"]
    sprite_url = sprites.get("versions", {}).get("generation-vii", {}).get("icons", {}).get("front_default") or sprites.get("front_default")
    sprite = get_image(sprite_url)
    if not sprite:
        return render_message("Pokémon image unavailable")
    sprite_img = render.Image(sprite)
    sprite_width, _ = sprite_img.size()
    sprite_width *= 2 if canvas.is2x() else 1

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(width = canvas.width() // 2),
                        render.Box(render.Image(sprite, width = sprite_width)),
                    ],
                ),
                render.Column(
                    children = [
                        render.Text(name),
                        render.Text("# " + str(id_)),
                        render.Text(height),
                        render.Text(weight),
                    ],
                ),
            ],
        ),
    )

def round(num):
    """Rounds floats to a single decimal place."""
    return float(int(num * 10) / 10)

def get_pokemon(id):
    url = POKEAPI_URL.format(id)
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_JSON_BYTES or not body.startswith("{") or not body.endswith("}"):
        return None
    data = json.decode(body, None)
    if type(data) != "dict" or type(data.get("name")) != "string" or type(data.get("height")) not in ("int", "float") or type(data.get("weight")) not in ("int", "float") or type(data.get("sprites")) != "dict":
        return None
    return data

def get_image(url):
    if type(url) != "string" or not url.startswith(SPRITE_PREFIX):
        return None
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_IMAGE_BYTES:
        return None
    return body

def render_message(message):
    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            child = render.WrappedText(message, align = "center"),
        ),
    )
