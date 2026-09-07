"""
Applet: Purdue Basketball
Summary: Shows basketball record
Description: Shows Purdues bball record.
Author: Griffinov22
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/purdue_logo.png", PURDUE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PURDUE_LOGO = PURDUE_LOGO_ASSET.readall()
MAX_RESPONSE_BYTES = 2 * 1024 * 1024

def main(config):
    now = time.now()
    year = now.year + 1 if now.month >= 7 else now.year
    api_key = config.str("api_key", "")

    cbb_stat_endpoint = "https://api.sportsdata.io/v3/cbb/scores/json/TeamSeasonStats/" + str(year)

    if (api_key == ""):
        return message("API key needed")

    purdue_stat = get_purdue_stat(cbb_stat_endpoint, api_key)
    if purdue_stat == None:
        return message("Stats unavailable")
    wins = purdue_stat["wins"]
    losses = purdue_stat["losses"]
    # child = render.Text("{}-{}".format(wins,losses))

    return render.Root(
        child = render.Box(
            # width=48,
            padding = 5,
            child = render.Column(
                children = [render.Row(
                    children = [
                        render.Image(src = PURDUE_LOGO, width = 24),
                        render.Text("{}-{}".format(wins, losses)),
                    ],
                    main_align = "space_between",
                    cross_align = "center",
                    expanded = True,
                )],
                cross_align = "center",
            ),
        ),
    )

def get_purdue_stat(endpoint, api_key):
    data = http.get(endpoint, headers = {"Ocp-Apim-Subscription-Key": api_key})
    body = data.body()
    res = json.decode(body, None) if data.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(res) != "list":
        return None
    for obj in res:
        if type(obj) != "dict" or obj.get("Team") != "PUR":
            continue
        wins = obj.get("Wins")
        losses = obj.get("Losses")
        if type(wins) in ["int", "float"] and type(losses) in ["int", "float"]:
            return {"wins": int(wins), "losses": int(losses)}
    return None

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, align = "center")))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "api key",
                desc = "SportsDataIO College Basketball API key",
                icon = "key",
                secret = True,
            ),
        ],
    )
