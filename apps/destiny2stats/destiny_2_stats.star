"""
Applet: Destiny 2 Stats
Summary: Display Destiny stats
Description: Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 character.
Author: brandontod97
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/error.png", ERROR_IMAGE = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

API_BASE_URL = "https://www.bungie.net/platform"
API_USER_PROFILE = API_BASE_URL + "/User/GetBungieNetUserById/"
API_SEARCH_BUNGIE_ID = API_BASE_URL + "/User/Search/GlobalName/0/"
API_SEARCH_BUNGIE_ID_NAME = API_BASE_URL + "/Destiny2/SearchDestinyPlayerByBungieName/-1/"
MAX_RESPONSE_BYTES = 512 * 1024

def message(title, detail):
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [render.Text(title, color = "#fff"), render.Text(detail, color = "#888")],
        ),
    )

def response_json(response):
    body = response.body()
    return json.decode(body, None) if len(body) <= MAX_RESPONSE_BYTES else None

def safe_text(value, maximum):
    return value.strip() if type(value) == "string" and value.strip() and len(value) <= maximum else None

def safe_api_key(value):
    return value if type(value) == "string" and len(value) >= 1 and len(value) <= 512 and "\r" not in value and "\n" not in value else None

def main(config):
    display_name = safe_text(config.get("display_name"), 64)
    display_name_code = safe_text(config.get("display_name_code"), 8)
    show_id = config.bool("show_id", False)
    api_key = safe_api_key(config.get("api_key"))
    if not api_key or not display_name or not display_name_code:
        return message("Destiny 2", "Setup required")
    if not re.match(r"^[0-9]{1,8}$", display_name_code):
        return message("Destiny 2", "Invalid ID")

    apiResponse = http.post(
        API_SEARCH_BUNGIE_ID_NAME,
        headers = {"X-API-Key": api_key},
        json_body = {"displayName": display_name, "displayNameCode": int(display_name_code)},
    )
    search_payload = response_json(apiResponse)
    matches = search_payload.get("Response", []) if type(search_payload) == "dict" else []
    match = matches[0] if type(matches) == "list" and matches and type(matches[0]) == "dict" else {}
    membership_id = match.get("membershipId")
    membership_type = match.get("membershipType")
    if type(membership_id) != "string" or not re.match(r"^[0-9]{1,32}$", membership_id) or type(membership_type) != "int" or membership_type < 0 or membership_type > 255:
        return message("Invalid API", "or Bungie ID")

    profile_response = http.get(
        API_BASE_URL + "/Destiny2/" + str(membership_type) + "/Profile/" + membership_id + "/",
        params = {"components": "Characters"},
        headers = {"X-API-Key": api_key},
    )
    profile_payload = response_json(profile_response) if profile_response.status_code == 200 else None
    profile = profile_payload.get("Response", {}) if type(profile_payload) == "dict" else {}
    characters = profile.get("characters", {}) if type(profile) == "dict" else {}
    character_data = characters.get("data", {}) if type(characters) == "dict" else {}
    displayed_character = get_last_played_character(character_data)
    if not displayed_character:
        return message("Destiny 2", "No character")

    image = get_image(displayed_character["emblemPath"])

    #TODO: Clean this up and send dictionary of values instead of all the needed values separately
    return get_view(show_id, image, displayed_character, display_name, display_name_code)

def get_last_played_character(characters_list):
    if type(characters_list) != "dict" or len(characters_list) > 16:
        return None
    most_recent = None
    most_recent_date = ""
    for character in characters_list.values():
        if type(character) != "dict":
            continue
        played = character.get("dateLastPlayed")
        emblem = character.get("emblemPath")
        race = character.get("raceType")
        character_class = character.get("classType")
        light = character.get("light")
        if type(played) != "string" or len(played) > 40 or type(emblem) != "string" or len(emblem) > 256:
            continue
        if not emblem.startswith("/common/destiny2_content/icons/") or not re.match(r"^/[A-Za-z0-9_./-]+$", emblem):
            continue
        if type(race) != "int" or type(character_class) != "int" or type(light) not in ["int", "float"] or light < 0 or light > 10000:
            continue
        if played > most_recent_date:
            most_recent = {"dateLastPlayed": played, "emblemPath": emblem, "raceType": race, "classType": character_class, "light": light}
            most_recent_date = played
    return most_recent

def get_image(path):
    response = http.get("https://www.bungie.net" + path)
    body = response.body()
    content_type = response.headers.get("Content-Type", "")
    if response.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES and content_type.startswith("image/"):
        return body
    return ERROR_IMAGE.readall()

def get_character_class(class_value):
    class_value = int(class_value)

    if (class_value == 0):
        return "Titan"

    elif (class_value == 1):
        return "Huntr"

    elif (class_value == 2):
        return "Wrlck"

    else:
        return "Unknown"

def get_character_race(race_value):
    race_value = int(race_value)

    if (race_value == 0):
        return "Human"

    elif (race_value == 1):
        return "Awokn"

    elif (race_value == 2):
        return "Exo"

    else:
        return "Unkn"

def get_view(show_id, image, displayed_character, display_name, display_name_code):
    no_username_view = render.Root(
        child = render.Row(
            cross_align = "center",
            children = [
                render.Image(src = image, width = 32, height = 32),
                render.Box(width = 1, height = 32, color = "#FFFFFF"),
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "right",
                    children = [
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_race(displayed_character["raceType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_class(displayed_character["classType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(str(int(displayed_character["light"]))),
                        ),
                    ],
                ),
            ],
        ),
    )

    username_view = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = image, width = 24, height = 24),
                        render.Box(width = 1, height = 22, color = "#FFFFFF"),
                        render.Column(
                            expanded = False,
                            main_align = "space_around",
                            cross_align = "right",
                            children = [
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_race(displayed_character["raceType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_class(displayed_character["classType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(str(int(displayed_character["light"]))),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(width = 64, height = 1, color = "#FFFFFF"),
                render.Box(width = 64, height = 1),
                render.Marquee(
                    width = 64,
                    child = render.Row(
                        children = [
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                content = display_name,
                            ),
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                color = "#808080",
                                content = "#" + display_name_code,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

    if show_id:
        return username_view
    else:
        return no_username_view

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your Bungie API key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Your display name for your bungie account. This consists of your username before the # in your Bungie ID.",
                icon = "user",
            ),
            schema.Text(
                id = "display_name_code",
                name = "Display Code",
                desc = "Your display code for your bungie account. This consists of the numbers after the # in your Bungie ID.",
                icon = "code",
            ),
            schema.Toggle(
                id = "show_id",
                name = "Show ID",
                desc = "Show your Bungie ID.",
                icon = "idCard",
                default = False,
            ),
        ],
    )
