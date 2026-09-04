"""
Applet: YahooFantasyMLB
Summary: Fantasy Standings & Scores
Description: Display standings or scores for a Yahoo Fantasy Baseball league (MLB).
Author: jweier extended from LunchBox8484
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

YAHOO_OAUTH_TOKEN_URL = "https://api.login.yahoo.com/oauth2/get_token"
YAHOO_REDIRECT_URI = "oob"
GAME_KEY = "mlb"

def main(config):
    render_category = []
    league_name = ""
    client_id = config.get("yahoo_client_id")
    client_secret = config.get("yahoo_client_secret")
    refresh_token = config.get("yahoo_refresh_token")
    league_number = config.get("league_number", "")
    rotation_speed = config.get("rotation_speed", "5")
    teams_per_view = int(config.get("teams_per_view", "3"))
    heading_font_color = config.get("heading_font_color", "#FFA500")
    color_scheme = config.get("color_scheme", '["BD3039", "0C2340", "BD3039", "0C2340", "FFFFFF"]')
    color_scheme = json.decode(color_scheme)
    show_scores = config.bool("show_scores", False)

    if client_id and client_secret and refresh_token:
        access_token = get_access_token(client_id, client_secret, refresh_token)

        if (access_token):
            league_name = get_league_name(access_token, GAME_KEY, league_number)

            if (league_name):
                if show_scores:
                    entries_to_display = 2
                    current_matchup = get_current_matchup(access_token, GAME_KEY, league_number)

                    render_category.extend(
                        [
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = render_current_matchup(current_matchup, entries_to_display, heading_font_color, color_scheme, league_name),
                                    ),
                                ],
                            ),
                        ],
                    )
                else:
                    entries_to_display = teams_per_view
                    standings = get_standings_and_records(access_token, GAME_KEY, league_number)

                    for x in range(0, len(standings), entries_to_display):
                        render_category.extend(
                            [
                                render.Column(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name),
                                        ),
                                    ],
                                ),
                            ],
                        )

                return render.Root(
                    delay = int(rotation_speed) * 1000,
                    show_full_animation = True,
                    child = render.Animation(children = render_category),
                )
            else:
                error_message = "Please check your league number."
                return render.Root(
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(error_message),
                    ),
                )
        else:
            error_message = "Unable to acquire an access token from the refresh token."
            return render.Root(
                child = render.Marquee(
                    width = 64,
                    child = render.Text(error_message),
                ),
            )
    else:
        entries_to_display = teams_per_view
        league_name = "Yahoo Fantasy"

        standings = [{"Name": "Stealing Signals", "Standings": "1", "Wins": "11", "Losses": "0", "Ties": "0"}, {"Name": "Me Casas Su Casas", "Standings": "2", "Wins": "8", "Losses": "2", "Ties": "1"}, {"Name": "Judge Dread", "Standings": "3", "Wins": "8", "Losses": "3", "Ties": "0"}, {"Name": "A Christmas Carroll", "Standings": "4", "Wins": "8", "Losses": "5", "Ties": "1"}, {"Name": "Judge and Eury Perez", "Standings": "5", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "You're Making Me Mervis", "Standings": "6", "Wins": "8", "Losses": "6", "Ties": "0"}, {"Name": "Honey Nut Chourio", "Standings": "7", "Wins": "5", "Losses": "9", "Ties": "0"}, {"Name": "Jordan Lawler n Orderler", "Standings": "8", "Wins": "3", "Losses": "11", "Ties": "0"}, {"Name": "Jack Cigarette Leiter", "Standings": "9", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "Jake Burger in Paradise", "Standings": "10", "Wins": "6", "Losses": "8", "Ties": "0"}, {"Name": "Triston the Night Away", "Standings": "11", "Wins": "4", "Losses": "10", "Ties": "0"}, {"Name": "Men Behaving Adley", "Standings": "12", "Wins": "6", "Losses": "8", "Ties": "0"}]
        for x in range(0, len(standings), entries_to_display):
            render_category.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name),
                            ),
                        ],
                    ),
                ],
            )

        return render.Root(
            delay = int(rotation_speed) * 1000,
            show_full_animation = True,
            child = render.Animation(children = render_category),
        )

rotation_options = [
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

teams_per_view_options = [
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
]

color_scheme_options = [
    schema.Option(
        display = "Blue",
        value = json.encode(["0A2647", "144272", "205295", "2C74B3", "FFFFFF"]),
    ),
    schema.Option(
        display = "Arizona Diamondbacks",
        value = json.encode(["A71930", "000000", "A71930", "000000", "E3D4AD"]),
    ),
    schema.Option(
        display = "Atlanta Braves",
        value = json.encode(["CE1141", "13274F", "CE1141", "13274F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Baltimore Orioles",
        value = json.encode(["DF4601", "000000", "DF4601", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Boston Red Sox",
        value = json.encode(["BD3039", "0C2340", "BD3039", "0C2340", "FFFFFF"]),
    ),
    schema.Option(
        display = "Chicago Cubs",
        value = json.encode(["0E3386", "CC3433", "0E3386", "CC3433", "FFFFFF"]),
    ),
    schema.Option(
        display = "Chicago White Sox",
        value = json.encode(["27251F", "27251F", "27251F", "27251F", "C4CED4"]),
    ),
    schema.Option(
        display = "Cincinnati Reds",
        value = json.encode(["C6011F", "000000", "C6011F", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Cleveland Indians",
        value = json.encode(["00385D", "E50022", "00385D", "E50022", "FFFFFF"]),
    ),
    schema.Option(
        display = "Colorado Rockies",
        value = json.encode(["333366", "131413", "333366", "131413", "FFFFFF"]),
    ),
    schema.Option(
        display = "Detroit Tigers",
        value = json.encode(["0C2340", "FA4616", "0C2340", "FA4616", "FFFFFF"]),
    ),
    schema.Option(
        display = "Houston Astros",
        value = json.encode(["002D62", "EB6E1F", "002D62", "EB6E1F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Kansas City Royals",
        value = json.encode(["004687", "BD9B60", "004687", "BD9B60", "FFFFFF"]),
    ),
    schema.Option(
        display = "Los Angeles Angels",
        value = json.encode(["003263", "BA0021", "003263", "BA0021", "FFFFFF"]),
    ),
    schema.Option(
        display = "Los Angeles Dodgers",
        value = json.encode(["005A9C", "EF3E42", "005A9C", "EF3E42", "FFFFFF"]),
    ),
    schema.Option(
        display = "Miami Marlins",
        value = json.encode(["00A3E0", "000000", "00A3E0", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Milwaukee Brewers",
        value = json.encode(["12284B", "FFC52F", "12284B", "FFC52F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Minnesota Twins",
        value = json.encode(["002B5C", "D31145", "002B5C", "D31145", "FFFFFF"]),
    ),
    schema.Option(
        display = "Montreal Expos",
        value = json.encode(["003087", "E4002B", "003087", "E4002B", "FFFFFF"]),
    ),
    schema.Option(
        display = "New York Mets",
        value = json.encode(["002D72", "FF5910", "002D72", "FF5910", "FFFFFF"]),
    ),
    schema.Option(
        display = "New York Yankees",
        value = json.encode(["0C2340", "0C2340", "0C2340", "0C2340", "C4CED3"]),
    ),
    schema.Option(
        display = "Okaland Athletics",
        value = json.encode(["003831", "EFB21E", "003831", "EFB21E", "FFFFFF"]),
    ),
    schema.Option(
        display = "Philadelphia Phillies",
        value = json.encode(["E81828", "002D72", "E81828", "002D72", "FFFFFF"]),
    ),
    schema.Option(
        display = "Pittsburgh Pirates",
        value = json.encode(["27251F", "27251F", "27251F", "27251F", "FDB827"]),
    ),
    schema.Option(
        display = "St. Louis Cardinals",
        value = json.encode(["C41E3A", "0C2340", "C41E3A", "0C2340", "FFFFFF"]),
    ),
    schema.Option(
        display = "San Deigo Padres",
        value = json.encode(["2F241D", "FFC425", "2F241D", "FFC425", "FFFFFF"]),
    ),
    schema.Option(
        display = "San Francisco Giants",
        value = json.encode(["FD5A1E", "27251F", "FD5A1E", "27251F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Seattle Mariners",
        value = json.encode(["0C2C56", "005C5C", "0C2C56", "005C5C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Tampa Bay Rays",
        value = json.encode(["092C5C", "8FBCE6", "092C5C", "8FBCE6", "FFFFFF"]),
    ),
    schema.Option(
        display = "Texas Rangers",
        value = json.encode(["003278", "C0111F", "003278", "C0111F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Toronto Blue Jays",
        value = json.encode(["134A8E", "1D2D5C", "134A8E", "1D2D5C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Washington Nationals",
        value = json.encode(["AB0003", "14225A", "AB0003", "14225A", "FFFFFF"]),
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "yahoo_client_id",
                name = "Yahoo Client ID",
                desc = "Consumer Key from your Yahoo-approved Fantasy Sports application.",
                icon = "key",
                secret = True,
                default = "",
            ),
            schema.Text(
                id = "yahoo_client_secret",
                name = "Yahoo Client Secret",
                desc = "Consumer Secret from your Yahoo-approved Fantasy Sports application.",
                icon = "key",
                secret = True,
                default = "",
            ),
            schema.Text(
                id = "yahoo_refresh_token",
                name = "Yahoo Refresh Token",
                desc = "Refresh token created with Yahoo's authorization-code flow and redirect URI oob.",
                icon = "key",
                secret = True,
                default = "",
            ),
            schema.Text(
                id = "league_number",
                name = "League Number",
                desc = "Type in the league number for your league. Go to your league in a browser and look at the URL. It should end in /b1 then /#######. Input just those numbers here.",
                icon = "hashtag",
                default = "",
            ),
            schema.Toggle(
                id = "show_scores",
                name = "Show Scores",
                desc = "Show scores instead of standings",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "rotation_speed",
                name = "Rotation Speed",
                desc = "Seconds per rotation",
                icon = "gear",
                default = rotation_options[1].value,
                options = rotation_options,
            ),
            schema.Dropdown(
                id = "teams_per_view",
                name = "Teams Per View",
                desc = "Number of teams to show at once (standings only)",
                icon = "gear",
                default = teams_per_view_options[1].value,
                options = teams_per_view_options,
            ),
            schema.Color(
                id = "heading_font_color",
                name = "Font Color",
                desc = "Heading font color",
                icon = "brush",
                default = "#FFA500",
                palette = [
                    "#FFF",
                    "#FF0",
                    "#F00",
                    "#00F",
                    "#0F0",
                    "#FFA500",
                ],
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color Scheme",
                desc = "Select the color scheme",
                icon = "gear",
                default = color_scheme_options[4].value,
                options = color_scheme_options,
            ),
        ],
    )

def get_access_token(client_id, client_secret, refresh_token):
    response = http.post(
        YAHOO_OAUTH_TOKEN_URL,
        headers = {
            "Authorization": "Basic " + base64.encode(client_id + ":" + client_secret),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        form_body = {
            "grant_type": "refresh_token",
            "redirect_uri": YAHOO_REDIRECT_URI,
            "refresh_token": refresh_token,
        },
    )
    if response.status_code != 200:
        return ""

    return response.json().get("access_token", "")

def get_league_name(access_token, GAME_KEY, league_number):
    league_name = ""

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    league_name_response = http.get(url, headers = headers)
    league_name = xpath.loads(league_name_response.body()).query("/fantasy_content/league/name")
    return league_name

def get_standings_and_records(access_token, GAME_KEY, league_number):
    allstandings = []

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number + "/standings"
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    standings_response = http.get(url, headers = headers)

    total_teams = int(xpath.loads(standings_response.body()).query("/fantasy_content/league/standings/teams/@count"))
    team_names = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/name")
    team_standings = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/rank")
    team_wins = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/wins")
    team_losses = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/losses")
    team_ties = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/ties")

    for team_number in range(total_teams):
        allstandings.append({"Name": team_names[team_number], "Standings": team_standings[team_number], "Wins": team_wins[team_number], "Losses": team_losses[team_number], "Ties": team_ties[team_number]})

    return allstandings

def render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, leagueName):
    output = []
    teamTies = ""
    teamWins = ""
    teamLosses = ""

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = heading_font_color, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entries_to_display)
    for i in range(entries_to_display):
        if i + x < len(standings):
            mainFont = "CG-pixel-3x5-mono"
            teamName = standings[i + x]["Name"]
            teamWins = standings[i + x]["Wins"]
            teamLosses = standings[i + x]["Losses"]
            teamTies = standings[i + x]["Ties"]
            totalGames = int(teamWins) + int(teamLosses) + int(teamTies)
            if totalGames > 0:
                teamRecord = ((2 * int(teamWins) + int(teamTies)) / (2 * int(totalGames)))
                if teamRecord != 1:
                    # Multiply by 1000 and then truncate because there is no format library and we want a constant 3 digits after decimal.
                    teamRecord *= 1000
                    teamRecord = humanize.ftoa(teamRecord)
                    teamRecord = "." + teamRecord[-3:]
                else:
                    teamRecord = "1.00"
            else:
                teamRecord = "0.00"
            teamNameBoxSize = 40
            recordBoxSize = 20
            teamName = teamName[:10]

            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            elif i == 2:
                teamColor = "#" + color_scheme[2]
            else:
                teamColor = "#" + color_scheme[3]
            textColor = "#" + color_scheme[4]

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = teamNameBoxSize, height = containerHeight, child = render.Text(content = teamName, color = textColor, font = mainFont)),
                        render.Box(width = 4, height = containerHeight, child = render.Text(content = "", color = textColor, font = mainFont)),
                        render.Box(width = recordBoxSize, height = containerHeight, child = render.Text(content = str(teamRecord), color = textColor, font = mainFont)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output

def get_current_matchup(access_token, GAME_KEY, league_number):
    current_matchup = []

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number + "/scoreboard"
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    current_matchup_response = http.get(url, headers = headers)

    # owners_team = xpath.loads(current_matchup_response.body()).query("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//preceding-sibling::name/text()")
    # print("Owner's Team: " + str(owners_team))

    teams_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/name")
    scores_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/team_points/total")

    for i in range(2):
        current_matchup.append({"Name": teams_in_matchup_xml[i], "Score": scores_in_matchup_xml[i]})

    return current_matchup

def render_current_matchup(current_matchup, entries_to_display, heading_font_color, color_scheme, leagueName):
    output = []

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = heading_font_color, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entries_to_display)
    for i in range(2):
        if i < len(current_matchup):
            mainFont = "CG-pixel-3x5-mono"
            teamName = current_matchup[i]["Name"]
            teamName = teamName[:11]
            teamColor = ""
            teamScore = current_matchup[i]["Score"]
            teamNameBoxSize = 46
            scoreBoxSize = 18
            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            textColor = "#" + color_scheme[4]

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = teamNameBoxSize, height = containerHeight, child = render.Text(content = teamName, color = textColor, font = mainFont)),
                        render.Box(width = 4, height = containerHeight, child = render.Text(content = "", color = textColor, font = mainFont)),
                        render.Box(width = scoreBoxSize, height = containerHeight, child = render.Text(content = teamScore, color = textColor, font = mainFont)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output
