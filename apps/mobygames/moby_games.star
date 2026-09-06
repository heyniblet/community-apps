"""
Applet: Moby Games
Summary: Game info from MobyGames
Description: Display information about random games from the extensive MobyGames database. Includes basic information such as a thumbnail, year of release, etc.
Author: pandincus

MobyGames API documentation: https://www.mobygames.com/info/api/
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Root url for the Moby Games API
MOBY_GAMES_API_ROOT_URL = "https://api.mobygames.com/v1/"

# Random games API endpoint
# See docs here: https://www.mobygames.com/info/api/#gamesrandom
RANDOM_GAMES_API = MOBY_GAMES_API_ROOT_URL + "games/random?api_key={api_key}&limit=100&format=normal"

### -------------------------------------------------- ###
###                   Helper functions                 ###
### -------------------------------------------------- ###
def debug_print(debug, string):
    """Prints a string to the console, but only if the debug parameter is set to true

    Args:
        debug (bool): whether or not debug mode is enabled, which determines whether or not to print
        string (str): the string to print

    Returns:
        None
    """
    if debug:
        print(string)

def load_random_games(api_key, debug = False):
    """Loads random games from the MobyGames API.

    Args:
        api_key (str): the API key to use when making requests to the MobyGames API
        debug (bool): whether or not debug mode is enabled, which determines whether or not to print log messages
    Returns:
        A dict of games, where the key is the game_id, and each object is a dict containing information about the game
    """
    response = http.get(RANDOM_GAMES_API.format(api_key = humanize.url_encode(api_key)))
    if response.status_code != 200:
        # If the call failed, print the error code to debug (if we're debugging), and return an empty dict
        debug_print(debug, "[HTTP] Moby Games API returned non-200 status code: " + str(response.status_code))
        return {}

    # Decode the response
    response_json = response.json()
    if response_json == None:
        # If the decode failed, print a message to debug (if we're debugging), and return an empty dict
        debug_print(debug, "[HTTP] Failed to decode response from Moby Games API")
        return {}

    # Construct a dict of dicts containing information about each game
    # We specifically are interested in the following fields:
    # * title - the title of the game
    # * description - a long description of the game
    # * moby_score - the MobyScore of the game
    # * platforms - a list of platforms the game is available on (note: each platform is a dict containing a platform_name and first_release_date)
    # * sample_cover - a dict containing information about the game's cover art (note: this is a dict containing only one field we care about: thumbnail_image

    # Construct a dict of dicts containing information about each game
    games = {}
    for game in response_json.get("games") or []:
        if not game.get("game_id") or not game.get("title"):
            continue

        # Construct a dict containing information about the game
        game_info = {}
        game_info["id"] = str(game["game_id"])
        game_info["title"] = game["title"]
        game_info["description"] = game.get("description") or "No description available."
        game_info["moby_score"] = game.get("moby_score")
        game_info["platforms"] = []

        # Add information about each platform the game is available on
        for platform in game.get("platforms") or []:
            if not platform.get("platform_name") or not platform.get("first_release_date"):
                continue
            game_info["platforms"].append({
                "platform_name": platform["platform_name"],
                "first_release_date": platform["first_release_date"],
            })

        # Add information about the game's cover art
        game_info["thumbnail_image"] = (game.get("sample_cover") or {}).get("thumbnail_image")

        # Add the game to the games dict, keyed by the game ID
        games[game_info["id"]] = game_info

    return games

def render_message(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.WrappedText(content = message, width = 60, align = "center")],
        ),
    )

def render_output(title, moby_score, description, first_platform_name, first_platform_release_date, image_content):
    """Return the rendered output for the given game information
    """

    # Construct the output
    # That should be a row with two columns, where the left column is the thumbnail image, and the right column is the game title
    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [image_content],
                ),
                render.Column(
                    children = [
                        # Inside of a colored box, display the title and moby score in a marquee, like so: "Title (7.8)"
                        render.Box(
                            width = 40,
                            height = 8,
                            color = "#540007",
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    font = "tb-8",
                                    content = title + " (" + moby_score + ")",
                                ),
                            ),
                        ),
                        # Display the description in a vertical scrolling marquee
                        render.Marquee(
                            height = 19,
                            scroll_direction = "vertical",
                            child = render.WrappedText(
                                font = "CG-pixel-4x5-mono",
                                width = 40,
                                content = description,
                            ),
                        ),
                        # Inside of a colored box, display the first platform and release date in a scrolling marquee, like so: "Platform (YYYY-MM-DD)"
                        render.Box(
                            width = 40,
                            height = 5,
                            color = "#540007",
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    font = "CG-pixel-4x5-mono",
                                    content = first_platform_name + " " + first_platform_release_date + " | Data by MobyGames.com",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

### -------------------------------------------------- ###
###                  Main Applet Logic                 ###
### -------------------------------------------------- ###
def main(config):
    """Main function, invoked by the Pixlet runtime

    Args:
      config (dict): a dictionary of configuration parameters, passed in by the Pixlet runtime
                     The following parameters are supported:
                        - api_key: the API key to use when making requests to the MobyGames API when running locally
                        - debug: whether or not to print debug statements to the console (set to true to enable)
                        - bypass_cache: whether or not to bypass the cache and make a network request directly to the MobyGames API
                     Supply the config parameter when using the pixlet render command
                        For example, pixlet render moby_games.star api_key=my_api_key debug=true
                     Or, when using the pixlet serve command, you can pass the same paramters via query string
                        For example, http://localhost:8080/?api_key=my_api_key&debug=true

    Returns:
        render.Root: The rendered output
    """

    # Load the config parameters
    debug = config.get("debug") != None and config.get("debug").lower() == "true"
    api_key = config.get("api_key")
    if not api_key:
        return render_message("Add a MobyGames API key to show random games.")

    games = load_random_games(api_key, debug)

    # Pick a random game from the list of games
    game_ids_list = games.keys()
    random_game = {}
    if len(game_ids_list) == 0:
        return render_message("MobyGames data is unavailable.")
    else:
        random_game_index = random.number(0, len(game_ids_list) - 1)
        random_game_id = game_ids_list[random_game_index]
        random_game = games[random_game_id]

    debug_print(debug, "[Main] Selected game: " + json.encode(random_game))

    # Compute the first platform by looking at all platforms the game is available on, and picking the earliest date
    # Note that the dates are represented as strings in ISO 8601 YYYY-MM-DD format, which is lexicographically sortable,
    # so we can just sort the list of dates and pick the first one
    first_platform = None
    for platform in random_game.get("platforms") or []:
        if first_platform == None or platform["first_release_date"] < first_platform["first_release_date"]:
            first_platform = platform
    if first_platform == None:
        first_platform = {"platform_name": "Unknown platform", "first_release_date": ""}

    # Use the html library to clean up the text from the title and description
    # This should strip out html tags, and convert encoded html entities to their decoded values
    description_html = html(random_game.get("description") or "No description available.")
    description = description_html.text()
    title_html = html(random_game["title"])
    title = title_html.text()

    image_content = render.Box(width = 24, height = 32, color = "#540007")
    thumbnail_image = random_game.get("thumbnail_image")
    if thumbnail_image:
        image_response = http.get(thumbnail_image)
        if image_response.status_code == 200:
            image_content = render.Image(src = image_response.body(), width = 24, height = 32)

    game_for_render = {
        "title": title,
        "moby_score": str(random_game.get("moby_score") or "N/A"),
        "description": description,
        "platform_name": first_platform["platform_name"],
        "first_release_date": first_platform["first_release_date"],
        "image_content": image_content,
    }

    return render_output(
        title = game_for_render["title"],
        moby_score = game_for_render["moby_score"],
        description = game_for_render["description"],
        first_platform_name = game_for_render["platform_name"],
        first_platform_release_date = game_for_render["first_release_date"],
        image_content = game_for_render["image_content"],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "MobyGames API Key",
                desc = "A MobyGames API key whose plan permits this use.",
                icon = "key",
                secret = True,
            ),
        ],
    )
