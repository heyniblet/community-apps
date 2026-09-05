"""
Applet: ESPN FF Standings
Summary: Fantasy Football Standings
Description: Displays the ordered standings with team name and team record.
Author: gmatthews1182
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FANTASY_ENDPOINT = "https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/seasons/{}/segments/0/leagues/{}?view=mTeam&view=mStandings"
DEFAULT_LEAGUE_ID = "1524051886"
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
MAX_TEAMS = 100

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fantasy_league_id",
                name = "ESPN Fantasy league ID",
                desc = "To find your league ID, open the ESPN Fantasy App, navigate to your league, tap on the 'LEAGUE' tab, then tap 'League Info'. You should then see your League ID listed under basic settings.",
                icon = "user",
            ),
            schema.Text(
                id = "year",
                name = "Year of League",
                desc = "The year you want display, usually the current year.",
                icon = "user",
            ),
            schema.Text(
                id = "schema_espn_s2",
                name = "Cookie: espn_s2",
                desc = "[NOT NEEDED FOR PUBLIC LEAGUES; MUST BE FOUND FROM COMPUTER BROWSER] To find your espn_s2 cookie value, log in to https://fantasy.espn.com/football. Once you're at your team's home page, right click anywhere on the page and click 'Inspect'. Once the inspector menu appears, in the top bar of the menu, select 'Application'. In the 'Application' page, on the right bar under 'Cookies', click https://fantasy.espn.com. The espn_s2 value should then displayed in the cookie list. Email your espn_s2 to yourself so you are able to copy it from your mobile device.",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "schema_swid",
                name = "Cookie: swid",
                desc = "[NOT NEEDED FOR PUBLIC LEAGUES; MUST BE FOUND FROM COMPUTER BROWSER] To find your swid cookie value, log in to https://fantasy.espn.com/football. Once you're at your team's home page, right click anywhere on the page and click 'Inspect'. Once the inspector menu appears, in the top bar of the menu, select 'Application'. In the 'Application' page, on the right bar under 'Cookies', click https://fantasy.espn.com. The swid value should then displayed in the cookie list under the 'espnAuth' value. It should be a string of alphanumerics similar to: '{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}'. Email your swid to yourself so you are able to copy it from your mobile device.",
                icon = "user",
                secret = True,
            ),
        ],
    )

def main(config):
    league_id = safe_digits(config.str("fantasy_league_id", DEFAULT_LEAGUE_ID), DEFAULT_LEAGUE_ID, 20)
    current_year = str(time.now().year)
    year = safe_year(config.get("year", current_year), current_year)
    espn_s2 = safe_cookie(config.str("schema_espn_s2", ""))
    swid = safe_cookie(config.str("schema_swid", ""))
    headers = {}
    if espn_s2 and swid:
        headers["Cookie"] = "espn_s2={}; SWID={}".format(espn_s2, swid)

    response = http.get(url = FANTASY_ENDPOINT.format(year, league_id), headers = headers)
    body = response.body()
    payload = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    list_of_teams = normalized_teams(payload)
    if not list_of_teams:
        return error_root("League unavailable")

    render_category = []
    teams_per_view = 3  # Number of teams to display at once

    # Create a fixed title with a softer color scheme
    title = render.Box(
        width = 64,
        height = 7,
        color = "#2E3B4E",  # Darker blue-gray for background
        child = render.Box(
            width = 64,
            height = 7,
            color = "#4B6F93",  # Lighter blue-gray for inner box
            child = render.Padding(
                pad = 2,  # Padding to create space for the inner box
                child = render.Box(
                    width = 60,
                    height = 7,
                    color = "#2E3B4E",  # Matching background color for consistency
                    child = render.Text(content = "ESPN Fantasy", color = "#F0E68C"),  # Softer yellow for title text
                ),
            ),
        ),
    )

    # Group teams into sets of three
    for i in range(0, len(list_of_teams), teams_per_view):
        team_group = list_of_teams[i:i + teams_per_view]
        team_rows = []

        for team in team_group:
            team_rows.append(
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#000000",  # Black background for team boxes
                    child = render.Row(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                width = 45,
                                height = 7,
                                child = render.Text(content = team["team_name"], color = "#F0E68C"),  # Softer yellow for team name
                                align = "start",
                                delay = 6000,
                            ),
                            render.Box(
                                width = 16,
                                height = 6,
                                child = render.Text(content = team["team_record"], color = "#FFFFFF"),  # White text for team record
                            ),
                        ],
                    ),
                ),
            )

        # Create a column for the group of teams
        render_category.append(
            render.Column(
                children = team_rows,
                expanded = True,
                main_align = "start",
                cross_align = "start",
            ),
        )

    # Return the rendered animation with the title at the top
    return render.Root(
        delay = 4000,
        show_full_animation = True,
        child = render.Column(
            children = [
                title,
                render.Animation(children = render_category),
            ],
        ),
    )

def normalized_teams(payload):
    teams = payload.get("teams") if type(payload) == "dict" else None
    if type(teams) != "list":
        return []
    team_values = []
    for team in teams[:MAX_TEAMS]:
        if type(team) != "dict":
            continue
        overall = team.get("record", {}).get("overall") if type(team.get("record")) == "dict" else None
        rank = team.get("playoffSeed")
        if type(overall) != "dict" or type(rank) not in ["int", "float"]:
            continue
        wins = overall.get("wins")
        losses = overall.get("losses")
        if type(wins) not in ["int", "float"] or type(losses) not in ["int", "float"]:
            continue
        team_values.append({
            "team_name": str(team.get("name") or "Team")[:80],
            "team_rank": max(0, min(1000, int(rank))),
            "team_record": "{}-{}".format(max(0, min(1000, int(wins))), max(0, min(1000, int(losses)))),
        })
    return sorted(team_values, key = lambda team: (team["team_rank"]))

def safe_digits(value, fallback, max_length):
    value = str(value or "").strip()
    return value if value and len(value) <= max_length and value.isdigit() else fallback

def safe_year(value, fallback):
    value = safe_digits(value, fallback, 4)
    year = int(value)
    return value if year >= 2000 and year <= 2100 else fallback

def safe_cookie(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 4096 and "\r" not in value and "\n" not in value and ";" not in value else ""

def error_root(message):
    return render.Root(child = render.Box(render.WrappedText(message, font = "tom-thumb")))
