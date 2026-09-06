"""
Applet: ESPN Fantasy FB
Summary: Fantasy FB matchup scores
Description: Connects to your ESPN fantasy football league and randomly displays the scoreboard for a given matchup.
Author: jack_markle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FANTASY_BASE_ENDPOINT = "https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/seasons/{}/segments/0/leagues/{}"
DEFAULT_LEAGUE_ID = "59435668"
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
MAX_TEAMS = 100
MAX_MATCHUPS = 50

def main(config):
    league_id = safe_digits(config.str("fantasy_league_id", DEFAULT_LEAGUE_ID), DEFAULT_LEAGUE_ID, 20)
    current_year = str(time.now().year)
    year = safe_year(config.get("year", current_year), current_year)
    espn_s2 = safe_cookie(config.str("schema_espn_s2", ""))
    swid = safe_cookie(config.str("schema_swid", ""))
    headers = {}
    if espn_s2 and swid:
        headers["Cookie"] = "espn_s2={}; SWID={}".format(espn_s2, swid)

    endpoint = FANTASY_BASE_ENDPOINT.format(year, league_id)
    league = fetch_json(endpoint + "?view=mTeam&view=mSettings&view=mStandings", headers)
    status = league.get("status") if type(league) == "dict" else None
    if type(status) != "dict":
        return error_root("League unavailable")
    scoring_period = league.get("scoringPeriodId")
    final_period = status.get("finalScoringPeriod")
    if type(scoring_period) not in ["int", "float"] or type(final_period) not in ["int", "float"]:
        return error_root("Season unavailable")
    scoring_period = max(1, min(int(scoring_period), int(final_period)))
    matchup_period = status.get("currentMatchupPeriod")
    matchup_period = max(1, min(100, int(matchup_period))) if type(matchup_period) in ["int", "float"] else scoring_period

    score_headers = dict(headers)
    score_headers["x-fantasy-filter"] = json.encode({"schedule": {"filterMatchupPeriodIds": {"value": [matchup_period]}}})
    scores = fetch_json(endpoint + "?view=mMatchupScore&view=mScoreboard&scoringPeriodId={}".format(scoring_period), score_headers)
    matchups = normalized_matchups(scores)
    if not matchups:
        return error_root("No matchups found")
    matchup = matchups[random.number(0, len(matchups) - 1)]

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                team_column(matchup["home_team"], "#163f75"),
                render.Box(width = 2, height = 32, color = "#fff"),
                team_column(matchup["away_team"], "#7a241f"),
            ],
        ),
    )

def fetch_json(url, headers):
    response = http.get(url = url, headers = headers)
    body = response.body()
    return json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None

def normalized_matchups(payload):
    if type(payload) != "dict":
        return []
    teams = payload.get("teams")
    schedule = payload.get("schedule")
    if type(teams) != "list" or type(schedule) != "list":
        return []
    teams_by_id = {}
    for team in teams[:MAX_TEAMS]:
        team_id = team.get("id") if type(team) == "dict" else None
        if type(team_id) in ["int", "float", "string"]:
            teams_by_id[str(team_id)] = team

    matchups = []
    for matchup in schedule[:MAX_MATCHUPS]:
        if type(matchup) != "dict" or type(matchup.get("home")) != "dict" or type(matchup.get("away")) != "dict":
            continue
        home = normalized_team(matchup["home"], teams_by_id)
        away = normalized_team(matchup["away"], teams_by_id)
        if home and away:
            matchups.append({"home_team": home, "away_team": away})
    return matchups

def normalized_team(side, teams_by_id):
    team = teams_by_id.get(str(side.get("teamId")))
    if type(team) != "dict":
        return None
    name = str(team.get("name") or "Team")[:80]
    abbreviation = str(team.get("abbrev") or name[:3]).upper()[:4]
    score = side.get("totalPointsLive")
    if type(score) not in ["int", "float"]:
        score = side.get("totalPoints")
    score = max(0, min(9999, score)) if type(score) in ["int", "float"] else 0
    return {"team_name": name, "abbreviation": abbreviation, "team_score": score}

def team_column(team, color):
    return render.Box(
        width = 30,
        height = 32,
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Box(
                    width = 30,
                    height = 8,
                    child = render.Marquee(width = 30, height = 8, child = render.Text(team["team_name"])),
                ),
                render.Box(
                    width = 30,
                    height = 16,
                    color = color,
                    child = render.Text(team["abbreviation"], font = "tb-8"),
                ),
                render.Box(
                    width = 30,
                    height = 8,
                    child = render.Text(content = score_text(team["team_score"]), font = "tb-8", height = 8),
                ),
            ],
        ),
    )

def score_text(score):
    rounded = int(score * 10 + 0.5) / 10.0
    return str(int(rounded)) if rounded == int(rounded) else str(rounded)

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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fantasy_league_id",
                name = "ESPN Fantasy league ID",
                desc = "Find the league ID under League Info in the ESPN Fantasy app.",
                icon = "user",
            ),
            schema.Text(
                id = "year",
                name = "Year of League",
                desc = "Season year; defaults to the current year.",
                icon = "calendar",
            ),
            schema.Text(
                id = "schema_espn_s2",
                name = "Cookie: espn_s2",
                desc = "Optional for public leagues. Private leagues require your ESPN espn_s2 web-session cookie.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "schema_swid",
                name = "Cookie: swid",
                desc = "Optional for public leagues. Private leagues require your ESPN SWID web-session cookie.",
                icon = "key",
                secret = True,
            ),
        ],
    )
