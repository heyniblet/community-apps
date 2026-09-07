load("encoding/json.star", "json")
load("http.star", "http")

MAX_RESPONSE_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 1024 * 1024
MAX_TEXT_LENGTH = 160

def fetch_icon(url):
    if url == None:
        return None
    res = http.get(url, ttl_seconds = 86400)
    if res.status_code != 200:
        return None
    body = res.body()
    return body if len(body) <= MAX_IMAGE_BYTES else None

def fetch_server_data(server_id, api_token):
    url = "https://api.battlemetrics.com/servers/" + server_id
    res = http.get(url, headers = {"Authorization": "Bearer " + api_token})
    if res.status_code != 200:
        return None

    raw = res.body()
    if len(raw) > MAX_RESPONSE_BYTES:
        return None
    body = json.decode(raw)
    data = body.get("data") if type(body) == "dict" else None
    attrs = data.get("attributes") if type(data) == "dict" else None
    relationships = data.get("relationships") if type(data) == "dict" else None
    game = relationships.get("game") if type(relationships) == "dict" else None
    game_data = game.get("data") if type(game) == "dict" else None
    game_id = game_data.get("id") if type(game_data) == "dict" else None
    if type(attrs) != "dict" or type(game_id) != "string":
        return None
    name = attrs.get("name")
    players = attrs.get("players")
    max_players = attrs.get("maxPlayers")
    status = attrs.get("status")
    if type(name) != "string" or type(players) not in ["int", "float"] or type(max_players) not in ["int", "float"] or type(status) != "string":
        return None

    result = {
        "name": name[:MAX_TEXT_LENGTH],
        "players": max(0, int(players)),
        "max_players": max(0, int(max_players)),
        "status": status[:32],
        "game_id": game_id[:40],
        "details": attrs.get("details") if type(attrs.get("details")) == "dict" else {},
    }

    return result
