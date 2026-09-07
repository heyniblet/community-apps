""" 
Fortnite Win Tracker by Hunter Berry

Applet/App Name: Fortnite Win Tracker
Author: Hunter Berry (https://www.github.com/HunBurry)
Summary: Tracks Fortnite wins. 
Description: Shows how many wins the user has in each main game mode (i.e., Solos, Duos, Trios, and Squads).

Example gif generated through the following command: 
    pixlet render fortnite_wins.star username="HunBurry05" show_kd=True show_win_rate=True --gif --magnify 10
"""

######################################################################################### Loads/Imports #########################################################################################

load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon_left.png", ICON_LEFT_ASSET = "file")
load("images/icon_right.png", ICON_RIGHT_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICON_LEFT = ICON_LEFT_ASSET.readall()
ICON_RIGHT = ICON_RIGHT_ASSET.readall()

######################################################################################### Global Variables #########################################################################################

yellow = "#ffcc66"
blue = "#3399ff"
default_username = ""

#

######################################################################################### Helper Functions ########################################################################################

def float_to_string_without_trailing_decimal(f):
    if type(f) not in ["int", "float"]:
        return "0"
    if f % 1 == 0:
        return str(int(f))
    else:
        return str(f)

def encode_display_name(value):
    if type(value) != "string" or not value or len(value) > 32:
        return None
    encoded = ""
    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ ."
    for char in value.codepoints():
        if char not in allowed:
            return None
        encoded += "%20" if char == " " else char
    return encoded

def get_mode_stats(payload, mode):
    global_stats = payload.get("global_stats", {}) if type(payload) == "dict" else {}
    direct = global_stats.get(mode, {}) if type(global_stats) == "dict" else {}
    if mode in global_stats and type(direct) == "dict":
        return {
            "wins": direct.get("placetop1", direct.get("wins", 0)),
            "kd": direct.get("kd", 0),
            "winrate": direct.get("winrate", direct.get("winRate", 0)),
        }

    flat = payload.get("stats", payload) if type(payload) == "dict" else {}
    if type(flat) != "dict":
        return {"wins": 0, "kd": 0, "winrate": 0}

    marker = {
        "solo": "solo",
        "duo": "duo",
        "trio": "trio",
        "squad": "squad",
    }[mode]
    result = {"wins": 0, "kd": 0, "winrate": 0}
    kills = 0
    matches = 0
    for key in list(flat.keys())[:5000]:
        value = flat[key]
        lowered = str(key).lower()
        if marker not in lowered or type(value) not in ["int", "float"]:
            continue
        if "placetop1" in lowered or lowered.endswith("_wins"):
            result["wins"] += value
        elif "kills" in lowered:
            kills += value
        elif "matchesplayed" in lowered or "matches_played" in lowered:
            matches += value
        elif lowered.endswith("_kd"):
            result["kd"] = value
        elif "winrate" in lowered or "win_rate" in lowered:
            result["winrate"] = value
    if result["kd"] == 0 and matches > result["wins"]:
        result["kd"] = kills / (matches - result["wins"])
    if result["winrate"] == 0 and matches > 0:
        result["winrate"] = result["wins"] * 100 / matches
    return result

######################################################################################### Main Function #########################################################################################

def main(config):
    decrypted_key = config.get("fortnite_api_key")
    if type(decrypted_key) != "string" or not decrypted_key or len(decrypted_key) > 2048 or "\r" in decrypted_key or "\n" in decrypted_key:
        return render.Root(
            child = render.WrappedText("API Key not set", color = "#ff0000"),
        )

    headers = {
        "x-api-key": decrypted_key,
    }

    username = config.str("username", default_username)
    show_kd = config.bool("show_kd")
    win_rate = config.bool("show_win_rate")

    encoded_username = encode_display_name(username)
    if not encoded_username:
        message = "No username found... Input a username in the app to check your wins here!"
    else:
        primary_url = "https://prod.api-fortnite.com/api/v1/account/displayName/" + encoded_username
        accountID_request = http.get(primary_url, headers = headers)

        if accountID_request.status_code != 200 or len(accountID_request.body()) > 256 * 1024:
            message = "Couldn't find your Epic account information... Make sure to use your Epic account username and not your display name!"
        else:
            account_payload = json.decode(accountID_request.body(), {})
            accountID = account_payload.get("id") or account_payload.get("accountId") if type(account_payload) == "dict" else None
            if type(accountID) != "string" or not accountID or len(accountID) > 64 or not all([char.isalnum() or char in "-_" for char in accountID.codepoints()]):
                message = "We couldn't find a Fortnite account associated with the given Epic username."
            else:
                secondary_url = "https://prod.api-fortnite.com/api/v2/stats/" + accountID
                playerStats_request = http.get(secondary_url, headers = headers)
                if playerStats_request.status_code == 403:
                    message = "This Fortnite account has Public Game Stats disabled."
                elif playerStats_request.status_code != 200 or len(playerStats_request.body()) > 2 * 1024 * 1024:
                    message = "Fortnite stats are unavailable right now."
                else:
                    player_stats = json.decode(playerStats_request.body(), {})
                    values = []
                    for mode in ["solo", "duo", "trio", "squad"]:
                        stats = get_mode_stats(player_stats, mode)
                        label = mode.capitalize() + "s: " + float_to_string_without_trailing_decimal(stats["wins"])
                        if show_kd:
                            label += " (K/D: " + float_to_string_without_trailing_decimal(stats["kd"]) + ")"
                        if win_rate:
                            label += " (Win: " + float_to_string_without_trailing_decimal(stats["winrate"]) + "%)"
                        values.append(label)
                    message = "    ".join(values)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Image(
                                    src = ICON_LEFT,
                                    width = 16,
                                    height = 16,
                                ),
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (4, 0, 0, 0),
                                            child = render.WrappedText(
                                                content = "Fortnite Win Tracker",
                                                color = yellow,
                                                align = "center",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 48,
                    child = render.Text(
                        message,
                        color = blue,
                    ),
                ),
            ],
        ),
    )

########################################################################################### Schema ###########################################################################################

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fortnite_api_key",
                name = "Fortnite API Key",
                desc = "Your api-fortnite.com API key. See https://api-fortnite.com/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "username",
                name = "Fortnite Username",
                desc = "Fortnite/Epic Games Username. Please note this may or may not be the same as your display name.",
                icon = "user",
            ),
            schema.Toggle(
                id = "show_kd",
                name = "Show K/D Ratio?",
                desc = "Turn on to show your K/D ratio for each game mode alongside your wins.",
                icon = "gun",
                default = False,
            ),
            schema.Toggle(
                id = "show_win_rate",
                name = "Show Win Rate?",
                desc = "Turn on to show your win/loss ratio for each game mode alongside your wins.",
                icon = "crown",
                default = False,
            ),
        ],
    )
