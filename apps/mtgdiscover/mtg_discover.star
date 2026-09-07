"""
Applet: MTG Discover
Summary: Discover random MTG cards
Description: Cycles through and displays information about random Magic: The Gathering cards.
Author: Staghouse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ONE_MIN_TTL = 60
APP_FONT = "tb-8"
SCRYFALL_HEADERS = {
    "Accept": "application/json;q=0.9,*/*;q=0.8",
    "User-Agent": "Niblet/1.0 (+https://heyniblet.com)",
}

# Main application function
def main(config):
    # Fetched card
    card = get_scryfall_card()

    # Schema config
    show_prices = config.bool("prices")
    show_rarity = config.bool("rarity")

    if card == False:
        return render.Root(
            child = render.Box(
                padding = 1,
                height = 28,
                child = render.Column(
                    children = [
                        render.WrappedText(
                            content = "MTG Discover",
                        ),
                        render_line_break(),
                        render.WrappedText(
                            color = "#999",
                            content = "No cards found...",
                        ),
                    ],
                ),
            ),
        )

    # Main root render
    return render.Root(
        delay = 100,
        max_age = 30,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Padding(
                            pad = (1, 0, 1, 0),
                            child = render.Marquee(
                                width = 62,
                                offset_start = 62,
                                child = render_card_name_cost(card),
                            ),
                        ),
                        render_line_break("#999", (1, 0, 1, 1)),
                    ],
                ),
                render.Padding(
                    pad = (1, 0, 1, 1),
                    child = render.Marquee(
                        height = 18,
                        offset_start = 18,
                        scroll_direction = "vertical",
                        child = render.Column(
                            children = render_details(card, show_rarity, show_prices) + [render_line_break()] + render_details(card, show_rarity, show_prices),
                        ),
                    ),
                ),
            ],
        ),
    )

# Render a line break
def render_line_break(color = "#333", padding = (0, 1, 0, 1)):
    return render.Row(
        expanded = True,
        main_align = "center",
        children = [
            render.Padding(
                pad = padding,
                child = render.Box(
                    color = color,
                    height = 1,
                ),
            ),
        ],
    )

# Set render for creature power/toughness
def render_creature_properties(card):
    creature_properties = None

    if card["power"] != "" or card["toughness"] != "":
        creature_properties = render.WrappedText(
            font = APP_FONT,
            content = "(" + card["power"] + "/" + card["toughness"] + ")",
        )

    return creature_properties

# Render card name and cost
def render_card_name_cost(card):
    card_name_cost = []

    if card["mana_cost"] != "":
        card_name_cost.append(
            render.Padding(
                pad = (0, 1, 2, 0),
                child = render.Text(
                    content = card["mana_cost"],
                    font = "tom-thumb",
                ),
            ),
        )

    card_name_cost.append(
        render.Padding(
            pad = (0, 2, 3, 2),
            child = render.Text(
                font = APP_FONT,
                content = card["name"],
            ),
        ),
    )

    return render.Row(
        children = card_name_cost,
    )

# Render card details
def render_details(card, show_rarity, show_prices):
    return [
        render.WrappedText(
            font = APP_FONT,
            content = card["type"],
        ),
        render_creature_properties(card),
        render_line_break(),
        render_rarity(card["rarity"], show_rarity),
        render.WrappedText(
            font = APP_FONT,
            content = card["set"],
        ),
        render_prices(card, show_prices),
    ]

# Render card prices
def render_prices(card, show):
    prices = []

    # Config wants no prices
    if show == False:
        return render.Column(
            children = prices,
        )

    prices.append(
        render_line_break("#333", (0, 2, 0, 2)),
    )

    # Set normal price
    if card["price"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Normal: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price"],
                ),
            ],
        ))

    # Set foil price
    if card["price_foil"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Foil: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price_foil"],
                ),
            ],
        ))

    # Set etched foil price
    if card["price_etched"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Etched: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price_etched"],
                ),
            ],
        ))

    # Set no available prices
    if len(prices) == 0:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Prices ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = "N/A",
                ),
            ],
        ))

    return render.Column(
        children = prices,
    )

# Rnder card rarity
def render_rarity(rarity, show):
    if show != False:
        rarity_color = "#fff"

        if rarity == "uncommon":
            rarity_color = "#dedede"

        if rarity == "rare":
            rarity_color = "#d5d03a"

        if rarity == "mythic" or rarity == "bonus":
            rarity_color = "#d5623a"

        if rarity == "special":
            rarity_color = "#a03ad5"

        return render.Column(
            children = [
                render.WrappedText(
                    font = APP_FONT,
                    color = rarity_color,
                    content = rarity[0].upper() + rarity[1:],
                ),
                render_line_break(),
            ],
        )

    else:
        return None

# Fetch a random card from Scryfall and return wanted data
def get_scryfall_card():
    text = ""
    mana_cost = ""
    power = ""
    toughness = ""
    type_line = ""
    price_usd = None
    price_usd_foil = None
    price_usd_etched = None

    response = http.get("https://api.scryfall.com/cards/random", headers = SCRYFALL_HEADERS, ttl_seconds = ONE_MIN_TTL)

    if response.status_code != 200:
        return False

    card = json.decode(response.body(), None)
    if type(card) != "dict" or card.get("object") != "card":
        return False

    if type(card.get("oracle_text")) == "string":
        text = card["oracle_text"]

    if type(card.get("type_line")) == "string":
        type_line = card["type_line"]

    if type(card.get("mana_cost")) == "string":
        mana_cost = card["mana_cost"]

    if type(card.get("power")) == "string":
        power = card["power"]

    if type(card.get("toughness")) == "string":
        toughness = card["toughness"]

    prices = card.get("prices") if type(card.get("prices")) == "dict" else {}
    if type(prices.get("usd")) == "string" and prices["usd"] != "":
        price_usd = "$" + prices["usd"]

    if type(prices.get("usd_foil")) == "string" and prices["usd_foil"] != "":
        price_usd_foil = "$" + prices["usd_foil"]

    if type(prices.get("usd_etched")) == "string" and prices["usd_etched"] != "":
        price_usd_etched = "$" + prices["usd_etched"]

    return {
        "name": card.get("name") if type(card.get("name")) == "string" else "Unknown card",
        "type": type_line,
        "text": text,
        "rarity": card.get("rarity") if type(card.get("rarity")) == "string" else "unknown",
        "set": card.get("set_name") if type(card.get("set_name")) == "string" else "Unknown set",
        "power": power,
        "toughness": toughness,
        "price": price_usd,
        "price_foil": price_usd_foil,
        "price_etched": price_usd_etched,
        "mana_cost": mana_cost,
    }

# Schema config for the application
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "rarity",
                name = "Show rarity",
                desc = "A toggle to display the card rarity.",
                icon = "rankingStar",
                default = True,
            ),
            schema.Toggle(
                id = "prices",
                name = "Show prices",
                desc = "A toggle to display the card prices.",
                icon = "dollarSign",
                default = True,
            ),
        ],
    )
