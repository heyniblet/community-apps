load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FOOTBALL_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
BASEBALL_URL = "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard"
HOCKEY_URL = "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard"
BASKETBALL_URL = "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard"

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

NFL_TEAMS = {
    "Arizona Cardinals": "22",
    "Atlanta Falcons": "1",
    "Baltimore Ravens": "33",
    "Buffalo Bills": "2",
    "Carolina Panthers": "29",
    "Chicago Bears": "3",
    "Cincinnati Bengals": "4",
    "Cleveland Browns": "5",
    "Dallas Cowboys": "6",
    "Denver Broncos": "7",
    "Detroit Lions": "8",
    "Green Bay Packers": "9",
    "Houston Texans": "34",
    "Indianapolis Colts": "11",
    "Jacksonville Jaguars": "30",
    "Kansas City Chiefs": "12",
    "Las Vegas Raiders": "13",
    "Los Angeles Chargers": "24",
    "Los Angeles Rams": "14",
    "Miami Dolphins": "15",
    "Minnesota Vikings": "16",
    "New England Patriots": "17",
    "New Orleans Saints": "18",
    "New York Giants": "19",
    "New York Jets": "20",
    "Philadelphia Eagles": "21",
    "Pittsburgh Steelers": "23",
    "San Francisco 49ers": "25",
    "Seattle Seahawks": "26",
    "Tampa Bay Buccaneers": "27",
    "Tennessee Titans": "10",
    "Washington Commanders": "28",
}

MLB_TEAMS = {
    "Arizona Diamondbacks": "29",
    "Atlanta Braves": "15",
    "Baltimore Orioles": "1",
    "Boston Red Sox": "2",
    "Chicago Cubs": "16",
    "Chicago White Sox": "4",
    "Cincinnati Reds": "17",
    "Cleveland Guardians": "5",
    "Colorado Rockies": "27",
    "Detroit Tigers": "6",
    "Houston Astros": "18",
    "Kansas City Royals": "7",
    "Los Angeles Angels": "3",
    "Los Angeles Dodgers": "19",
    "Miami Marlins": "28",
    "Milwaukee Brewers": "8",
    "Minnesota Twins": "9",
    "New York Mets": "21",
    "New York Yankees": "10",
    "Oakland Athletics": "11",
    "Philadelphia Phillies": "22",
    "Pittsburgh Pirates": "23",
    "San Diego Padres": "25",
    "San Francisco Giants": "26",
    "Seattle Mariners": "12",
    "St. Louis Cardinals": "24",
    "Tampa Bay Rays": "30",
    "Texas Rangers": "13",
    "Toronto Blue Jays": "14",
    "Washington Nationals": "20",
}

NHL_TEAMS = {
    "Anaheim Ducks": "25",
    "Arizona Coyotes": "24",
    "Boston Bruins": "1",
    "Buffalo Sabres": "2",
    "Calgary Flames": "3",
    "Carolina Hurricanes": "7",
    "Chicago Blackhawks": "4",
    "Colorado Avalanche": "17",
    "Columbus Blue Jackets": "29",
    "Dallas Stars": "9",
    "Detroit Red Wings": "5",
    "Edmonton Oilers": "6",
    "Florida Panthers": "26",
    "Los Angeles Kings": "8",
    "Minnesota Wild": "30",
    "Montreal Canadiens": "10",
    "Nashville Predators": "27",
    "New Jersey Devils": "11",
    "New York Islanders": "12",
    "New York Rangers": "13",
    "Ottawa Senators": "14",
    "Philadelphia Flyers": "15",
    "Pittsburgh Penguins": "16",
    "San Jose Sharks": "18",
    "Seattle Kraken": "124292",
    "St. Louis Blues": "19",
    "Tampa Bay Lightning": "20",
    "Toronto Maple Leafs": "21",
    "Vancouver Canucks": "22",
    "Vegas Golden Knights": "37",
    "Washington Capitals": "23",
    "Winnipeg Jets": "28",
}

NBA_TEAMS = {
    "Atlanta Hawks": "1",
    "Boston Celtics": "2",
    "Brooklyn Nets": "17",
    "Charlotte Hornets": "30",
    "Chicago Bulls": "4",
    "Cleveland Cavaliers": "5",
    "Dallas Mavericks": "6",
    "Denver Nuggets": "7",
    "Detroit Pistons": "8",
    "Golden State Warriors": "9",
    "Houston Rockets": "10",
    "Indiana Pacers": "11",
    "LA Clippers": "12",
    "Los Angeles Lakers": "13",
    "Memphis Grizzlies": "29",
    "Miami Heat": "14",
    "Milwaukee Bucks": "15",
    "Minnesota Timberwolves": "16",
    "New Orleans Pelicans": "3",
    "New York Knicks": "18",
    "Oklahoma City Thunder": "25",
    "Orlando Magic": "19",
    "Philadelphia 76ers": "20",
    "Phoenix Suns": "21",
    "Portland Trail Blazers": "22",
    "Sacramento Kings": "23",
    "San Antonio Spurs": "24",
    "Toronto Raptors": "28",
    "Utah Jazz": "26",
    "Washington Wizards": "27",
}

def get_events_with_competitor(all_events, id):
    events_with_competitor = []
    for event in all_events[:100]:
        competitions = event.get("competitions", []) if type(event) == "dict" else []
        for competition in (competitions[:4] if type(competitions) == "list" else []):
            competitors = competition.get("competitors", []) if type(competition) == "dict" else []
            for competitor in (competitors[:4] if type(competitors) == "list" else []):
                if type(competitor) == "dict" and competitor.get("id") == id:
                    events_with_competitor.append(event)
    return events_with_competitor

def fetch_events(url):
    rep = http.get(url, ttl_seconds = 120)
    body = rep.body()
    data = json.decode(body, {}) if rep.status_code == 200 and body and len(body) <= 512 * 1024 else {}
    events = data.get("events", []) if type(data) == "dict" else []
    return events[:100] if type(events) == "list" else []

def render_event_status(event, timezone):
    if event["status"]["type"]["name"] == "STATUS_SCHEDULED":
        return [
            render.Text(
                height = 6,
                font = "tom-thumb",
                content = time.parse_time(event["date"].replace("Z", ":00Z")).in_location(timezone).format("1/2  3:04 PM"),
                color = "#FCF9D9",
                offset = -1,
            ),
        ]
    else:
        return [
            render.Text(
                height = 6,
                color = "#FCF9D9",
                font = "tom-thumb",
                content = event["status"]["type"]["shortDetail"],
                offset = -1,
            ),
        ]

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location, {}) if type(location) == "string" and len(location) <= 4096 else {}
    timezone = loc.get("timezone", "UTC") if type(loc) == "dict" else "UTC"
    if type(timezone) != "string" or not time.is_valid_timezone(timezone):
        timezone = "UTC"

    my_nfl_teams = []
    for team in NFL_TEAMS.keys():
        if (config.bool(team)):
            my_nfl_teams.append(team)

    my_mlb_teams = []
    for team in MLB_TEAMS.keys():
        if (config.bool(team)):
            my_mlb_teams.append(team)

    my_nhl_teams = []
    for team in NHL_TEAMS.keys():
        if (config.bool(team)):
            my_nhl_teams.append(team)

    my_nba_teams = []
    for team in NBA_TEAMS.keys():
        if (config.bool(team)):
            my_nba_teams.append(team)

    my_nfl_events = []
    nfl_events = fetch_events(FOOTBALL_URL) if my_nfl_teams else []
    for team in my_nfl_teams:
        my_nfl_events.extend(get_events_with_competitor(nfl_events, NFL_TEAMS[team]))

    my_mlb_events = []
    mlb_events = fetch_events(BASEBALL_URL) if my_mlb_teams else []
    for team in my_mlb_teams:
        my_mlb_events.extend(get_events_with_competitor(mlb_events, MLB_TEAMS[team]))

    my_nhl_events = []
    nhl_events = fetch_events(HOCKEY_URL) if my_nhl_teams else []
    for team in my_nhl_teams:
        my_nhl_events.extend(get_events_with_competitor(nhl_events, NHL_TEAMS[team]))

    my_nba_events = []
    nba_events = fetch_events(BASKETBALL_URL) if my_nba_teams else []
    for team in my_nba_teams:
        my_nba_events.extend(get_events_with_competitor(nba_events, NBA_TEAMS[team]))

    my_events = my_nfl_events + my_mlb_events + my_nba_events + my_nhl_events

    rows = []
    for event in my_events:
        away_team = event["competitions"][0]["competitors"][1]["team"]
        home_team = event["competitions"][0]["competitors"][0]["team"]
        rows.append(render.Row(
            main_align = "start",
            cross_align = "start",
            children = render_event_status(event, timezone),
        ))
        rows.append(render.Row(
            children = [
                render.Box(
                    child = render.Text(
                        font = "5x8",
                        content = away_team["abbreviation"],
                        color = away_team.get("alternateColor", "#ffffff"),
                    ),
                    height = 10,
                    width = 18,
                    color = away_team.get("color", "#000000"),
                ),
                render.Box(
                    child = render.Text(
                        content = event["competitions"][0]["competitors"][1]["score"],
                        color = away_team.get("color", "#000000"),
                        font = "5x8",
                    ),
                    height = 10,
                    width = 14,
                    color = away_team.get("alternateColor", "#ffffff"),
                ),
                render.Box(
                    child = render.Text(
                        font = "5x8",
                        content = home_team["abbreviation"],
                        color = home_team.get("alternateColor", "#ffffff"),
                    ),
                    height = 10,
                    width = 18,
                    color = home_team.get("color", "#000000"),
                ),
                render.Box(
                    child = render.Text(
                        content = event["competitions"][0]["competitors"][0]["score"],
                        color = home_team.get("color", "#000000"),
                        font = "5x8",
                    ),
                    height = 10,
                    width = 14,
                    color = home_team.get("alternateColor", "#ffffff"),
                ),
            ],
        ))

    if (len(rows) == 0):
        return render.Root(
            render.Box(
                render.WrappedText("[No Games]"),
            ),
        )

    return render.Root(
        show_full_animation = True,
        delay = 350,
        child = render.Marquee(
            child = render.Column(
                children = rows,
                cross_align = "start",
                main_align = "start",
            ),
            scroll_direction = "vertical",
            height = 32,
        ),
    )

def get_schema():
    nfl_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "NFL - " + team,
            icon = "football",
            default = team == "Minnesota Vikings",
        )
        for team in NFL_TEAMS.keys()
    ]
    mlb_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "MLB - " + team,
            icon = "baseball",
            default = team == "Minnesota Twins",
        )
        for team in MLB_TEAMS.keys()
    ]

    nba_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "NBA - " + team,
            icon = "basketball",
            default = team == "Minnesota Timberwolves",
        )
        for team in NBA_TEAMS.keys()
    ]

    nhl_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "NHL - " + team,
            icon = "hockeyPuck",
            default = team == "Minnesota Wild",
        )
        for team in NHL_TEAMS.keys()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for diplaying local game times.",
                icon = "locationDot",
            ),
        ] + nfl_options + mlb_options + nba_options + nhl_options,
    )
