"""
Applet: League Champs
Summary: Display league characters
Description: Shows league of legends champsions and their subtitle.
Author: xl0lli
"""

load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL = 604800
CSV_ENDPOINT = "https://gist.githubusercontent.com/xl0lli/bc6755ee77e52a9dcd481e75c95c74b6/raw/ac2c83cc874b2dbbe8f9449a8cef1df4ff8bedb4/league_champ_data"
ANITMATION_SPEED = 200

# Keep schema extraction deterministic and network-free. These are the exact
# existing toggle IDs; live titles and sprites still come from CSV_ENDPOINT.
CHAMPS = [
    "Aatrox",
    "Ahri",
    "Akali",
    "Alistar",
    "Amumu",
    "Anivia",
    "Annie",
    "Aphelios",
    "Ashe",
    "AurelionSol",
    "Azir",
    "Bard",
    "Blitzcrank",
    "Brand",
    "Braum",
    "Caitlyn",
    "Camille",
    "Cassiopeia",
    "Chogath",
    "Corki",
    "Darius",
    "Diana",
    "Draven",
    "DrMundo",
    "Ekko",
    "Elise",
    "Evelynn",
    "Ezreal",
    "Fiddlesticks",
    "Fiora",
    "Fizz",
    "Galio",
    "Gangplank",
    "Garen",
    "Gnar",
    "Gragas",
    "Graves",
    "Hecarim",
    "Heimerdinger",
    "Illaoi",
    "Irelia",
    "Ivern",
    "Janna",
    "JarvanIV",
    "Jax",
    "Jayce",
    "Jhin",
    "Jinx",
    "Kaisa",
    "Kalista",
    "Karma",
    "Karthus",
    "Kassadin",
    "Katarina",
    "Kayle",
    "Kayn",
    "Kennen",
    "Khazix",
    "Kindred",
    "Kled",
    "KogMaw",
    "Leblanc",
    "LeeSin",
    "Leona",
    "Lillia",
    "Lissandra",
    "Lucian",
    "Lulu",
    "Lux",
    "Malphite",
    "Malzahar",
    "Maokai",
    "MasterYi",
    "MissFortune",
    "MonkeyKing",
    "Mordekaiser",
    "Morgana",
    "Nami",
    "Nasus",
    "Nautilus",
    "Neeko",
    "Nidalee",
    "Nocturne",
    "Nunu",
    "Olaf",
    "Orianna",
    "Ornn",
    "Pantheon",
    "Poppy",
    "Pyke",
    "Qiyana",
    "Quinn",
    "Rakan",
    "Rammus",
    "RekSai",
    "Renekton",
    "Rengar",
    "Riven",
    "Rumble",
    "Ryze",
    "Samira",
    "Sejuani",
    "Senna",
    "Seraphine",
    "Sett",
    "Shaco",
    "Shen",
    "Shyvana",
    "Singed",
    "Sion",
    "Sivir",
    "Skarner",
    "Sona",
    "Soraka",
    "Swain",
    "Sylas",
    "Syndra",
    "TahmKench",
    "Taliyah",
    "Talon",
    "Taric",
    "Teemo",
    "Thresh",
    "Tristana",
    "Trundle",
    "Tryndamere",
    "TwistedFate",
    "Twitch",
    "Udyr",
    "Urgot",
    "Varus",
    "Vayne",
    "Veigar",
    "Velkoz",
    "Vi",
    "Viktor",
    "Vladimir",
    "Volibear",
    "Warwick",
    "Xayah",
    "Xerath",
    "XinZhao",
    "Yasuo",
    "Yone",
    "Yorick",
    "Yuumi",
    "Zac",
    "Zed",
    "Ziggs",
    "Zilean",
    "Zoe",
    "Zyra",
    "Milio",
    "KSante",
    "Nilah",
    "Belveth",
    "Renata",
    "Zeri",
    "Vex",
    "Akshan",
    "Gwen",
    "Viego",
    "Rell",
]

def main(config):
    random.seed(time.now().unix // 15)
    sprite_position = config.str("sprite_position", "random")

    #open csv file
    league_champs = filter_data(config, get_data())
    if len(league_champs) == 0:
        return render.Root(child = render.Text("No champions", font = "5x8"))

    #choose random line for number of champions
    index = random.number(0, len(league_champs) - 1)

    children = [
        render.Image(src = base64.decode(league_champs[index][1]), width = 24, height = 32),
        render.Marquee(
            height = 32,
            width = 40,
            align = "center",
            offset_start = 0,
            offset_end = 64,
            child = render.WrappedText(
                content = league_champs[index][2].upper(),
                align = "center",
                width = 40,
                font = "5x8",
                color = "#fd4",
            ),
            scroll_direction = "vertical",
        ),
    ]

    # If the user prefers the image on the right, or if the position is random, swap the order
    if sprite_position == "right" or (sprite_position == "random" and random.number(0, 1)):
        children = reversed(children)

    return render.Root(
        child = render.Box(
            #color = "#444",
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
        delay = ANITMATION_SPEED,
    )

def get_data():
    # If we don't have a cached version, fetch the data now
    request = http.get(CSV_ENDPOINT, ttl_seconds = CACHE_TTL)
    if request.status_code != 200:
        print("Unexpected status code: %d" % request.status_code)
        return []

    league_champs = request.body()

    # Return our quotes, except for the header line
    return csv.read_all(league_champs, skip = 1)

# SCHEMA
# ------
def get_schema():
    fields = [
        schema.Dropdown(
            id = "sprite_position",
            name = "Image Position",
            desc = "Where to display the image relative to the quote",
            icon = "rightLeft",
            default = "random",
            options = [
                schema.Option(
                    display = "Random",
                    value = "random",
                ),
                schema.Option(
                    display = "Left",
                    value = "left",
                ),
                schema.Option(
                    display = "Right",
                    value = "right",
                ),
            ],
        ),
    ]

    for champ in CHAMPS:
        fields.append(
            schema.Toggle(
                id = champ,
                name = champ,
                desc = "Show champion " + champ,
                icon = "gamepad",
                default = True,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

# FILTER_DATA
# -----------
def filter_data(config, data):
    result = []
    for index in range(0, len(data)):
        champ = data[index][0]

        if config.bool(champ, True):
            result.append(data[index])

    return result
