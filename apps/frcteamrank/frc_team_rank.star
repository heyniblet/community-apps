"""
Applet: FRC Team Rank
Summary: Display FRC event ranking
Description: Displays the ranking of an FRC team at the team's active event.
Author: dragid10
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/default_team_avatar.png", DEFAULT_TEAM_AVATAR_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TEAM_AVATAR = DEFAULT_TEAM_AVATAR_ASSET.readall()

## ==================== BEGIN CONSTANTS ====================
IMG_MAX_WIDTH = 20
IMG_MAX_HEIGHT = 20
DATETIME_FORMAT = "yyyy-MM-dd"
MARQUEE_OFFSET_START = 15
MARQUEE_WIDTH = 40
WIDGET_HEIGHT = 1
WIDGET_COLOR = "#ffffff"

# Default values for UI display when API calls fail

DEFAULT_TEAM_NAME = "N/A"
DEFAULT_RANKING_MSG = "No Ranking"

# Use The Blue Alliance API to get the team's current competition ranking
TBA_BASE_URL = "https://www.thebluealliance.com/api/v3"
TBA_API_KEY_DEFAULT = "YOUR_TBA_READ_API_KEY_HERE"

## ==================== END CONSTANTS ====================

## ==================== BEGIN HELPER FUNCTIONS ====================
# Time and date helper functions
def get_year():
    """Returns the current year.

    Returns:
        Integer representing the current year
    """
    return time.now().year

def get_current_date():
    """Returns the current date formatted as YYYY-MM-DD.

    Returns:
        String representing the current date in YYYY-MM-DD format
    """
    formatted_time = humanize.time_format(DATETIME_FORMAT, time.now())
    return formatted_time

# Team information helper functions
def get_team_info(team_id, tba_api_key):
    """Fetches team information from The Blue Alliance API.

    Args:
        team_id: The FRC team ID in the format "frcXXXX"
        tba_api_key: The Blue Alliance API key

    Returns:
        Tuple containing team number (int) and team name (string)

    Raises:
        Error if API request fails
    """

    #  Make API call to get team info
    team_info_resp = http.get(
        "%s/team/%s" % (TBA_BASE_URL, team_id),
        headers = {"X-TBA-Auth-Key": tba_api_key},
    )

    # If the request fails, return an error message
    if team_info_resp.status_code != 200:
        return None

    # Parse the response JSON
    if len(team_info_resp.body()) > 2 * 1024 * 1024:
        return None
    team_info = json.decode(team_info_resp.body(), {})
    number = team_info.get("team_number") if type(team_info) == "dict" else None
    nickname = team_info.get("nickname") if type(team_info) == "dict" else None
    if type(number) != "int" or type(nickname) != "string" or not nickname:
        return None
    return number, nickname[:120]

def get_team_events_for_current_year(team_number, tba_api_key):
    """Fetches all events for a given team for the current year.

    Args:
        team_number: The FRC team number
        tba_api_key: The Blue Alliance API key

    Returns:
        List of events the team is participating in for the current year

    Raises:
        Error if API request fails
    """

    # Make API call to get team events
    team_events_url = "%s/team/frc%d/events/%d/simple" % (TBA_BASE_URL, team_number, get_year())
    team_events_resp = http.get(team_events_url, headers = {"X-TBA-Auth-Key": tba_api_key})

    # If the request fails, return an error message
    if team_events_resp.status_code != 200:
        return None

    # Parse the response JSON
    if len(team_events_resp.body()) > 2 * 1024 * 1024:
        return None
    team_events = json.decode(team_events_resp.body(), [])
    return team_events if type(team_events) == "list" else None

def get_team_ranking(team_number, event_key, tba_api_key):
    """Fetches team ranking for a specific event from The Blue Alliance API.

    Args:
        team_number: The FRC team number
        event_key: The event key identifier
        tba_api_key: The Blue Alliance API key

    Returns:
        Tuple containing team ranking (int) and total number of teams (int)

    Raises:
        Error if API request fails
    """
    team_ranking_resp = http.get(
        "%s/team/frc%d/event/%s/status" % (TBA_BASE_URL, team_number, event_key),
        headers = {"X-TBA-Auth-Key": tba_api_key},
    )

    # If the request fails, return an error message
    if team_ranking_resp.status_code != 200:
        return -1, 999

    # Parse the team ranking data using intermediate variables.
    # TBA returns qual/ranking/rank as nested objects, but any level can be
    # None (not just missing) when the event hasn't started matches yet.
    if len(team_ranking_resp.body()) > 2 * 1024 * 1024:
        return -1, 999
    ranking_data = json.decode(team_ranking_resp.body(), {})
    if type(ranking_data) != "dict":
        return -1, 999
    qual_data = ranking_data.get("qual")
    if type(qual_data) != "dict":
        return -1, 999

    ranking_info = qual_data.get("ranking")
    if type(ranking_info) != "dict":
        return -1, 999

    team_ranking = ranking_info.get("rank")
    if type(team_ranking) != "int" or team_ranking < 0:
        return -1, 999

    total_teams = ranking_info.get("num_teams", 999)
    if type(total_teams) != "int" or total_teams < team_ranking:
        total_teams = 999
    return team_ranking, total_teams

def build_avatar_url(team_number):
    """Builds the URL for a team's avatar on The Blue Alliance.

    Args:
        team_number: The FRC team number

    Returns:
        URL string to the team's avatar image
    """
    avatar_url = "https://www.thebluealliance.com/avatar/%s/frc%d.png" % (get_year(), team_number)
    return avatar_url

def get_team_avatar(team_number):
    """Retrieves a team's avatar image from The Blue Alliance.

    Args:
        team_number: The FRC team number

    Returns:
        Binary data of the team's avatar image

    Raises:
        Error if API request fails
    """
    avatar_url = build_avatar_url(team_number)

    avatar_resp = http.get(avatar_url)

    if avatar_resp.status_code != 200 or len(avatar_resp.body()) > 1024 * 1024:
        return None

    return avatar_resp.body()

## ==================== END HELPER FUNCTIONS ====================

## ==================== BEGIN MAIN FUNCTION ====================
def main(config):
    """Main entry point for the app.

    Args:
        config: Configuration dictionary containing user settings

    Returns:
        A render object representing the UI
    """

    # Get team number from the user
    team_number_input = config.get("team_number")
    if type(team_number_input) != "string" or not team_number_input.isdigit() or len(team_number_input) > 6 or int(team_number_input) <= 0:
        return message("Add an FRC team number")
    USER_INPUT_TEAM_NUMBER = "frc%s" % team_number_input

    # Parse the team number (assuming it's valid)
    team_number = int(team_number_input)

    # Initialize with default values from constants
    team_name = DEFAULT_TEAM_NAME
    team_ranking_msg = DEFAULT_RANKING_MSG
    team_avatar = DEFAULT_TEAM_AVATAR

    # Get Blue Alliance API key from the user
    TBA_API_KEY = config.get("tba_api_key", TBA_API_KEY_DEFAULT)

    # Check if we have a valid API key
    if valid_secret(TBA_API_KEY) and TBA_API_KEY != TBA_API_KEY_DEFAULT:
        # API key is valid, proceed with API calls

        # Get team info
        team_info = get_team_info(USER_INPUT_TEAM_NUMBER, TBA_API_KEY)
        if not team_info:
            return message("FRC team unavailable")
        team_number, team_name = team_info

        # Get team events
        team_events = get_team_events_for_current_year(team_number, TBA_API_KEY)
        if team_events == None:
            return message("FRC events unavailable")

        # Process events if any exist
        # Look for active events and get ranking
        current_date = get_current_date()

        # Check if there are any active events
        for event in team_events:
            if type(event) != "dict":
                continue
            event_start_date = event.get("start_date")
            event_end_date = event.get("end_date")

            if type(event_start_date) == "string" and type(event_end_date) == "string" and event_start_date <= current_date and current_date <= event_end_date:
                event_key = event.get("key")
                if type(event_key) != "string" or not event_key or len(event_key) > 32:
                    continue

                # Get ranking for the team's active event
                team_ranking, total_teams = get_team_ranking(team_number, event_key, TBA_API_KEY)

                # Update ranking message
                team_ranking_msg = "Rank: %d of %d" % (team_ranking, total_teams) if team_ranking >= 0 else DEFAULT_RANKING_MSG

                # Break after finding the first active event
                # Note: There should never be more than 1 active event
                break

        # Get team avatar - will use default if this fails
        team_avatar = get_team_avatar(team_number)

    else:
        return message("Add a TBA API key")

    # Create widgets with whatever data we have
    # Avatar widget - create a fallback if no avatar is available
    if team_avatar:
        TEAM_AVATAR_WIDGET = render.Column(
            children = [
                render.Image(
                    src = team_avatar,
                    width = IMG_MAX_WIDTH,
                    height = IMG_MAX_HEIGHT,
                ),
            ],
        )
    else:
        # Create a simple placeholder for the avatar
        TEAM_AVATAR_WIDGET = render.Column(
            children = [
                render.Box(
                    width = IMG_MAX_WIDTH,
                    height = IMG_MAX_HEIGHT,
                    color = "#333333",
                    child = render.Text("FRC"),
                ),
            ],
        )

    # Team number widget
    TEAM_NUMBER_WIDGET = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Text("FRC %d" % team_number),
        ],
    )

    # Team name scrolling marquee
    TEAM_NAME_MARQUEE = render.Marquee(
        scroll_direction = "horizontal",
        align = "center",
        offset_start = MARQUEE_OFFSET_START,
        offset_end = MARQUEE_OFFSET_START,
        width = MARQUEE_WIDTH,
        child = render.Text(team_name),
    )

    # Team ranking display
    TEAM_RANKING_WIDGET = render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(team_ranking_msg),
        ],
    )

    DIVIDER_LINE_WIDGET = render.Box(width = 64, height = WIDGET_HEIGHT, color = WIDGET_COLOR)

    # Always render the main UI
    return render.Root(
        show_full_animation = True,
        child = render.Box(
            render.Column(
                children = [
                    render.Row(
                        main_align = "space_evenly",
                        expanded = True,
                        children = [
                            TEAM_AVATAR_WIDGET,
                            render.Column(
                                cross_align = "center",
                                children = [
                                    TEAM_NUMBER_WIDGET,
                                    TEAM_NAME_MARQUEE,
                                ],
                            ),
                        ],
                    ),
                    DIVIDER_LINE_WIDGET,
                    TEAM_RANKING_WIDGET,
                ],
            ),
        ),
    )

def get_schema():
    """Defines the configuration schema for the app.

    Returns:
        A schema object defining the configurable parameters for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team_number",
                name = "FRC Team Number",
                desc = "The FRC Team whose stats you want to display. List of team numbers can be found here: https://www.thebluealliance.com/teams",
                icon = "hashtag",
            ),
            schema.Text(
                id = "tba_api_key",
                name = "TheBlueAlliance API Key",
                desc = "READ Api key to access TheBlueAlliance API. Can be generated from your TBA account settings: https://www.thebluealliance.com/account",
                icon = "key",
                secret = True,
            ),
        ],
    )

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 2048 and "\r" not in value and "\n" not in value

def message(text):
    return render.Root(child = render.WrappedText(text, color = "#ffcc66"))

## ==================== END MAIN FUNCTION ====================
