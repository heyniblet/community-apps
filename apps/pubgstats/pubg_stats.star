"""
Applet: PUBG Stats
Summary: Shows PUBG Player Stats
Description: Displays individual player's gaming stats from PlayerUnknown's Battlegrounds.
Author: joes-io
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/pubg_logo.png", PUBG_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PUBG_LOGO = PUBG_LOGO_ASSET.readall()

# Default settings if no configuration set in Tidbyt app
DEFAULT_PLAYER_NAME = "chocoTaco"
DEFAULT_PLATFORM = "steam"
DEFAULT_SELECTED_STAT = "wins"
PLATFORMS = ["steam", "psn", "xbox", "stadia", "kakao"]
MAX_RESPONSE_BYTES = 262144

# App display options
background_color = "#eba919"
text_color = "#000000"
background_render = render.Box(width = 64, height = 32, color = background_color)

# Base64 PUBG logo displayed in app

# Cache timers for API calls (seconds)
# 604800 = 7 days
ttl_player_id = 604800

# 1800 = 30 minutes
ttl_lifetime_stats = 1800

# Animation settings (frames)
logo_delay = 20
logo_duration = 30
name_delay = logo_delay + 27
name_duration = 7
stat_label_delay = name_delay + 7
stat_label_duration = 7
stat_delay = stat_label_delay + 7
stat_duration = 7

# Tuples are 0 = Stat label shown in options, 1 = API use, 2 = Tidbyt display label, 3 = Tidbyt display units of measure (if any)
stat_details = [
    ("Chicken Dinners (Wins)", "wins", "CHICKEN DINNERS", ""),
    ("Kills", "kills", "KILLS", ""),
    ("Headshots", "headshotKills", "HEADSHOTS", ""),
    ("Assists", "assists", "ASSISTS", ""),
    ("Enemies Knocked", "dBNOs", "KNOCKS", ""),
    ("Damage Dealt", "damageDealt", "DAMAGE DEALT", ""),
    ("Teammates Revived", "revives", "TEAMMATES REVIVED", ""),
    ("Teamkills", "teamKills", "TEAMKILLS", ""),
    ("Suicides", "suicides", "SUICIDES", ""),
    ("Heals Used", "heals", "HEALS USED", ""),
    ("Boosts Used", "boosts", "BOOSTS USED", ""),
    ("Weapons Picked Up", "weaponsAcquired", "WEAPONS PICKED UP", ""),
    ("Kills with Vehicles", "roadKills", "ROADKILLS", ""),
    ("Vehicles Destroyed", "vehicleDestroys", "VEHICLES DESTROYED", ""),
    ("Distance in Vehicles", "rideDistance", "VEHICLE DISTANCE RIDDEN", "km"),
    ("Distance Swam", "swimDistance", "SWAM", "m"),
    ("Distance Walked", "walkDistance", "WALKED", "km"),
    ("Time Survived", "timeSurvived", "TOTAL TIME SURVIVED", "m"),
    ("Days Played", "days", "DAYS PLAYED", ""),
    ("Rounds Played", "roundsPlayed", "ROUNDS PLAYED", ""),
    ("Top 10s", "top10s", "TOP TEN FINISHES", ""),
    ("Matches Lost", "losses", "MATCHES LOST", ""),
    ("Most Kills in a Match", "roundMostKills", "MOST MATCH KILLS", ""),
    ("Max Kill Streak", "maxKillStreaks", "MAX KILL STREAK", ""),
    ("Furthest Kill Distance", "longestKill", "FURTHEST KILL", "m"),
    ("Longest Time Survived in a Match", "longestTimeSurvived", "LONGEST MATCH", "s"),
    ("Past Day's Wins", "dailyWins", "PAST DAY'S WINS", ""),
    ("Past Day's Kills", "dailyKills", "PAST DAY'S KILLS", ""),
    ("Past Week's Wins", "weeklyWins", "PAST WEEK'S WINS", ""),
    ("Past Week's Kills", "weeklyKills", "PAST WEEK'S KILLS", ""),
]

def main(config):
    api_key = config.str("pubg_api_key", "")
    if not api_key:
        return pretty_message("ADD PUBG API KEY")

    header = {
        "Authorization": "Bearer {}".format(api_key),
        "Accept": "application/vnd.api+json",
    }

    # Load user settings from Tidbyt app, or grab defaults
    player_name = config.str("player_name", DEFAULT_PLAYER_NAME)
    platform = config.str("platform", DEFAULT_PLATFORM)
    selected_stat = config.str("selected_stat", DEFAULT_SELECTED_STAT)
    if platform not in PLATFORMS:
        platform = DEFAULT_PLATFORM
    if selected_stat not in [stat[1] for stat in stat_details]:
        selected_stat = DEFAULT_SELECTED_STAT

    # App defaults
    display_label = ""
    display_unit = ""

    # Get the player id from the player name and platform
    # URL to request player data
    url = "https://api.pubg.com/shards/{}/players?filter[playerNames]={}".format(platform, humanize.url_encode(player_name))

    # Request player data
    resp = http.get(url, headers = header, ttl_seconds = ttl_player_id)

    # Check for API errors
    if resp.status_code != 200:
        # Display error on Tidbyt and end
        return pretty_error(resp)

    # Get player id from API response
    player_data = decode_response(resp)
    players = player_data.get("data", []) if type(player_data) == "dict" else []
    if type(players) != "list" or len(players) == 0 or type(players[0]) != "dict" or type(players[0].get("id")) != "string":
        return pretty_message("PLAYER NOT FOUND")
    player_id = players[0]["id"]

    # URL to request lifetime stats for player
    url = "https://api.pubg.com/shards/{}/players/{}/seasons/lifetime".format(platform, player_id)

    # Add gamepad filter to Stadia API requests
    if platform == "stadia":
        url = url + "?filter[gamepad]=true"

    # Request lifetime stats for player
    resp = http.get(url, headers = header, ttl_seconds = ttl_lifetime_stats)

    # Check for API errors
    if resp.status_code != 200:
        # Display error on Tidbyt and end
        return pretty_error(resp)

    # Encode JSON data to be stored in cache
    lifetime_stats = decode_response(resp)
    if type(lifetime_stats) != "dict":
        return pretty_message("INVALID API RESPONSE")

    # Find label and unit type to display for selected stat
    for i in stat_details:
        if i[1] == selected_stat:
            display_label = i[2]
            display_unit = i[3]
            break

    display_label_len = len(display_label)

    # If label for stat is too wide then replicate label and marquee scroll with a longer end delay for readability
    if display_label_len > 12:
        end_delay = display_label_len * 7
        display_label = display_label + "   " + display_label + "   " + display_label
        stat_label_child = render.Marquee(width = 64, offset_start = 64, child = render.Text(content = display_label, color = text_color))
    else:
        end_delay = 0
        stat_label_child = render.Text(content = display_label, color = text_color)

    # Render output to display
    return render.Root(
        render.Stack(
            children = [
                # Background
                background_render,

                # PUBG logo animation
                animation.Transformation(
                    child = render.Image(src = PUBG_LOGO),
                    duration = logo_duration,
                    delay = logo_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(-64, 0)],
                        ),
                    ],
                ),

                # Scrolling name animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 2, 0, 0),
                        child = render.Text(
                            content = player_name,
                            font = "CG-pixel-3x5-mono",
                            color = text_color,
                        ),
                    ),
                    duration = name_duration,
                    delay = name_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # Scrolling stat label animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 10, 0, 0),
                        child = stat_label_child,
                    ),
                    duration = stat_label_duration,
                    delay = stat_label_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # Scrolling stat animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 18, 0, 0),
                        child = render.Text(
                            content = (calc_lifetime_stat(lifetime_stats, selected_stat) + display_unit),
                            font = "6x13",
                            color = text_color,
                        ),
                    ),
                    duration = stat_duration,
                    delay = stat_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # End delay animation
                animation.Transformation(
                    child = render.Box(),
                    duration = 0,
                    delay = end_delay,
                    keyframes = [],
                ),
            ],
        ),
    )

# Return render of scrolling error message for Tidbyt display
def pretty_error(resp):
    # Get plaintext error from API response
    if resp.status_code == 401:
        error = "BAD AUTHORIZATION"
    else:
        data = decode_response(resp)
        errors = data.get("errors", []) if type(data) == "dict" else []
        detail = errors[0].get("detail") if type(errors) == "list" and len(errors) > 0 and type(errors[0]) == "dict" else None
        error = detail.upper() if type(detail) == "string" else "REQUEST FAILED"

    return pretty_message(error)

def pretty_message(message):
    # Return render of error to Tidbyt
    return render.Root(
        render.Stack(
            children = [
                # Background
                background_render,

                # Error message
                render.Marquee(
                    width = 64,
                    child = render.Padding(
                        pad = (0, 11, 0, 0),
                        child = render.Text(
                            content = "PUBG STATS: {}".format(message),
                            color = text_color,
                        ),
                    ),
                ),
            ],
        ),
    )

# Return stat total from across all game modes
def calc_lifetime_stat(lifetime_stats, selected_stat):
    data = lifetime_stats.get("data", {})
    attributes = data.get("attributes", {}) if type(data) == "dict" else {}
    game_modes = attributes.get("gameModeStats", {}) if type(attributes) == "dict" else {}
    if type(game_modes) != "dict":
        return "NO DATA"
    lifetime_total_stat = 0
    for mode in ["duo", "duo-fpp", "solo", "solo-fpp", "squad", "squad-fpp"]:
        stats = game_modes.get(mode, {})
        value = stats.get(selected_stat, 0) if type(stats) == "dict" else 0
        if type(value) in ("int", "float"):
            lifetime_total_stat += value

    # Convert timeSurvived from seconds to minutes
    if selected_stat == "timeSurvived":
        lifetime_total_stat = lifetime_total_stat // 60

    # Convert rideDistance and walkDistance to km
    if selected_stat == "rideDistance" or selected_stat == "walkDistance":
        lifetime_total_stat = lifetime_total_stat // 1000

    # Make stat readable
    lifetime_total_stat = humanize.comma(int(lifetime_total_stat))

    # Return total lifetime stat
    return lifetime_total_stat

def decode_response(resp):
    body = resp.body()
    return json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None

# Defines app configuration settings available on Tidbyt mobile app
def get_schema():
    # List of options for gaming platform
    platforms = [
        schema.Option(
            display = "Steam",
            value = "steam",
        ),
        schema.Option(
            display = "PlayStation Network",
            value = "psn",
        ),
        schema.Option(
            display = "Xbox",
            value = "xbox",
        ),
        schema.Option(
            display = "Stadia",
            value = "stadia",
        ),
        schema.Option(
            display = "Kakao",
            value = "kakao",
        ),
    ]

    # List of options for stat to display
    stats = []
    for i in stat_details:
        stats.append(
            schema.Option(
                display = i[0],
                value = i[1],
            ),
        )

    # Configuration options available to user
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "player_name",
                name = "PUBG Player Name",
                desc = "Player name is case sensitive",
                icon = "user",
            ),
            schema.Dropdown(
                id = "platform",
                name = "Gaming Platform",
                desc = "Player's gaming platform",
                icon = "gamepad",
                default = platforms[0].value,
                options = platforms,
            ),
            schema.Dropdown(
                id = "selected_stat",
                name = "Stat to Display",
                desc = "Lifetime statistic to display",
                icon = "chartLine",
                default = stats[0].value,
                options = stats,
            ),
            schema.Text(
                id = "pubg_api_key",
                name = "PUBG API Key",
                desc = "A PUBG API key to access the PUBG API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
