"""
Applet: Ski Report
Summary: Weather and Trails
Description: Weather and Trail status for Mountains that are part of the Epic Pass resort system.
Author: Colin Morrisseau
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/black_diamond.png", BLACK_DIAMOND_ASSET = "file")
load("images/blue_square.png", BLUE_SQUARE_ASSET = "file")
load("images/green_circle.png", GREEN_CIRCLE_ASSET = "file")
load("images/mountain_icon.png", MOUNTAIN_ICON_ASSET = "file")
load("images/spacer.png", SPACER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BLACK_DIAMOND = BLACK_DIAMOND_ASSET.readall()
BLUE_SQUARE = BLUE_SQUARE_ASSET.readall()
GREEN_CIRCLE = GREEN_CIRCLE_ASSET.readall()
MOUNTAIN_ICON = MOUNTAIN_ICON_ASSET.readall()
SPACER = SPACER_ASSET.readall()

#Icons

#These are used for scraping the data from each site. most epic resort websites follow a similar structure. This doesn't work for the austrailian resorts
TERRAIN_URL_STUB = "the-mountain/mountain-conditions/terrain-and-lift-status.aspx"
TERRAIN_URL_STUB_ALT = "the-mountain/mountain-conditions/lift-and-terrain-status.aspx"
WEATHER_URL_STUB = "the-mountain/mountain-conditions/snow-and-weather-report.aspx"
WEATHER_URL_STUB_ALT = "the-mountain/mountain-conditions/weather-report.aspx"
TERRAIN_URL_STUBS = {"Crested Butte": TERRAIN_URL_STUB_ALT}
WEATHER_URL_STUBS = {"Crested Butte": WEATHER_URL_STUB_ALT}

RESORT_URLS = {
    "Vail": "https://www.vail.com/",
    "Beaver Creek": "https://www.beavercreek.com/",
    "Breckenridge": "https://www.breckenridge.com/",
    "Park City": "https://www.parkcitymountain.com/",
    "Keystone": "https://www.keystoneresort.com/",
    "Crested Butte": "https://www.skicb.com/",
    "Heavenly": "https://www.skiheavenly.com/",
    "Northstar": "https://www.northstarcalifornia.com/",
    "Kirkwood": "https://www.kirkwood.com/",
    "Stevens Pass": "https://www.stevenspass.com/",
    "Stowe": "https://www.stowe.com/",
    "Okemo": "https://www.okemo.com/",
    "Mount Snow": "https://www.mountsnow.com/",
    "Hunter": "https://www.huntermtn.com/",
    "Attitash": "https://www.attitash.com/",
    "Wildcat": "https://www.skiwildcat.com/",
    "Mount Sunapee": "https://www.mountsunapee.com/",
    "Crotched": "https://www.crotchedmtn.com/",
    "Liberty": "https://www.libertymountainresort.com/",
    "Roundtop": "https://www.skiroundtop.com/",
    "Whitetail": "https://www.skiwhitetail.com/",
    "Jack Frost and Big Boulder": "https://www.jfbb.com/",
    "Seven Springs": "https://www.7springs.com/",
    "Hidden Valley(PA)": "https://www.hiddenvalleyresort.com/",
    "Laurel Mountain": "https://www.laurelmountainski.com/",
    "Wilmot": "https://www.wilmotmountain.com/",
    "Afton Alps": "https://www.aftonalps.com/",
    "Mt Brighton": "https://www.mtbrighton.com/",
    "Alpine Valley": "https://alpinevalleyohio.com/",
    "Boston Mills and Brandywine": "https://www.bmbw.com/",
    "Mad River Mountain": "https://www.skimadriver.com/",
    "Hidden Valley(MO)": "https://www.hiddenvalleyski.com/",
    "Snow Creek": "https://www.skisnowcreek.com/",
    "Paoli Peaks": "https://www.paolipeaks.com/",
    "Whistler Blackcomb": "https://www.whistlerblackcomb.com/",
}

def get_schema():
    options = [schema.Option(display = resort, value = resort) for resort in RESORT_URLS.keys()]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "resort",
                name = "Ski Resort",
                icon = "mountain",
                desc = "The resort you want to show. North American Epic Pass Resorts only right now",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def trimToJSON(js_command):
    parts = js_command.split("= ", 1)
    if len(parts) != 2:
        return ""
    value = parts[1]
    return value[:-2] if value.endswith(";\r") else (value[:-1] if value.endswith(";") else "")

def fetch_page(url):
    response = http.get(url, ttl_seconds = 1800)
    body = response.body()
    return body if response.status_code == 200 and body and len(body) <= 1024 * 1024 else ""

def Getweather_data(resort):
    """Pulls weather info from the weather page associated with the given resort

    Args:
        resort (string): The Resort Name as listed in RESORT_URLS

    Returns:
        dict: a dict containing the temperature, snowfall and description attributes. description is not currently used. Returns None if their is an error fetching the results.
    """

    weather_stub = WEATHER_URL_STUBS.get(resort, WEATHER_URL_STUB)
    url = RESORT_URLS[resort] + weather_stub
    response = fetch_page(url)
    temperature = None
    snowfall = None
    weather_description = None
    for line in response.splitlines():
        if line.startswith("    FR.forecasts = "):
            temp_data = json.decode(trimToJSON(line), [])
            if type(temp_data) == "list" and temp_data and type(temp_data[0]) == "dict" and type(temp_data[0].get("CurrentTempStandard")) in ["int", "float"]:
                value = temp_data[0]["CurrentTempStandard"]
                temperature = str(value) if type(value) == "int" else humanize.ftoa(value)
        if line.startswith("    FR.snowReportData = "):
            snow = json.decode(trimToJSON(line), {})
            snow24 = snow.get("TwentyFourHourSnowfall", {}) if type(snow) == "dict" else {}
            if type(snow24) == "dict" and type(snow24.get("Inches")) in ["string", "int", "float"]:
                snowfall = str(snow24.get("Inches"))[:20]
    if temperature == None and weather_stub != WEATHER_URL_STUB_ALT:
        url = RESORT_URLS[resort] + WEATHER_URL_STUB_ALT
        response = fetch_page(url)
        for line in response.splitlines():
            if line.startswith("    FR.forecasts = "):
                temp_data = json.decode(trimToJSON(line), [])
                if type(temp_data) == "list" and temp_data and type(temp_data[0]) == "dict" and type(temp_data[0].get("CurrentTempStandard")) in ["int", "float"]:
                    value = temp_data[0]["CurrentTempStandard"]
                    temperature = str(value) if type(value) == "int" else humanize.ftoa(value)
            if line.startswith("    FR.snowReportData = "):
                snow = json.decode(trimToJSON(line), {})
                snow24 = snow.get("TwentyFourHourSnowfall", {}) if type(snow) == "dict" else {}
                if type(snow24) == "dict" and type(snow24.get("Inches")) in ["string", "int", "float"]:
                    snowfall = str(snow24.get("Inches"))[:20]
    if temperature == None or snowfall == None:
        return None

    results = dict(temperature = temperature, snowfall = snowfall, description = weather_description)
    return results

def getTerrain(resort):
    """Gets the Trail status from a particular resort by scraping the website associated with the resort

    Args:
        resort (string): The Resort Name as listed in RESORT_URLS

    Returns:
        _type_: _description_
    """
    terrain_stub = TERRAIN_URL_STUBS.get(resort, TERRAIN_URL_STUB)
    url = RESORT_URLS[resort] + terrain_stub

    # Pull an HTML response of the lift status page
    response = fetch_page(url)

    # filter out to just the JSON Object. It's a little wierd so it requires some string manipulation
    terrain_status_js_command = None
    for line in response.splitlines():
        if line.startswith("    FR.TerrainStatusFeed = "):
            terrain_status_js_command = line
            break
    if terrain_status_js_command == None and terrain_stub != TERRAIN_URL_STUB_ALT:
        url = RESORT_URLS[resort] + TERRAIN_URL_STUB_ALT
        response = fetch_page(url)
        for line in response.splitlines():
            if line.startswith("    FR.TerrainStatusFeed = "):
                terrain_status_js_command = line
                break
    if terrain_status_js_command == None:
        return None
    terrain_status_js = trimToJSON(terrain_status_js_command)

    # Turn it into JSON
    terrain_report = json.decode(terrain_status_js, {})
    if type(terrain_report) != "dict" or type(terrain_report.get("GroomingAreas")) != "list":
        return None

    # Filter it out just the trails
    trails = []
    for area in terrain_report["GroomingAreas"][:100]:
        area_trails = area.get("Trails", []) if type(area) == "dict" else []
        if type(area_trails) == "list":
            trails.extend([trail for trail in area_trails[:1000] if type(trail) == "dict"])

    # generate a trail summary

    # 1 - Green; 2 - Blue; 3 - Black; 4 - Double Black; 5 - Terrain Park
    summary = {}

    for trail in trails:
        difficulty = trail.get("Difficulty")
        if type(difficulty) not in ["int", "float"]:
            continue
        difficulty_key = repr(int(difficulty))
        if difficulty_key not in summary.keys():
            summary[difficulty_key] = dict(open = 0, total = 1)
        else:
            summary[difficulty_key]["total"] += 1

        if trail.get("IsOpen") == True:
            summary[difficulty_key]["open"] += 1
    for x in ["1", "2", "3"]:
        if x not in summary.keys():
            summary[x] = dict(open = 0, total = 0)

    summary.pop(5, None)
    if "4" in summary.keys():
        summary["3"]["open"] += summary["4"]["open"]
        summary["3"]["total"] += summary["4"]["total"]
    summary.pop("4", None)

    #this turns everything into to strings because the json encoder is picky and needed for caching
    for x in summary.keys():
        for y in summary[x].keys():
            summary[x][y] = repr(summary[x][y])
    return summary

def titleRow(resort):
    return render.Row(
        children = [
            render.Image(src = MOUNTAIN_ICON),
            render.Marquee(render.Text(resort, font = "6x13", color = "#85c1e9"), width = 48, align = "center"),
        ],
    )

def trailStatus(image, open, total):
    """Converts the raw info for a difficulty's trail status into a Render object stating the info

    Args:
        image (string): the base_64 constaint associated with difficulty
        open (int): how many trails are open
        total (int): how many total trails there are

    Returns:
        render: a row of one difficulties trail info
    """
    if int(open) == 0:
        color = "#BB1111"  #Red
    elif int(total) == 0 or int(open) * 2 < int(total):
        color = "#DFEF21"  #Yellow
    else:
        color = "#0FA700"  #Green
    return render.Row(
        children = [
            render.Image(src = image),
            render.Image(src = SPACER),
            render.Text(open, font = "CG-pixel-3x5-mono", color = color),
            render.Text("/", font = "CG-pixel-3x5-mono", color = color),
            render.Text(total, font = "CG-pixel-3x5-mono", color = color),
        ],
    )

def trailStatusColumn(resort):
    summary = getTerrain(resort)
    if summary == None:
        return render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Text("Trail", font = "CG-pixel-3x5-mono"),
                render.Text("Error", font = "CG-pixel-3x5-mono"),
            ],
        )
    return render.Column(
        expanded = True,
        main_align = "space_around",
        children = [
            trailStatus(GREEN_CIRCLE, summary["1"]["open"], summary["1"]["total"]),
            trailStatus(BLUE_SQUARE, summary["2"]["open"], summary["2"]["total"]),
            trailStatus(BLACK_DIAMOND, summary["3"]["open"], summary["3"]["total"]),
        ],
    )

def lowerRow(resort):
    return render.Row(
        expanded = True,
        main_align = "space_around",
        children = [
            weather(resort),
            trailStatusColumn(resort),
        ],
    )

def weather(resort):
    weather_data = Getweather_data(resort)
    if weather_data == None:
        return render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Text("Weather", font = "CG-pixel-3x5-mono"),
                render.Text("Error", font = "CG-pixel-3x5-mono"),
            ],
        )

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Text(weather_data["temperature"] + "°"),
            render.Text("24h:" + weather_data["snowfall"] + "\"", font = "tom-thumb"),
        ],
    )

def main(config):
    resort = config.str("resort", "Vail")
    if resort not in RESORT_URLS:
        resort = "Vail"
    return render.Root(
        child = render.Column(
            children = [
                titleRow(resort),
                lowerRow(resort),
            ],
        ),
    )
