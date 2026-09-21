# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: My Last Coffee
Summary: Show when your last espresso shot was pulled. 
Description: Display details and meta infomation about the last espresso shot you recorded.
Author: jeffbean
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "US/Pacific"

DEBUG = False

def render_root(todays_shots, latest_shot, timezone):
    """ Renders the root for the app while we have data for it 

    Args:
      todays_shots: list containing the shots that are timestamped today.
      latest_shot: the latest shot data we found.
      timezone: the timezone location string to compare the day to.
    Returns:
        rendered root for the app
    """

    render_text = "{}".format(
        humanize.time(
            time.from_timestamp(latest_shot.get("clock", 1)).in_location(timezone),
        ),
    )

    todays_text = "{}".format(len(todays_shots))

    return render.Root(
        child = render.Stack(
            children = [
                # column at the top of the screen
                render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "space_between",
                                    cross_align = "end",
                                    children = [
                                        render.Text(todays_text, color = "#DEB887", font = "10x20"),
                                        render.Padding(
                                            child = render.Text("/ today", font = "CG-pixel-4x5-mono"),
                                            pad = 4,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),

                # column to hold the stuff in the bottom of the screen
                render.Column(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Padding(
                                    child = render.Text("last shot ...", color = "#DEB887", font = "tom-thumb"),
                                    pad = 1,
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(render_text, font = "tom-thumb"),
                                    align = "center",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_problem(msg):
    return render.Root(
        render.Marquee(
            width = 64,
            child = render.Text(msg),
            align = "center",
        ),
    )

def get_my_shots(auth_token):
    """ Fetchs the list of shots for the OAuth user.

    Args:
        auth_token: the auth token from oauth exchange.
    Returns:
        list of shots for the authenticated user.
    """
    url = "https://visualizer.coffee/api/shots/"
    resp = http.get(
        url,
        headers = {
            "Authorization": "Bearer " + auth_token,
        },
        ttl_seconds = 600,  # 10 mins.
    )
    if resp.status_code != 200 or len(resp.body()) > 512 * 1024:
        if DEBUG:
            print("request to %s failed with status code: %d" % (url, resp.status_code))
        return None

    return json.decode(resp.body())

def get_latest_shot(my_shots):
    """ Returns the latest shot by time.

    Args:
      my_shots: data returned from getting shots
    Returns:
        latest shot object
    """

    # im not sure we can assume its time sorted, simple
    # loop to find the latest shot from the list.
    latest_shot = {}
    for shot in my_shots["data"]:
        timestamp = time.from_timestamp(shot.get("clock", 1))
        if timestamp > time.from_timestamp(latest_shot.get("clock", 1)):
            latest_shot = shot

    return latest_shot

def get_todays_shots(my_shots, timezone):
    """ Returns a list of shots from today (starting at midnight).

    Args:
      my_shots: data returned from getting shots
      timezone: the timezone location string to compare the day to.
    Returns:
        list of todays shots
    """
    now = time.now().in_location(timezone)
    today_start_midnight = time.time(year = now.year, month = now.month, day = now.day, location = timezone)

    todays_shots = []

    # data from visulizer are UTC
    for shot in my_shots.get("data"):
        ts = time.from_timestamp(shot.get("clock", 1)).in_location(timezone)
        if ts > today_start_midnight:
            todays_shots.append(shot)

    return todays_shots

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "auth",
                name = "Visualizer access token",
                desc = "A Visualizer Coffee API access token with read access.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def main(config):
    """ The main function for the application

    todo:
    - config for colors?
    - thresholds where text color will change, like if < 1 by noon its red... lol

    Args:
      config: the passed in config object accessing fields set by the schema.
    Returns:
      a rendered root object
    """
    auth_token = config.get("auth", None)
    if auth_token == None:
        return render_problem("Add Visualizer access token")

    my_shots = get_my_shots(auth_token)
    if my_shots == None:
        return render_problem("could not get shots from vizulizer...")

    return render_root(get_todays_shots(my_shots, DEFAULT_TIMEZONE), get_latest_shot(my_shots), DEFAULT_TIMEZONE)
