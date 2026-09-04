"""
Applet: NES Quotes
Summary: Random NES quotes
Description: Displays random quotes from Nintendo Entertainment System games.
Author: Mark McIntyre
"""

load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

CSV_ENDPOINT = "https://gist.githubusercontent.com/markmcintyre/b39cf560d7e66bc0b987f809ca4a568f/raw/4a24f8658bc319abb53ffcbe3af21b0c9e25f2e0/nes-quotes.csv"
GAME_COL = 0
QUOTE_COL = 1
SPRITE_COL = 2
BG_COLOR = "#333"
ANIMATION_SPEED = 200
CACHE_TTL = 604800

GAMES = [
    "Bubble Bobble",
    "Castlevania II: Simon's Quest",
    "Dragon Warrior",
    "Final Fantasy",
    "Kid Icarus",
    "Metal Gear",
    "Pro Wrestling",
    "Star Tropics",
    "Super Mario Bros.",
    "Super Mario Bros. 3",
    "The Legend of Zelda",
    "Zelda II: The Adventures of Link",
]

GAME_IDS = {
    "Bubble Bobble": "bubble_bobble",
    "Castlevania II: Simon's Quest": "castlevania_ii_simons_quest",
    "Dragon Warrior": "dragon_warrior",
    "Final Fantasy": "final_fantasy",
    "Kid Icarus": "kid_icarus",
    "Metal Gear": "metal_gear",
    "Pro Wrestling": "pro_wrestling",
    "Star Tropics": "star_tropics",
    "Super Mario Bros.": "super_mario_bros",
    "Super Mario Bros. 3": "super_mario_bros_3",
    "The Legend of Zelda": "the_legend_of_zelda",
    "Zelda II: The Adventures of Link": "zelda_ii_the_adventures_of_link",
}

# Version 1 accidentally used only the final character, coupling two pairs of games.
LEGACY_IDS = {game: game.lower().elems()[-1] for game in GAMES}

# GET DATA
# --------
def get_data():
    request = http.get(CSV_ENDPOINT, ttl_seconds = CACHE_TTL)
    if request.status_code != 200:
        print("Unexpected status code: {}".format(request.status_code))
        return []

    rows = csv.read_all(request.body(), skip = 1)
    return [
        row
        for row in rows
        if len(row) == 3 and row[GAME_COL] in GAME_IDS and row[QUOTE_COL] != "" and len(row[SPRITE_COL]) <= 65536
    ]

# FILTER_DATA
# -----------
def filter_data(config, data):
    result = []
    for index in range(0, len(data)):
        game = data[index][GAME_COL]
        game_id = GAME_IDS[game]
        configured = config.get(game_id)
        if config.bool(game_id, True) if configured != None else config.bool(LEGACY_IDS[game], True):
            result.append(data[index])

    return result

# MAIN
# ----
def main(config):
    nes_quotes = filter_data(config, get_data())
    sprite_position = config.str("sprite_position", "random")

    # If there are no quotes, skip rendering
    if len(nes_quotes) <= 0:
        return []

    # Randomly grab a quote and layout its sprite and quote as wrapped text
    index = random.number(0, len(nes_quotes) - 1)
    children = [
        render.Image(src = base64.decode(nes_quotes[index][SPRITE_COL])),
        render.Marquee(
            height = 32,
            align = "center",
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(
                content = nes_quotes[index][QUOTE_COL],
                align = "center",
                width = 45,
            ),
            scroll_direction = "vertical",
        ),
    ]

    # If the user prefers the image on the right, or if the position is random, swap the order
    if sprite_position == "right" or (sprite_position == "random" and random.number(0, 1)):
        children = reversed(children)

    # Render our quote with a 200ms animation rate
    return render.Root(
        child = render.Box(
            color = BG_COLOR,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
        delay = ANIMATION_SPEED,
    )

# SCHEMA
# ------
def get_schema():
    fields = [
        schema.Dropdown(
            id = "sprite_position",
            name = "Image Position",
            desc = "Where to display the image relative to the quote",
            icon = "rightLeft",
            default = "random",
            options = [
                schema.Option(
                    display = "Random",
                    value = "random",
                ),
                schema.Option(
                    display = "Left",
                    value = "left",
                ),
                schema.Option(
                    display = "Right",
                    value = "right",
                ),
            ],
        ),
    ]

    for game in GAMES:
        fields.append(
            schema.Toggle(
                id = GAME_IDS[game],
                name = game,
                desc = "Show quotes from " + game,
                icon = "gamepad",
                default = True,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )
