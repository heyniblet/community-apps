"""Displays a player's current Slippi ranked profile statistics."""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://internal.slippi.gg/graphql"
DEFAULT_CODE = "TRB#328"
QUERY = "query UserProfilePageQuery($cc: String) { getUser(connectCode: $cc) { displayName rankedNetplayProfile { wins losses characters { character gameCount } } } }"
MAX_RESPONSE_BYTES = 256 * 1024

def main(config):
    code = config.str("code", DEFAULT_CODE).upper().replace("-", "#")
    if not re.match(r"^[A-Z0-9]{1,10}#[0-9]{1,6}$", code):
        return error_frame("Invalid Slippi code")
    response = http.post(
        API_URL,
        body = json.encode({"operationName": "UserProfilePageQuery", "variables": {"cc": code}, "query": QUERY}),
        headers = {"Accept": "application/json", "Content-Type": "application/json", "User-Agent": "tronbyt-slippi-stats/1.0"},
    )
    body = response.body()
    payload = json.decode(body, {}) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else {}
    data = payload.get("data", {}) if type(payload) == "dict" else {}
    user = data.get("getUser", {}) if type(data) == "dict" else {}
    profile = user.get("rankedNetplayProfile", {}) if type(user) == "dict" else {}
    if type(profile) != "dict":
        return error_frame("Profile unavailable")

    wins = profile.get("wins")
    losses = profile.get("losses")
    display_name = user.get("displayName")
    if type(wins) != "int" or wins < 0 or type(losses) != "int" or losses < 0 or type(display_name) != "string":
        return error_frame("Profile unavailable")
    total = wins + losses
    win_rate = int(100 * wins / total) if total else 0
    main_character = "UNRANKED"
    main_games = -1
    characters = profile.get("characters", [])
    if type(characters) == "list":
        for character in characters[:100]:
            if type(character) == "dict" and type(character.get("gameCount")) == "int" and type(character.get("character")) == "string" and character["gameCount"] > main_games:
                main_character = character["character"][:40].replace("_", " ")
                main_games = character["gameCount"]

    return render.Root(child = render.Column(children = [
        render.Marquee(width = 64, child = render.Text(display_name[:80], color = "#7cc7ff", font = "tb-8")),
        render.Text("%d games  %d%% WR" % (total, win_rate), font = "tb-8"),
        render.Marquee(width = 64, child = render.Text(main_character, color = "#ddd", font = "tom-thumb")),
    ]))

def error_frame(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, color = "#f00"))

def get_schema():
    return schema.Schema(version = "1", fields = [schema.Text(
        id = "code",
        name = "Slippi Code",
        desc = "For example: TRB#328",
        icon = "user",
        default = DEFAULT_CODE,
    )])
