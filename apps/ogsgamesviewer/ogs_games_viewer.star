"""
Applet: OGS Games Viewer
Summary: Shows OGS Games
Description: Shows a visualization of currently active Go games on OGS (Online Go Server) for a given user.
Author: Neal Wright
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Constants
NUM_OF_GAMES = 5
FRAMES = 50
SIZES = [9, 13, 19]
MAX_RESPONSE_BYTES = 512 * 1024
OGS_HEADERS = {"User-Agent": "Niblet/1.0 (heyniblet.com)"}
FAMOUS_GAMES = [
    {
        "state": [[0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 2, 0, 2, 0, 2, 2, 1, 0, 0], [0, 0, 2, 2, 0, 1, 0, 0, 2, 1, 1, 2, 2, 0, 2, 1, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0], [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 2, 2, 1, 1, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 1, 0, 1, 2, 0], [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 1, 2, 2, 0], [0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 1, 2, 0, 2, 1, 0, 0, 0], [0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 0, 1, 2, 1, 2, 1, 2, 0, 0], [0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 2, 2, 1, 2, 2, 0, 0], [0, 0, 0, 0, 0, 1, 2, 1, 2, 0, 2, 2, 1, 1, 1, 1, 2, 2, 0], [0, 0, 0, 0, 0, 0, 1, 2, 0, 2, 2, 0, 2, 1, 1, 0, 1, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 1, 0, 1, 0, 1, 0]],
        "opponent": "Honinbo Shusaku",
        "opp_color": "b",
        "width": 19,
        "height": 19,
    },
    {
        "state": [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 2, 1, 1, 0, 1, 0, 2, 0, 0, 2, 0, 0, 1, 0, 0, 0, 0], [0, 0, 2, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0], [0, 0, 0, 1, 1, 0, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0], [0, 0, 1, 1, 2, 2, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 1, 1, 2, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0], [0, 1, 2, 2, 2, 2, 0, 0, 1, 0, 0, 1, 0, 1, 0, 2, 0, 0, 0], [2, 2, 1, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
        "opponent": "Honinbo Jowa",
        "opp_color": "w",
        "width": 19,
        "height": 19,
    },
    {
        "state": [[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], [0, 1, 1, 1, 1, 2, 2, 0, 0, 0, 0, 0, 2, 2, 1, 0, 0, 0, 0], [0, 1, 2, 1, 2, 1, 0, 2, 2, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0], [0, 2, 2, 2, 2, 0, 1, 1, 2, 0, 2, 0, 0, 1, 0, 2, 1, 0, 0], [0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 1, 1, 1, 1, 2, 0, 0, 0], [0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 2, 1, 2, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2, 2, 1, 1, 1, 0, 0], [0, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 2, 0], [2, 0, 0, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0], [0, 2, 2, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 2, 0, 1, 2, 0, 0], [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 2, 0, 0], [0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 0], [0, 0, 2, 1, 2, 2, 1, 0, 0, 0, 0, 2, 0, 1, 1, 2, 1, 2, 0], [0, 0, 2, 0, 2, 1, 0, 0, 0, 0, 0, 0, 2, 1, 2, 2, 2, 1, 0], [0, 0, 2, 0, 2, 1, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0, 0, 1, 0], [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 0, 2, 0, 1, 0, 0], [0, 0, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 0, 2, 2, 1, 0], [0, 0, 0, 2, 2, 1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
        "opponent": "Go Seigen",
        "opp_color": "b",
        "width": 19,
        "height": 19,
    },
    {
        "state": [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 0, 2, 2, 2, 2, 1, 0, 0], [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 2, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], [0, 1, 2, 0, 2, 0, 2, 0, 0, 1, 0, 2, 0, 0, 2, 2, 1, 0, 0], [0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 1, 0, 0], [0, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 2, 2, 2, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 1, 0, 1, 2, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 1, 2, 1, 2, 2, 0], [0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 1, 0, 1, 2, 0, 1, 2, 0, 0], [0, 0, 2, 0, 0, 0, 0, 2, 2, 1, 0, 0, 1, 0, 1, 0, 2, 0, 0], [0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 1, 2, 0, 0], [0, 0, 2, 0, 0, 0, 2, 0, 0, 1, 2, 0, 1, 0, 1, 2, 1, 0, 0], [0, 2, 1, 2, 0, 1, 1, 2, 0, 0, 2, 0, 0, 0, 2, 2, 0, 1, 0], [0, 1, 1, 1, 0, 1, 2, 2, 0, 0, 0, 0, 0, 1, 0, 2, 2, 1, 0], [0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 0, 0, 2, 0, 0, 2, 0], [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
        "opponent": "Hashimoto Utaro",
        "opp_color": "w",
        "width": 19,
        "height": 19,
    },
    {
        "state": [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0], [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 2, 0, 0, 0, 1, 0, 1, 0, 0, 0, 2, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
        "opponent": "Go Seigen",
        "opp_color": "w",
        "width": 19,
        "height": 19,
    },
]

### API Functions ###
#-------------------#

# Query the API for the ID of a given username
def get_player_id_by_username(username):
    if len(username) > 40:
        return False
    req = http.get(
        url = "https://online-go.com/api/v1/players",
        headers = OGS_HEADERS,
        params = {"username": username},
        ttl_seconds = 3600,
    )
    data = response_json(req)
    results = data.get("results", []) if type(data) == "dict" else []
    if results and type(results[0]) == "dict" and str(results[0].get("id", "")).isdigit():
        player_id = int(results[0]["id"])
        return player_id
    return False

# Get all games for a given player ID
def get_player_games(player_id):
    games_url = "https://online-go.com/api/v1/players/{}/games?ended__isnull=true&ordering=-ended&page_size={}".format(player_id, NUM_OF_GAMES)
    req = http.get(
        url = games_url,
        headers = OGS_HEADERS,
        ttl_seconds = 240,
    )
    data = response_json(req)
    return data.get("results", []) if type(data) == "dict" and type(data.get("results")) == "list" else []

def get_game_state(game_id):
    state_url = "https://online-go.com/termination-api/game/{}/state".format(game_id)
    state_req = http.get(
        url = state_url,
        headers = OGS_HEADERS,
        ttl_seconds = 240,
    )
    board_state = response_json(state_req)
    return board_state.get("board") if type(board_state) == "dict" else None

def get_game_info(game):
    related = game.get("related", {}) if type(game) == "dict" else {}
    detail = related.get("detail", "") if type(related) == "dict" else ""
    if not detail.startswith("/api/v1/games/"):
        return None
    game_url = "https://online-go.com{}".format(detail)
    game_req = http.get(
        url = game_url,
        headers = OGS_HEADERS,
        ttl_seconds = 240,
    )
    return response_json(game_req)

def response_json(response):
    if response.status_code != 200:
        return None
    body = response.body()
    if not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    return response.json()

# Get the details for each of a player's games
def get_games_details(games, player_id):
    games_info = []
    for game in games:
        game_json = get_game_info(game)
        if type(game_json) != "dict" or type(game) != "dict" or not str(game.get("id", "")).isdigit():
            continue
        if not str(game_json.get("width", "")).isdigit() or not str(game_json.get("height", "")).isdigit():
            continue
        game_id = int(game["id"])
        board_state = get_game_state(game_id)
        if type(board_state) != "list":
            continue
        width = int(game_json["width"])
        height = int(game_json["height"])
        if width != height or width not in SIZES or len(board_state) != height:
            continue
        valid_board = True
        for row in board_state:
            if type(row) != "list" or len(row) != width:
                valid_board = False
                break
            for point in row:
                if point not in [0, 1, 2]:
                    valid_board = False
                    break
        if not valid_board:
            continue
        players = game_json.get("players", {})
        black = players.get("black", {}) if type(players) == "dict" else {}
        white = players.get("white", {}) if type(players) == "dict" else {}
        if type(black) != "dict" or type(white) != "dict" or not str(black.get("id", "")).isdigit():
            continue
        if type(black.get("username")) != "string" or type(white.get("username")) != "string":
            continue
        if int(black["id"]) == player_id:
            opponent = white["username"]
            opp_color = "w"
        else:
            opponent = black["username"]
            opp_color = "b"
        games_info.append({
            "opponent": opponent,
            "opp_color": opp_color,
            "state": board_state,
            "width": width,
            "height": height,
        })

    return games_info

### Drawing Functions ###
#-----------------------#

# Using the populated coordinates object, create the graphics for
# the current board state
def draw_game_board(coords, width, height):
    game_board = []
    game_columns = []
    total_width = width + 4
    total_height = height + 4
    board_max_width = width + 3
    board_max_height = height + 3
    for y in range(0, total_height):
        this_row = []
        for x in range(0, total_width):
            if (x == 0 or
                x == board_max_width or
                y == 0 or
                y == board_max_height):
                this_color = "#D19A34"
            elif (x == 1 or
                  x == (board_max_width - 1) or
                  y == 1 or
                  y == (board_max_height - 1)):
                this_color = "#222222"
            else:
                coord_string = "{},{}".format(x - 1, y - 1)
                if coords[coord_string] == "b":
                    this_color = "#000000"
                elif coords[coord_string] == "w":
                    this_color = "#ffffff"
                else:
                    this_color = "#D19A34"
            this_row.append(
                render.Box(
                    width = 1,
                    height = 1,
                    color = this_color,
                ),
            )
        game_columns.append(render.Row(
            children = this_row,
        ))
    game_board = render.Box(
        width = total_width,
        height = total_height,
        child = render.Column(
            children = game_columns,
        ),
    )
    return game_board

# Draw a box with the board, stone color, and opponent name
def draw_game_box(game_board, game_info):
    game_box = []
    game_box.append(
        render.Box(
            width = 4,
            height = 32,
            color = "#000000",
        ),
    )
    game_box.append(game_board)
    opponent = game_info["opponent"]
    if game_info["opp_color"] == "b":
        stone = render.Circle(
            color = "#ffffff",
            diameter = 6,
            child = render.Circle(
                color = "#000000",
                diameter = 4,
            ),
        )
    else:
        stone = render.Circle(
            color = "#ffffff",
            diameter = 6,
        )
    game_box.append(render.Box(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        stone,
                        render.Box(
                            width = 6,
                            height = 6,
                            color = "#000000",
                        ),
                        render.Text(
                            content = "({})".format(game_info["opp_color"]),
                            color = "#ffffff",
                        ),
                    ],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Marquee(
                    child = render.Text(
                        content = "{}".format(opponent),
                        color = "#ffffff",
                    ),
                    width = 30 + 19 - game_info["width"],
                ),
            ],
        ),
        width = 42 + 19 - game_info["width"],
        height = 32,
    ))
    return game_box

# Draw the frames for the final animation
def draw_games_graphics(game_boxes):
    games_graphics = []
    for game_box in game_boxes:
        for _ in range(0, FRAMES):
            games_graphics.append(render.Box(
                child = render.Row(
                    main_align = "start",
                    cross_align = "center",
                    children = game_box,
                    expanded = True,
                ),
                width = 64,
                height = 32,
            ))
    return games_graphics

def draw_game_boxes(games_info):
    game_boxes = []

    # Get the board state for each game and draw the game graphics
    for game_info in games_info:
        # Sort moves in spacially instead of by move number
        coords = init_coords()
        for (y, row) in enumerate(game_info["state"], 1):
            for (x, column) in enumerate(row, 1):
                move_string = "{},{}".format(x, y)
                if column > 0:
                    if column == 1:
                        coords[move_string] = "b"
                    else:
                        coords[move_string] = "w"
        game_board = draw_game_board(coords, game_info["width"], game_info["height"])
        game_box = draw_game_box(game_board, game_info)
        game_boxes.append(game_box)
    return game_boxes

def draw_no_games():
    return render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "No active",
                    color = "#ffffff",
                ),
                render.Text(
                    content = "games found!",
                    color = "#ffffff",
                ),
            ],
            main_align = "center",
            cross_align = "center",
        ),
    )

### Misc Functions ###
#--------------------#

# Initialize a dictionary with all of the board coordinates
def init_coords():
    coords = {}
    for x in range(1, 28):
        for y in range(1, 28):
            coord_string = "{},{}".format(x, y)
            coords[coord_string] = ""
    return coords

### Main Functions ###
#--------------------#

def main(config):
    username = config.str("username", "").strip()

    # If a username has not been set, show a
    # "Username not found" message
    if username == "":
        games_info = FAMOUS_GAMES
    else:
        # Get the player ID and game details from the API
        # If the API didn't return a player ID, show a message
        player_id = get_player_id_by_username(username)

        if player_id == False:
            games_info = []
        else:
            # Get a list of games and game details from the API
            games = get_player_games(player_id)
            games_info = get_games_details(games, player_id)

    # Show a message if there are no active games found
    if len(games_info) == 0:
        no_games_graphics = draw_no_games()
        return render.Root(
            child = no_games_graphics,
        )

    # Create the graphics to be rendered for the final animation
    game_boxes = draw_game_boxes(games_info)
    games_graphics = draw_games_graphics(game_boxes)

    # Render the final animation
    return render.Root(
        child = render.Animation(
            children = games_graphics,
        ),
    )

# Set up options for Username entry
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "OGS Username to use",
                icon = "user",
            ),
        ],
    )
