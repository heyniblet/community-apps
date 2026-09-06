"""
Applet: Playdate Sales
Summary: See Playdate games on sale
Description: Check what's on sale over in the Playdate Catalog.
Author: UnBurn
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

SALES_URL = "https://play.date/games/tags/on-sale/"

PLAYDATE_YELLOW = "#FFC500"
TTL_TIME = 43200

def get_text_size_for_price(txt):
    return len(txt[1:]) * 4

def get_games_on_sale():
    response = http.get(SALES_URL, ttl_seconds = TTL_TIME)
    if response.status_code != 200:
        print("Playdate sale list failed with status %d" % response.status_code)
        return []
    sales_page = response.body()
    if len(sales_page) > 524288:
        print("Playdate sale list was too large")
        return []
    games = []

    games_node = bsoup.parseHtml(sales_page).find("ul", {"class": "gameCards"})
    for game_item in games_node.find_all("li")[:100] if games_node != None else []:
        link = game_item.find("a")
        title = game_item.find("h2", {"class": "gameTitle"})
        title_link = title.find("a") if title != None else None
        image = game_item.find("div", {"class": "gameCardImage"})
        prices = game_item.find("span", {"class": "prices"})
        retail = prices.find("s") if prices != None else None
        sale = prices.find("span", {"class": "discountedPrice"}) if prices != None else None
        url = link.attrs().get("href", "") if link != None else ""
        style = image.attrs().get("style", "") if image != None else ""
        marker = "url('"
        image_url = style[style.find(marker) + len(marker):].rstrip("')") if marker in style else ""
        if not url.startswith("/games/") or not image_url.startswith("https://play.date/media/") or title_link == None or retail == None or sale == None:
            continue
        name = title_link.get_text().strip()
        retail_price = retail.get_text().strip()
        sale_price = sale.get_text().strip()
        if not name or not sale_price:
            continue

        games.append({
            "image": image_url,
            "name": name[:120],
            "retail_price": retail_price[:20],
            "sale_price": sale_price[:20],
        })

    return games

def get_image_data(url):
    response = http.get(url, ttl_seconds = TTL_TIME)
    body = response.body()
    if response.status_code != 200 or len(body) > 4194304:
        print("Playdate screenshot failed with status %d" % response.status_code)
        return None
    return body

def main(config):
    show_retail_price = config.bool("show_retail")
    games_on_sale = get_games_on_sale()

    if len(games_on_sale) == 0:
        return render_message("No Playdate sales")

    selected_game = games_on_sale[random.number(0, len(games_on_sale) - 1)]
    gif_data = get_image_data(selected_game["image"])
    if not gif_data:
        return render_message(selected_game["name"])

    stickers = []
    size_of_sticker = 6 + get_text_size_for_price(selected_game["sale_price"])
    if show_retail_price:
        size_of_sticker = size_of_sticker + (6 + get_text_size_for_price(selected_game["retail_price"]))
        stickers.append(render.Text(content = selected_game["retail_price"], color = PLAYDATE_YELLOW))
    stickers.append(render.Text(content = selected_game["sale_price"], color = "#ff0000"))

    sticker = render.Row(children = stickers)
    return render.Root(
        delay = 20,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 6, 0, 0),
                    color = PLAYDATE_YELLOW,
                    child = render.Image(src = gif_data, width = 64, height = 26),
                ),
                render.Marquee(
                    child = render.Padding(
                        child = render.Text(content = selected_game["name"], font = "tom-thumb", color = "#000000"),
                        pad = (1, 0, 0, 0),
                    ),
                    width = 64,
                    delay = 30,
                ),
                render.Padding(
                    pad = (64 - size_of_sticker, 24, 0, 0),
                    child = sticker,
                ),
            ],
        ),
    )

def render_message(text):
    return render.Root(
        child = render.WrappedText(
            content = text[:120],
            font = "tom-thumb",
            color = PLAYDATE_YELLOW,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_retail",
                name = "Show retail price?",
                desc = "Show retail price as well as the sale price.",
                icon = "dollarSign",
                default = False,
            ),
        ],
    )
