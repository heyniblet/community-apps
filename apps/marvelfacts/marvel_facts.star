"""
Applet: Marvel Facts
Summary: Character Info
Description: Gives you the description or number of comics a random character has been in.
Author: Kaitlyn Musial

Last updated: 7/10/2023
Last update: Fixed API call error due to incorrect BASE_URL
"""

load("hash.star", "hash")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://gateway.marvel.com/v1/public/characters"
LIMIT = "50"

def main(config):
    """Main Function

    Returns:
        Root: Character info and display
    """
    char_name, char_desc, char_comics, char_series = getNew(config)

    if char_desc == "":
        next_text = "Comics: " + str(char_comics) + "\nSeries: " + str(char_series)
    else:
        next_text = char_desc

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    color = "#a31212",
                    child = render.Box(
                        width = 62,
                        height = 30,
                        color = "#000000",
                    ),
                ),
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [render.Marquee(
                                width = 62,
                                height = 8,
                                align = "center",
                                child = render.Text(str(char_name), font = "Dina_r400-6"),
                                scroll_direction = "horizontal",
                            )],
                        ),
                        render.Row(
                            main_align = "space_evenly",
                            cross_align = "center",
                            expanded = True,
                            children = [
                                render.Marquee(
                                    width = 60,
                                    height = 22,
                                    align = "center",
                                    child = render.WrappedText(content = str(next_text), width = 64, font = "tb-8", align = "center"),
                                    scroll_direction = "vertical",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def getNew(config):
    """Gets a new character from the API

    Returns:
        list: Character details
    """
    now = str(time.now()).split(" ")[1]

    public_key = config.get("marvel_public_key")
    private_key = config.get("marvel_private_key")

    if type(private_key) == "string" and type(public_key) == "string" and private_key and public_key and len(private_key) <= 512 and len(public_key) <= 512:
        digest = str(now) + private_key + public_key
        FULL_KEY = hash.md5(digest)

        MAX_OFFSET = 1562 - int(LIMIT) - 1
        OFFSET = random.number(0, MAX_OFFSET)

        response = http.get(BASE_URL, params = {
            "apikey": public_key,
            "hash": FULL_KEY,
            "limit": LIMIT,
            "offset": str(OFFSET),
            "ts": str(now),
        })
        if response.status_code != 200:
            return ["Marvel API", "Request failed (" + str(response.status_code) + ")", 0, 0]

        full_json = response.json()
        data = full_json.get("data") if type(full_json) == "dict" else None
        results = data.get("results") if type(data) == "dict" else None
        if type(results) != "list" or not results:
            return ["Marvel API", "No characters returned", 0, 0]

        character = results[random.number(0, len(results) - 1)]
        if type(character) != "dict":
            return ["Marvel API", "Invalid character data", 0, 0]
        comics = character.get("comics") if type(character.get("comics")) == "dict" else {}
        series = character.get("series") if type(character.get("series")) == "dict" else {}
        return [
            str(character.get("name") or "Unknown")[:80],
            str(character.get("description") or "")[:500],
            comics.get("available", 0),
            series.get("available", 0),
        ]
    else:
        return ["Character Name", "Character Info", None, None]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "marvel_public_key",
                name = "Marvel Public Key",
                desc = "Your Marvel Comics API Public Key. See https://developer.marvel.com/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "marvel_private_key",
                name = "Marvel Private Key",
                desc = "Your Marvel Comics API Private Key. See https://developer.marvel.com/ for details.",
                icon = "key",
                secret = True,
            ),
        ],
    )
