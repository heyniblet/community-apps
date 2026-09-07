"""
Applet: BGG Last Play
Summary: Days since last bgg play
Description: Counts up the number of days since the last time the given user has recorded a game play on Board Game Geek.
Author: DanDobrick
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

EXAMPLE_USERNAME = "zefquaavius"  # User named from the API docs, luckily has lots of recent plays
BGG_PLAYS_API_URL = "https://boardgamegeek.com/xmlapi2/plays?username={}"
BGG_THING_API_URL = "https://boardgamegeek.com/xmlapi2/thing?id={}"
DEFAULT_TIMEZONE = "America/New_York"
DEMO_GAME_ID = 13
DEMO_GAME_NAME = "Catan"
HTTP_CACHE_TTL = 3 * 60 * 60  # 3 hours

# Used for fetching game images, which are cached for longer
HTTP_CACHE_TTL_LONG = 72 * 60 * 60  # 72 hours
MAX_XML_BYTES = 2 * 1024 * 1024
MAX_IMAGE_BYTES = 8 * 1024 * 1024

def main(config):
    api_key = config.get("bgg_api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return render.Root(child = render.WrappedText(content = "BGG API key required", align = "center"))

    bgg_username = config.str("bgg_username")

    if (bgg_username == None or bgg_username == ""):
        return demo(config, api_key)
    if len(bgg_username) > 80 or "\r" in bgg_username or "\n" in bgg_username:
        return render.Root(child = error_message("Invalid username"))

    last_play_data = get_last_play_data(bgg_username, api_key)
    if last_play_data == None:
        return render.Root(child = error_message())
    last_play_date = last_play_data.query("//plays/play/@date")

    if last_play_date == None:
        return render.Root(child = error_message())
    else:
        last_play_id = last_play_data.query("//plays/play/item/@objectid")
        last_play_game = last_play_data.query("//plays/play/item/@name")
        if type(last_play_date) != "string" or len(last_play_date) != 10 or type(last_play_game) != "string":
            return render.Root(child = error_message())
        game_image = get_image(last_play_id, api_key)

        if game_image == None:
            game_image = ""

        return render_main(config, game_image, last_play_date, last_play_game[:240])

def get_last_play_data(bgg_username, api_key):
    encoded_username = humanize.url_encode(bgg_username)
    resp = http.get(BGG_PLAYS_API_URL.format(encoded_username), headers = {"Authorization": "Bearer " + api_key})

    if resp.status_code != 200:
        return None
    body = resp.body()
    return xpath.loads(body) if len(body) <= MAX_XML_BYTES else None

def get_image(game_id, api_key):
    if game_id == None:
        game_id = DEMO_GAME_ID
    game_id = str(game_id)
    if not game_id.isdigit() or len(game_id) > 20:
        return None

    resp = http.get(BGG_THING_API_URL.format(game_id), headers = {"Authorization": "Bearer " + api_key})

    if resp.status_code == 200:
        body = resp.body()
        if len(body) > MAX_XML_BYTES:
            return None
        xml_content = xpath.loads(body)
        image_url = xml_content.query("//item/image")

        if type(image_url) != "string" or not image_url.startswith("https://cf.geekdo-images.com/"):
            return None
        response = http.get(image_url, ttl_seconds = HTTP_CACHE_TTL_LONG)
        image = response.body()
        return image if response.status_code == 200 and len(image) <= MAX_IMAGE_BYTES else None
    else:
        return None

def num_days_since(last_play_date, timezone):
    current_time = time.now().in_location(timezone)
    parsed_last_play = time.parse_time(last_play_date, format = "2006-01-02")
    date_diff = current_time - parsed_last_play

    return math.floor(date_diff.hours // 24)

def build_days_since_str(last_play_date, timezone):
    if last_play_date == None:
        return "No plays found"
    else:
        days_since = num_days_since(last_play_date, timezone)

        if days_since == 1:
            return "1 day since"
        else:
            return "{} days since".format(days_since)

def build_last_play(config, last_play_date, last_play_game):
    timezone = time.tz()
    label_choice = config.get("label")
    days_since_str = build_days_since_str(last_play_date, timezone)

    children = [
        render.Box(
            color = "#0000FF00",
            height = 1,
        ),
    ]

    if label_choice == "last_play_label":
        children.append(
            render.Padding(
                pad = (1, 1, 5, 0),
                color = "#00000099",
                child = render.WrappedText("Last Play:"),
            ),
        )
    elif label_choice == "days_since_last_play":
        children.append(
            render.Padding(
                pad = (1, 1, 1, 0),
                color = "#00000099",
                child = render.WrappedText(days_since_str),
            ),
        )

    children.append(
        render.Padding(
            pad = (1, 1, 0, 0),
            color = "#00000099",
            child = render.WrappedText(last_play_game),
        ),
    )

    return children

def render_main(config, game_image, last_play_date, last_play_game):
    children = []
    if game_image:
        children.append(render.Image(height = 35, width = 35, src = game_image))

    children.append(render.Box(
        color = "#00FF0000",
        child = render.Padding(
            pad = (0, 0, 0, 0),
            color = "#FF000000",
            child = render.Column(
                cross_align = "end",
                main_align = "start",
                expanded = False,
                children = build_last_play(config, last_play_date, last_play_game),
            ),
        ),
    ))

    return render.Root(
        child = render.Stack(
            children = children,
        ),
    )

def demo(config, api_key):
    timezone = time.tz()
    yesterday_long = time.now().in_location(timezone) - time.parse_duration("86400s")
    yesterday = yesterday_long.format("2006-01-02")
    game_image = get_image(DEMO_GAME_ID, api_key)

    return render_main(config, game_image, yesterday, DEMO_GAME_NAME)

def error_message(message = "Error fetching data"):
    return render.WrappedText(content = message, align = "center", font = "5x8", color = "#FF0000")

def get_schema():
    label_options = [
        schema.Option(
            display = "None",
            value = "none",
        ),
        schema.Option(
            display = "Days since last play",
            value = "days_since_last_play",
        ),
        schema.Option(
            display = "\"Last Play:\"",
            value = "last_play_label",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bgg_username",
                name = "BoardGameGeek username",
                desc = "BoardGameGeek username to use for fetching last play date",
                icon = "user",
            ),
            schema.Dropdown(
                id = "label",
                name = "Label",
                desc = "Label to display above the game name",
                default = label_options[0].value,
                icon = "tag",
                options = label_options,
            ),
            schema.Text(
                id = "bgg_api_key",
                name = "BoardGameGeek API key",
                desc = "Your BoardGameGeek API key. See https://boardgamegeek.com/using_the_xml_api for details.",
                icon = "key",
                secret = True,
            ),
        ],
    )
