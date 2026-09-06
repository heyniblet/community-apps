"""
Applet: Roblox
Summary: Online friends & games
Description: Real time views of your Roblox experiences.
Author: Chad Milburn / CODESTRONG
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/roblox_dark_logo.png", ROBLOX_DARK_LOGO_ASSET = "file")
load("images/roblox_light_logo.png", ROBLOX_LIGHT_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ROBLOX_DARK_LOGO = ROBLOX_DARK_LOGO_ASSET.readall()
ROBLOX_LIGHT_LOGO = ROBLOX_LIGHT_LOGO_ASSET.readall()

### CONSTANTS
TTL_SECONDS = 240
TRIO_CIRCLES_TOP_OFFSET = 12
MAX_JSON_BYTES = 256 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024
IMAGE_PREFIX = "https://tr.rbxcdn.com/"

### DEFAULTS
DEFAULT_DARK_MODE = True
DEFAULT_ACCENT_COLOR = "#f77a24"

### VIEW MODES
VIEW_FRIENDS = "view_friends"
VIEW_FAVORITE_GAMES = "view_favorite_games"

def request_json(url, json_body = None, max_bytes = MAX_JSON_BYTES):
    response = http.get(url, ttl_seconds = TTL_SECONDS) if json_body == None else http.post(url, json_body = json_body, ttl_seconds = TTL_SECONDS)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > max_bytes:
        return None
    return json.decode(body, None)

def load_image(url):
    if type(url) != "string" or not url.startswith(IMAGE_PREFIX):
        return ""
    response = http.get(url, ttl_seconds = 86400)
    body = response.body()
    return body if response.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else ""

def thumbnail_urls(kind, ids):
    if len(ids) == 0:
        return {}
    if kind == "users":
        url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=60x60&format=Png&isCircular=true" % ",".join([str(id) for id in ids])
    else:
        url = "https://thumbnails.roblox.com/v1/games/icons?universeIds=%s&size=50x50&format=Png&isCircular=false" % ",".join([str(id) for id in ids])
    data = request_json(url, max_bytes = 64 * 1024)
    rows = data.get("data", []) if type(data) == "dict" else []
    return {
        str(row.get("targetId")): row.get("imageUrl")
        for row in rows[:len(ids)]
        if type(row) == "dict" and row.get("targetId") != None and type(row.get("imageUrl")) == "string" and row.get("imageUrl").startswith(IMAGE_PREFIX)
    }

def presence_by_user(ids):
    data = request_json("https://presence.roblox.com/v1/presence/users", json_body = {"userIds": ids}, max_bytes = 128 * 1024)
    rows = data.get("userPresences", []) if type(data) == "dict" else []
    return {
        str(row.get("userId")): row.get("userPresenceType", 0) != 0
        for row in rows[:len(ids)]
        if type(row) == "dict" and row.get("userId") != None
    }

def main(config):
    ### SET VIEW MODE FROM APP CONFIG SETTINGS
    view_mode = config.str("view_mode", VIEW_FRIENDS)
    if view_mode not in [VIEW_FRIENDS, VIEW_FAVORITE_GAMES]:
        view_mode = VIEW_FRIENDS

    ### SET ACCENT COLOR FROM APP CONFIG SETTINGS
    accent_color = config.str("accent_color", DEFAULT_ACCENT_COLOR)
    if accent_color not in ["#fff", "#f72525", "#f77a24", "#f7cd25", "#25f739", "#1a57f0", "#8329e9", "#fe2fe8", "#444", "#000"]:
        accent_color = DEFAULT_ACCENT_COLOR

    ### SET IS DARK MODE FROM APP CONFIG SETTINGS
    dark_mode = config.bool("dark_mode", DEFAULT_DARK_MODE)

    ### SET USERNAME
    username = config.str("username", "").strip()

    renderGame = []
    renderFriend = []

    ### GET USER ID
    lookup = request_json(
        "https://users.roblox.com/v1/usernames/users",
        json_body = {"usernames": [username], "excludeBannedUsers": True},
        max_bytes = 64 * 1024,
    ) if 3 <= len(username) and len(username) <= 20 and username.replace("_", "").isalnum() else None
    users = lookup.get("data", []) if type(lookup) == "dict" else []
    userRobloxId = str(users[0].get("id")) if len(users) > 0 and type(users[0]) == "dict" and users[0].get("id") != None else ""

    ### RETURN AND SHOW 'USER NOT FOUND' SCREEN IF FAILS TO GET USER ID
    if userRobloxId == None or userRobloxId == "":
        return render.Root(
            child = render.Stack(
                children = [
                    render.Padding(
                        pad = (2, 2, 0, 0),
                        child = render.Row(
                            children = [
                                render.Stack(
                                    children = [
                                        render.Circle(
                                            color = "#888",
                                            diameter = 21,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (19, 19, 0, 0),
                        child = render.Circle(
                            color = "#333",
                            diameter = 4,
                        ),
                    ),
                    render.Padding(
                        pad = (9, 25, 0, 0),
                        child = render.Marquee(
                            width = 64,
                            child = render.Text(content = "Set a Roblox username" if username == "" else "User not found", font = "tom-thumb"),
                        ),
                    ),
                    render.Padding(
                        pad = (1, 24, 0, 0),
                        child = render.Image(src = ROBLOX_DARK_LOGO, width = 7, height = 7),
                    ),
                ],
            ),
        )

    ### GET USER AVATAR
    profilePhotoImg = load_image(thumbnail_urls("users", [userRobloxId]).get(userRobloxId, ""))
    isOnline = presence_by_user([int(userRobloxId)]).get(userRobloxId, False)

    ### FRIEND MODE
    if view_mode == VIEW_FRIENDS:
        ### GET USER FRIENDS
        friends_data = request_json("https://friends.roblox.com/v1/users/%s/friends" % userRobloxId)
        userFriends = friends_data.get("data", [])[:50] if type(friends_data) == "dict" and type(friends_data.get("data")) == "list" else []
        friend_ids = [friend.get("id") for friend in userFriends if type(friend) == "dict" and friend.get("id") != None]
        online = presence_by_user([int(userRobloxId)] + friend_ids)
        isOnline = online.get(userRobloxId, isOnline)

        ### POPULATE FRIENDS LIST
        friendsList = []
        for friend in userFriends:
            if type(friend) == "dict" and friend.get("id") != None:
                friend_id = str(friend["id"])
                friendsList.append({"id": friend_id, "isOnline": online.get(friend_id, False)})

        ### SORT BY ONLINE STATUS
        friendsList = sorted(friendsList, key = lambda f: f["isOnline"], reverse = True)
        friend_avatars = thumbnail_urls("users", [friend["id"] for friend in friendsList[:3]])

        ### BUILD FRIEND RENDER LIST
        renderFriend = []
        for friend in range(3):
            friendAvatar = load_image(friend_avatars.get(friendsList[friend]["id"], "")) if friend < len(friendsList) else ""

            renderFriend.append(
                render.Padding(
                    pad = (25 + (13 * friend), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#333" if dark_mode == True else "#222",
                                        diameter = 11,
                                    ),
                                    render.Image(src = friendAvatar, width = 11, height = 11) if friendAvatar != "" else render.Text(content = ""),
                                    render.Padding(
                                        pad = (10, 10, 0, 0),
                                        child = render.Circle(
                                            color = "#0f0" if friend < len(friendsList) and friendsList[friend]["isOnline"] else "#888",
                                            diameter = 1,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )

        ### FAVORITE GAME MODE
    else:
        ### GET USER FAVORITE GAMES
        games_data = request_json("https://games.roblox.com/v2/users/%s/favorite/games?accessFilter=Public&sortOrder=Desc&limit=10" % userRobloxId)
        userFavoriteGames = games_data.get("data", [])[:3] if type(games_data) == "dict" and type(games_data.get("data")) == "list" else []

        ### POPULATE FAVORITE GAMES RENDER LIST
        favoriteGamesList = []
        for game in userFavoriteGames:
            if type(game) == "dict" and game.get("id") != None:
                favoriteGamesList.append(str(game["id"]))
        game_avatars = thumbnail_urls("games", favoriteGamesList)

        ### BUILD POPULATE FAVORITE GAMES
        renderGame = []
        for game in range(3):
            gameAvatar = load_image(game_avatars.get(favoriteGamesList[game], "")) if game < len(favoriteGamesList) else ""

            renderGame.append(
                render.Padding(
                    pad = (25 + (13 * game), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(
                                        color = "#333",
                                        width = 11,
                                        height = 11,
                                    ),
                                    render.Image(src = gameAvatar, width = 11, height = 11) if gameAvatar != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
            )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    color = "#000" if dark_mode == True else "#fff",
                    width = 64,
                    height = 32,
                ),
                render.Padding(
                    pad = (2, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#fff" if dark_mode == True else "#222",
                                        diameter = 21,
                                    ),
                                    render.Image(src = profilePhotoImg, width = 21, height = 21) if profilePhotoImg != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (19, 19, 0, 0),
                    child = PULSATING_ONLINE_DOT if isOnline else render.Circle(diameter = 4, color = "#888"),
                ),
                render.Padding(
                    pad = (30, 4, 0, 0),
                    child = render.Text(content = "friends", font = "CG-pixel-3x5-mono", color = accent_color),
                ) if view_mode == VIEW_FRIENDS else render.Padding(
                    pad = (26, 4, 0, 0),
                    child = render.Text(content = "favorites", font = "CG-pixel-3x5-mono", color = accent_color),
                ),
                render.Padding(
                    pad = (10, 26, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(content = "%s" % username, color = "#c7d0d8" if dark_mode == True else "#333", font = "CG-pixel-4x5-mono"),
                    ),
                ),
                render.Padding(
                    pad = (1, 24, 0, 0),
                    child = render.Image(src = ROBLOX_DARK_LOGO if dark_mode == True else ROBLOX_LIGHT_LOGO, width = 7, height = 7),
                ),
                renderFriend[0] if view_mode == VIEW_FRIENDS else renderGame[0],
                renderFriend[1] if view_mode == VIEW_FRIENDS else renderGame[1],
                renderFriend[2] if view_mode == VIEW_FRIENDS else renderGame[2],
            ],
        ),
    )

def get_schema():
    view_mode_options = [
        schema.Option(
            display = "Online Friends",
            value = VIEW_FRIENDS,
        ),
        schema.Option(
            display = "Favorite Games",
            value = VIEW_FAVORITE_GAMES,
        ),
    ]

    accent_color_options = [
        schema.Option(
            display = "White",
            value = "#fff",
        ),
        schema.Option(
            display = "Red",
            value = "#f72525",
        ),
        schema.Option(
            display = "Orange",
            value = "#f77a24",
        ),
        schema.Option(
            display = "Yellow",
            value = "#f7cd25",
        ),
        schema.Option(
            display = "Green",
            value = "#25f739",
        ),
        schema.Option(
            display = "Blue",
            value = "#1a57f0",
        ),
        schema.Option(
            display = "Purple",
            value = "#8329e9",
        ),
        schema.Option(
            display = "Pink",
            value = "#fe2fe8",
        ),
        schema.Option(
            display = "Gray",
            value = "#444",
        ),
        schema.Option(
            display = "Clear",
            value = "#000",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Roblox username",
                desc = "Enter a Roblox username",
                icon = "userAstronaut",
                default = "",
            ),
            schema.Dropdown(
                id = "view_mode",
                name = "View mode",
                desc = "Display your friends or games",
                icon = "cubes",
                default = view_mode_options[0].value,
                options = view_mode_options,
            ),
            schema.Dropdown(
                id = "accent_color",
                name = "Accent color",
                desc = "Choose an accent color",
                icon = "palette",
                default = accent_color_options[0].value,
                options = accent_color_options,
            ),
            schema.Toggle(
                id = "dark_mode",
                name = "Dark mode",
                desc = "Toggle between light and dark modes",
                icon = "moon",
                default = True,
            ),
        ],
    )

PULSATING_ONLINE_DOT = render.Animation(
    children = [
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
    ],
)
