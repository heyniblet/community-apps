"""Displays a player's current Slippi ranked profile statistics."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://internal.slippi.gg/graphql"
DEFAULT_CODE = "TRB#328"
QUERY = "query UserProfilePageQuery($cc: String) { getUser(connectCode: $cc) { displayName rankedNetplayProfile { wins losses characters { character gameCount } } } }"

def main(config):
    code = config.str("code", DEFAULT_CODE).upper().replace("-", "#")
    response = http.post(
        API_URL,
        body = json.encode({"operationName": "UserProfilePageQuery", "variables": {"cc": code}, "query": QUERY}),
        headers = {"Accept": "application/json", "Content-Type": "application/json", "User-Agent": "tronbyt-slippi-stats/1.0"},
        ttl_seconds = 3600,
    )
    if response.status_code != 200:
        fail("Slippi request failed: %d", response.status_code)

    user = response.json()["data"]["getUser"]
    if not user or not user["rankedNetplayProfile"]:
        fail("No ranked Slippi profile found for %s", code)

    profile = user["rankedNetplayProfile"]
    wins = profile["wins"]
    losses = profile["losses"]
    total = wins + losses
    win_rate = int(100 * wins / total) if total else 0
    main_character = "UNRANKED"
    main_games = -1
    for character in profile["characters"]:
        if character["gameCount"] > main_games:
            main_character = character["character"].replace("_", " ")
            main_games = character["gameCount"]

    return render.Root(child = render.Column(children = [
        render.Marquee(width = 64, child = render.Text(user["displayName"], color = "#7cc7ff", font = "tb-8")),
        render.Text("%d games  %d%% WR" % (total, win_rate), font = "tb-8"),
        render.Marquee(width = 64, child = render.Text(main_character, color = "#ddd", font = "tom-thumb")),
    ]))

def get_schema():
    return schema.Schema(version = "1", fields = [schema.Text(
        id = "code",
        name = "Slippi Code",
        desc = "For example: TRB#328",
        icon = "user",
        default = DEFAULT_CODE,
    )])
