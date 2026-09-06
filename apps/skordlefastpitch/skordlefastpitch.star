"""
Applet: SkordleFastPitch
Summary: Displays FP Games
Description: The app gets fast pitch data from the Skordle website to display on the Tidbyt. A user can select the class of game and manually select which game to display.
Author: Woolycoin437420
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Constants
DEFAULT_CLASS = "6A"
DEFAULT_GAME = "1"

#The following dictionary is used by the settings and some values in the main function.
#The ID numbers are used in the URL in the main function.

CLASSES = {"6A": 240, "5A": 241, "4A": 242, "3A": 243, "2A": 244, "A": 245, "B": 246, "Other": 453}

#This is the main function that runs after the settings. Returns display
def main(config):
    sportClass = config.str("class", DEFAULT_CLASS)
    classID = CLASSES[sportClass]
    current_game = config.get("games", DEFAULT_GAME)
    all_games = get_data(classID)
    total_games = len(all_games)

    #Type conversion from string to int
    current_game = int(current_game)

    if total_games > 0 and current_game > total_games:
        current_game = total_games

    data = all_games.get(current_game)

    first_icon_url = ""
    second_icon_url = ""
    first_team = ""
    second_team = ""
    first_score = ""
    second_score = ""
    progress = ""
    datetime = ""

    if total_games > 0:
        is_date = False

        #The following conditions are used to properly unpack the sorted game.
        #Please note that the score variables sometimes double as the date/time variables
        if len(data) == 7:
            first_icon_url, first_team, first_score, second_icon_url, second_team, second_score, progress = data
        elif len(data) == 6:
            first_icon_url, first_team, first_score, second_icon_url, second_team, second_score = data
            progress = "Final"
        elif len(data) == 5:
            first_icon_url, first_team, datetime, second_icon_url, second_team = data
            datetime = datetime.split(" @ ")
            first_score, second_score = datetime
            progress = "Scheduled"
            is_date = True
        elif len(data) == 4:
            first_icon_url, first_team, second_icon_url, second_team = data
            first_score, second_score = "N/A", "N/A"
            progress = "Coming Soon"

        if is_date:
            scores = "Date: " + first_score + " Time: " + second_score
        else:
            scores = "Scores: " + first_score + "/" + second_score

        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.Text(
                            content = "Game {} of {}".format(current_game, total_games),
                            font = "CG-pixel-3x5-mono",
                        ),
                        width = 64,
                        height = 7,
                        padding = 1,
                        color = "#0000ff",
                    ),
                    render.Marquee(
                        child = render.Column(
                            children = [
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url, ttl_seconds = 3600).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                            ],
                        ),
                        scroll_direction = "vertical",
                        height = 15,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Row(
                                children = [
                                    render.Text(
                                        content = "Status: " + progress + " | " + scores,
                                        font = "CG-pixel-3x5-mono",
                                    ),
                                ],
                                cross_align = "center",
                            ),
                            scroll_direction = "horizontal",
                            width = 64,
                            offset_start = 64,
                            offset_end = 64,
                            delay = 10,
                        ),
                        width = 64,
                        height = 11,
                        padding = 1,
                        color = "#a64800",
                    ),
                ],
                expanded = True,
            ),
        )

    else:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No Events for {} Fast Pitch".format(sportClass),
                    width = 60,
                    linespacing = 1,
                    font = "CG-pixel-3x5-mono",
                ),
                width = 64,
                height = 32,
                padding = 1,
            ),
        )

#This function gets and stores the data for the desired sport class.
def get_data(classID):
    web = http.get("https://skordle.com/scores/?sportid=11&classid={}&clubid=1".format(classID), ttl_seconds = 60)
    if web.status_code != 200:
        fail("Failure code: %s", web.status_code)

    #The sort function breaks up the HTML data and returns a dictionary.
    #This dictionary contains lists of data for each game.
    return sort(web.body())

#Returns the visible text from a table cell without depending on HTML offsets.
def html_text(element):
    text = ""
    in_tag = False
    value = "<td" + element
    for index in range(len(value)):
        char = value[index]
        if char == "<":
            if not in_tag and len(text) > 0 and text[-1] != " ":
                text += " "
            in_tag = True
        elif char == ">":
            in_tag = False
        elif not in_tag:
            text += char
    return text.strip().replace("  ", " ")

#Sorts through HTML data and returns numbered games with their data.
def sort(body):
    sorted = {}
    tables = []
    counter = 0
    has_games = False

    sections = body.split("<table")

    if len(sections) != 1:
        has_games = True

    if has_games:
        for section in sections:
            if "</table>" in section:
                tables.append(section)

        #The last item in tables contains the last table and the rest of the document.
        #To fix this, the program breaks the string at the end of the table.
        #It then replaces the final item with only the table.

        last_table = tables[-1].split("</table>")
        tables[-1] = last_table[0]

        for table in tables:
            counter += 1
            sorted[counter] = []
            elements = table.split("<td")

            #Each cell has a stable class even when attribute lengths change.
            for element in elements:
                if "teamcell" in element:
                    team = html_text(element)
                    if len(team) > 0 and team[0] == "@":
                        team = team[1:]
                    if len(team) > 0:
                        sorted[counter].append(team)

                if "scorecell" in element:
                    sorted[counter].append(html_text(element))

                if "logocell" in element:
                    if "src='" in element:
                        sorted[counter].append(element.split("src='")[1].split("'")[0])
                    elif "src=\"" in element:
                        sorted[counter].append(element.split("src=\"")[1].split("\"")[0])

                if "datetimecell" in element:
                    sorted[counter].append(html_text(element))

                if "progresscell" in element:
                    sorted[counter].append(html_text(element))

    return sorted

#Mobile settings function that returns the desired sport and class
def get_schema():
    class_options = [schema.Option(display = c, value = c) for c in CLASSES]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "class",
                name = "Classes",
                desc = "The class of sport whose games will be displayed",
                icon = "arrowUpShortWide",
                default = DEFAULT_CLASS,
                options = class_options,
            ),
            schema.Dropdown(
                id = "games",
                name = "Games",
                desc = "The game number to display (values above today's count use the last game)",
                icon = "baseballBatBall",
                default = DEFAULT_GAME,
                options = [schema.Option(display = "{}".format(game), value = "{}".format(game)) for game in range(1, 51)],
            ),
        ],
    )
