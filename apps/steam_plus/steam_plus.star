"""
Applet: Steam Plus
Summary: Steam profile status viewer
Description: Shows Steam user avatar, name, status, and currently playing.
Author: Mike Toscano
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATUS = ["Offline", "Online", "Busy", "Away"]
STATUS_COLOR = ["#59707B", "#0a0", "#F67407", "#FFD100"]

def main(config):
    api_key = config.str("api_key") or ""
    steam_id = config.str("id", "") or "76561197998958802"
    if not api_key or len(steam_id) != 17 or not steam_id.isdigit():
        return render.Root(child = render.WrappedText("Configure a Steam ID and API key", width = 64, align = "center"))

    resp = http.get("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/", params = {
        "key": api_key,
        "steamids": steam_id,
    })

    players = []
    if resp.status_code == 200:
        data = resp.json()
        response = data.get("response") if type(data) == "dict" else None
        candidate = response.get("players") if type(response) == "dict" else None
        players = candidate[:1] if type(candidate) == "list" else []

    username = "Cannot find the specified user"
    avatar = None
    currently_playing_logo = None
    currently_playing = ""
    status = ""
    persona_state = 0

    user = {}
    if len(players) > 0 and type(players[0]) == "dict":
        user = players[0]

        username = str(user.get("personaname") or username)[:80]

        currently_playing = str(user.get("gameextrainfo") or config.str("offlineStatus", "Just Chilling") or "Just Chilling")[:120]
        avatar = get_image(user.get("avatarfull"), ["https://avatars.steamstatic.com/", "https://avatars.akamai.steamstatic.com/"])
        persona_state = user.get("personastate", 0)
        persona_state = int(persona_state) if type(persona_state) in ["int", "float"] and persona_state >= 0 and persona_state < len(STATUS) else 0
        status = STATUS[persona_state]
        currently_playing_game_id = str(user.get("gameid") or "")
        user_games = []

        if currently_playing_game_id.isdigit():
            user_games_resp = http.get("https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/", params = {
                "format": "json",
                "include_appinfo": "true",
                "key": api_key,
                "steamid": steam_id,
            })

            if user_games_resp.status_code == 200:
                data = user_games_resp.json()
                response = data.get("response") if type(data) == "dict" else None
                candidate = response.get("games") if type(response) == "dict" else None
                user_games = candidate[:1000] if type(candidate) == "list" else []

        for game in user_games:
            if type(game) != "dict":
                continue
            icon_hash = str(game.get("img_icon_url") or "")
            if str(game.get("appid")) == currently_playing_game_id and len(icon_hash) <= 64 and icon_hash.isalnum():
                currently_playing_logo = get_image("https://media.steampowered.com/steamcommunity/public/images/apps/" + currently_playing_game_id + "/" + icon_hash + ".jpg", ["https://media.steampowered.com/"])
                break

    return render.Root(
        delay = 90,
        child = render.Box(
            height = 32,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = player_icon_row(config.bool("playerIconRight", False), avatar, username, status, persona_state),
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "end",  # Controls vertical alignment
                        children = game_icon_row(config.bool("gameIconRight", False), currently_playing_logo, currently_playing),
                    ),
                ],
            ),
        ),
    )

def game_icon_row(image_right, currently_playing_logo, currently_playing):
    iconView = render.Image(src = currently_playing_logo, width = 16, height = 15) if currently_playing_logo else render.Box(width = 16, height = 15, color = "#1b2838")

    views = [
        # render.Text(content=currently_playing, font="tb-8", height=16, offset=4),
        render.Marquee(
            width = 48,
            child = render.Text(content = " " + currently_playing, font = "tb-8", height = 16, offset = 4),
            offset_start = 0,
            offset_end = 0,
            align = "end" if image_right else "start",
        ),
    ]

    if image_right:
        views.append(iconView)
    else:
        views.insert(0, iconView)

    return views

def player_icon_row(image_right, avatar, username, status, persona_state):
    iconView = render.Image(src = avatar, width = 16, height = 16) if avatar else render.Box(width = 16, height = 16, color = "#1b2838")

    views = [
        render.Column(
            children = [
                render.Marquee(
                    width = 48,
                    height = 8,
                    child = render.Text(content = username, font = "tb-8"),
                    offset_start = 0,
                    offset_end = 0,
                    align = "end" if image_right else "start",
                ),
                render.Marquee(
                    child = render.Text(content = status, font = "tb-8", color = STATUS_COLOR[persona_state]),
                    offset_start = 0,
                    offset_end = 0,
                    width = 48,
                    height = 8,
                    align = "end" if image_right else "start",
                ),
            ],
        ),
    ]

    if image_right:
        views.append(iconView)
    else:
        views.insert(0, iconView)

    return views

def get_image(url, allowed_prefixes):
    if type(url) != "string" or not any([url.startswith(prefix) for prefix in allowed_prefixes]):
        return None
    response = http.get(url, ttl_seconds = 600)
    return response.body() if response.status_code == 200 else None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "id",
                name = "Steam ID",
                desc = "17 digit Steam ID",
                icon = "user",
                default = "76561197998958802",  # Mike's account ID
            ),
            schema.Text(
                id = "api_key",
                name = "Steam API Key",
                desc = "https://steamcommunity.com/dev/apikey",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "offlineStatus",
                name = "Offline Status",
                desc = "Message displayed when you are offline",
                icon = "comment",
                default = "Gaming IRL",
            ),
            schema.Toggle(
                id = "playerIconRight",
                name = "Player icon right",
                desc = "Show the player icon on the right side",
                icon = "rightToBracket",
            ),
            schema.Toggle(
                id = "gameIconRight",
                name = "Game icon right",
                desc = "Show the game icon on the right side",
                icon = "rightToBracket",
            ),
        ],
    )
