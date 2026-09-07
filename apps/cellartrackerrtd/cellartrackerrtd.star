"""
Applet: CellarTrackerRtd
Summary: Shows a ready to drink wine
Description: Displays a random wine from your CellarTracker Ready to Drink report.
Author: Matt Kent
"""

load("http.star", "http")
load("images/red_wine_glass_icon.png", RED_WINE_GLASS_ICON_ASSET = "file")
load("images/rose_wine_glass_icon.png", ROSE_WINE_GLASS_ICON_ASSET = "file")
load("images/sparkling_wine_glass_icon.png", SPARKLING_WINE_GLASS_ICON_ASSET = "file")
load("images/white_wine_glass_icon.png", WHITE_WINE_GLASS_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

RED_WINE_GLASS_ICON = RED_WINE_GLASS_ICON_ASSET.readall()
ROSE_WINE_GLASS_ICON = ROSE_WINE_GLASS_ICON_ASSET.readall()
SPARKLING_WINE_GLASS_ICON = SPARKLING_WINE_GLASS_ICON_ASSET.readall()
WHITE_WINE_GLASS_ICON = WHITE_WINE_GLASS_ICON_ASSET.readall()

MAX_RESPONSE_BYTES = 8 * 1024 * 1024
MAX_ROWS = 5000

DEFAULT_TOP_N_VALUE = 10

def inventory_xml_to_dict_list(raw_xml_string):
    result = []
    rows = xpath.loads(raw_xml_string).query_all_nodes("/cellartracker/inventory/row")[:MAX_ROWS]
    for row in rows:
        dict_row = {}
        dict_row["iWine"] = str(row.query("/iWine") or "")
        dict_row["BottleNote"] = str(row.query("/BottleNote") or "")
        result.append(dict_row)
    return result

def availability_xml_to_dict_list(raw_xml_string):
    result = []
    rows = xpath.loads(raw_xml_string).query_all_nodes("/cellartracker/availability/row")[:MAX_ROWS]
    for row in rows:
        dict_row = {}
        dict_row["iWine"] = str(row.query("/iWine") or "")
        dict_row["Type"] = str(row.query("/Type") or "")
        dict_row["Category"] = str(row.query("/Category") or "")
        dict_row["Vintage"] = str(row.query("/Vintage") or "")
        dict_row["Wine"] = str(row.query("/Wine") or "")
        dict_row["Producer"] = str(row.query("/Producer") or "")
        dict_row["Designation"] = str(row.query("/Designation") or "")
        dict_row["Varietal"] = str(row.query("/Varietal") or "")
        result.append(dict_row)
    return result

# Get inventory report which includes private notes
# that we can use for filtering out excluded bottles
def get_report_xml(username, password, table):
    resp = http.get(
        "https://www.cellartracker.com/xlquery.asp",
        params = {"User": username, "Password": password, "Format": "xml", "Table": table},
    )
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES or "<cellartracker" not in body[:512]:
        return None
    return body

def positive_int(value, default, maximum):
    value = str(value or "")
    if not value or len(value) > 4:
        return default
    for char in value.elems():
        if char not in "0123456789":
            return default
    return min(max(1, int(value)), maximum)

# Return a list of iWine ids for bottles to be excluded from the availability report
def select_excluded_wine_ids(inventory_list, exclusion_keyword_list):
    excluded_wine_ids = []
    for bottle in inventory_list:
        for keyword in exclusion_keyword_list:
            if keyword in bottle["BottleNote"]:
                excluded_wine_ids.append(bottle["iWine"])
    return excluded_wine_ids

def wine_display_text(bottle):
    display_text_components = [bottle["Vintage"], bottle["Wine"]]
    return " ".join(display_text_components)[:300]

# Use this command to generate base64 data of the image files
#
# python -c 'import base64; print(base64.b64encode(open("images/white-wine-glass.png", "rb").read()).decode("utf-8"))'
#
def get_wine_glass_icon(bottle):
    wine_type = bottle["Type"]
    if wine_type == "White":
        return WHITE_WINE_GLASS_ICON
    elif wine_type.endswith("Sparkling"):
        # CellarTracker has "Red - Sparkling", "White - Sparkling" etc but we only have one sparkling icon
        return SPARKLING_WINE_GLASS_ICON
    elif wine_type == "Rosé":
        return ROSE_WINE_GLASS_ICON
    else:
        return RED_WINE_GLASS_ICON

def select_displayable_bottles(availability_list, excluded_wine_ids):
    displayable_bottles = []
    for bottle in availability_list:
        bottle_id = bottle["iWine"]
        if bottle_id not in excluded_wine_ids:
            displayable_bottles.append(bottle)
    return displayable_bottles

def select_bottle_to_display(top_n_value, displayable_bottles):
    if not displayable_bottles:
        return None
    top_n_length = min(top_n_value, len(displayable_bottles))
    top_n_bottles = displayable_bottles[0:top_n_length]
    idx = random.number(0, len(top_n_bottles) - 1)
    return top_n_bottles[idx]

def render_widgets(wine_glass_icon, wine_display_name):
    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Box(
                    width = 14,
                    child = render.Image(
                        src = wine_glass_icon,
                    ),
                ),
                render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 30,
                    offset_end = 30,
                    align = "center",
                    child = render.WrappedText(
                        width = 50,
                        content = wine_display_name,
                        color = "#afafaf",
                    ),
                ),
            ],
        ),
    )

def main(config):
    username = config.get("cellartracker_username")
    password = config.get("cellartracker_password")
    exclusion_keywords_string = config.get("exclusion_keywords")
    top_n_value = positive_int(config.get("top_n_value"), DEFAULT_TOP_N_VALUE, 100)

    # These options are not exposed in the schema and are only
    # intended to be used in development
    bottle_id_override = config.get("bottle_id")

    exclusion_keyword_list = []
    if exclusion_keywords_string:
        exclusion_keyword_list = [keyword[:80] for keyword in exclusion_keywords_string.split(",")[:20] if keyword]

    if username and password and len(username) <= 256 and len(password) <= 256:
        print("CellarTracker credentials found, fetching data from server")

        raw_inventory_xml = get_report_xml(username, password, "Inventory")
        raw_availability_xml = get_report_xml(username, password, "Availability")
    else:
        print("No CellarTracker credentials found")

        return render_widgets(RED_WINE_GLASS_ICON, "2023 Your Favorite Red Wine")

    if not raw_inventory_xml or not raw_availability_xml:
        return render_widgets(RED_WINE_GLASS_ICON, "CellarTracker unavailable")

    inventory_list = inventory_xml_to_dict_list(raw_inventory_xml)
    availability_list = availability_xml_to_dict_list(raw_availability_xml)

    excluded_wine_ids = select_excluded_wine_ids(inventory_list, exclusion_keyword_list)
    displayable_bottles = select_displayable_bottles(availability_list, excluded_wine_ids)

    bottle = select_bottle_to_display(top_n_value, displayable_bottles)

    if bottle_id_override:
        matches = [b for b in availability_list if b["iWine"] == bottle_id_override]
        bottle = matches[0] if matches else bottle

    if not bottle:
        return render_widgets(RED_WINE_GLASS_ICON, "No matching wine found")

    wine_glass_icon = get_wine_glass_icon(bottle)
    wine_display_name = wine_display_text(bottle)

    return render_widgets(wine_glass_icon, wine_display_name)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "cellartracker_username",
                name = "CellarTracker username",
                desc = "CellarTracker username",
                icon = "user",
            ),
            schema.Text(
                id = "cellartracker_password",
                name = "CellarTracker password",
                desc = "CellarTracker password",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "exclusion_keywords",
                name = "Exclusion keywords",
                desc = "Comma-separated list of keywords. If any keyword is found in the BottleNote then the wine is excluded from display.",
                icon = "ban",
            ),
            schema.Text(
                id = "top_n_value",
                name = "Top N bottles",
                desc = "This app displays a random bottle from the top N bottles of the ready-to-drink report. Set N to a larger number if you want more variety in the results displayed or if you have a lot of bottles in your cellar that will be ready to drink soon.",
                icon = "wineBottle",
                default = "10",
            ),
        ],
    )
