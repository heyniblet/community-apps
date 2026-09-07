"""
Applet: IFPARank
Author: cubsaaron
Summary: Display IFPA Ranking
Description: Display an International Flipper Pinball Association (IFPA) World Ranking.
"""

load("http.star", "http")
load("images/pin_icon.png", PIN_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PIN_ICON = PIN_ICON_ASSET.readall()

def main(config):
    api_key = config.str("ifpa_api_key")
    player_id = config.str("playerId", "1")
    if not api_key:
        return render.Root(
            child = render.Text("No IFPA API Key provided.", font = "5x8"),
        )
    if not player_id or len(player_id) > 12 or any([c not in "0123456789" for c in player_id.elems()]):
        return render.Root(child = render.Text("Invalid player ID", font = "5x8"))

    res = http.get(
        "https://api.ifpapinball.com/v1/player/" + player_id,
        params = {"api_key": api_key},
    )
    if res.status_code != 200:
        return render.Root(child = render.Text("IFPA unavailable", font = "5x8"))
    data = res.json()
    player = data.get("player", {})
    stats = data.get("player_stats", {})
    if not player.get("initials") or stats.get("current_wppr_rank") == None:
        return render.Root(child = render.Text("No ranking found", font = "5x8"))
    ifpa_initial = player["initials"]
    ifpa_rank = stats["current_wppr_rank"]

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = PIN_ICON),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Text("IFPA", color = "#fc6203", font = "tb-8"),
                            render.Text("#%s" % ifpa_rank, color = "#fc6203", font = "6x13"),
                            render.Text(ifpa_initial, color = "#fc6203", font = "tb-8"),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "playerId",
                name = "Player ID",
                desc = "IFPA Player ID",
                icon = "user",
                default = "1",
            ),
            schema.Text(
                id = "ifpa_api_key",
                name = "IFPA API Key",
                desc = "An IFPA API key to access the IFPA API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
