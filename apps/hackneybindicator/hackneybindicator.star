"""
Applet: HackneyBindicator
Summary: Upcoming refuse collections
Description: Tells you what bins to put out for people who live in the London Borough of Hackney.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://hackney-bindicator.fly.dev"
COLLECTION_PATH = "/property/"

DATE = "date"
BINS = "Bins"
BORDER = "border"
FILL = "fill"
TYPE = "Type"
DISPLAY = "display"
NAME = "Name"

# https://design-system.hackney.gov.uk/developing/colours/
HACKNEY_GREEN = "#00664f"
WHITE = "#ffffff"
ERROR_RED = "#be3a34"
BLUE = "#0085ca"
BLACK = "#0b0c0c"
BORDER_GREY = "#bfc1c3"
LIGHT_GREEN = "#00b341"
BEIGE = "#f8e08e"
MAX_WIDTH = 16

MAX_RESPONSE_BYTES = 1024 * 1024

BIN_TYPES = {
    "food": {
        BORDER: BLUE,
        FILL: BLUE,
        DISPLAY: ["Food", "Food", "Food", "Fod"],
    },
    "recycling": {
        BORDER: LIGHT_GREEN,
        FILL: LIGHT_GREEN,
        DISPLAY: ["Recycling", "Recycle", "Recy", "Rec"],
    },
    "garden": {
        BORDER: BEIGE,
        FILL: BEIGE,
        DISPLAY: ["Garden", "Garden", "Gard", "Gdn"],
    },
    "rubbish": {
        BORDER: BORDER_GREY,
        FILL: BLACK,
        DISPLAY: ["Trash", "Trash", "Trsh", "Tsh"],
    },
    "unknown": {
        BORDER: BORDER_GREY,
        FILL: BORDER_GREY,
        DISPLAY: ["?", "?", "?", "?"],
    },
}

def get_next_collection(property_id):
    resp = http.get(BASE_URL + COLLECTION_PATH + property_id)
    body = resp.body()
    if resp.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return None

    data = json.decode(body, {})
    bins = data.get(BINS, []) if type(data) == "dict" else []
    if type(bins) != "list":
        return None
    collections = {}
    for bin in bins[:20]:
        if type(bin) != "dict":
            continue
        next_collection = bin.get("NextCollection")
        if not valid_timestamp(next_collection):
            continue
        date = time.parse_time(next_collection)
        if date not in collections:
            collections[date] = []
        bin_type = bin.get(TYPE, "unknown")
        if bin_type not in BIN_TYPES:
            bin_type = "unknown"

        # The council have changed their garden waste collection service to an opt-in
        # paid service. It looks like they have also changed the API response. My garden
        # waste bin now shows up as "unknown" type, so insert a manual override.
        if bin_type == "unknown" and bin.get(NAME) == "GW_Wheeled Bin 140l":
            bin_type = "garden"
        collections[date].append(bin_type)
    if not collections:
        return None
    first_date = sorted(collections.keys())[0]
    collected = sorted(list(set(collections[first_date])))

    return {
        DATE: first_date,
        BINS: collected,
    }

def render_error(error):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = HACKNEY_GREEN,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 62,
                                align = "center",
                                child = render.Text(
                                    content = "Hackney bins",
                                    color = WHITE,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(height = 1, width = 1),  # Spacing between box and text
                render.WrappedText(
                    width = 64,
                    height = 23,
                    align = "center",
                    content = error,
                    color = ERROR_RED,
                ),
            ],
        ),
    )

def render_bin(bin, width, count):
    bin_type = BIN_TYPES[bin]
    box_size = min(MAX_WIDTH, width)
    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        expanded = True,
        children = [
            render.Box(
                width = box_size,
                height = box_size,
                color = bin_type[BORDER],
                padding = 1,
                child = render.Box(
                    width = box_size - 2,
                    height = box_size - 2,
                    color = bin_type[FILL],
                ),
            ),
            render.WrappedText(
                bin_type[DISPLAY][count],
                width = width,
                align = "center",
                font = "tom-thumb",
            ),
        ],
    )

def render_bins(bins):
    width = 58 // len(bins)
    return render.Row(
        children = [render_bin(bin, width, len(bins) - 1) for bin in bins],
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
    )

def render_collection(date, bins):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = HACKNEY_GREEN,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 62,
                                align = "center",
                                child = render.Text(
                                    content = date.format("Mon 2 Jan"),
                                    color = WHITE,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(height = 1, width = 1),  # Spacing between box and text
                render_bins(bins),
            ],
        ),
    )

def main(config):
    property_id = config.get("address", "")
    if not valid_property_id(property_id):
        return render_error("Configure a Hackney property ID")
    collection = get_next_collection(property_id)
    if not collection:
        return render_error("Could not get collection")
    return render_collection(collection[DATE], collection[BINS])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "postcode",
                name = "Postcode",
                desc = "Reference postcode. Use the official Hackney collection lookup to choose your address.",
                icon = "map",
            ),
            schema.Text(
                id = "address",
                name = "Property ID",
                desc = "Property ID returned by https://hackney-bindicator.fly.dev/addresses/POSTCODE (encode the space as %20).",
                icon = "house",
            ),
        ],
    )

def valid_property_id(value):
    return type(value) == "string" and len(value) == 24 and all([char.lower() in "0123456789abcdef" for char in value.elems()])

def valid_timestamp(value):
    if type(value) != "string" or len(value) < 20 or len(value) > 35:
        return False
    prefix = value[:19]
    digits = prefix[:4] + prefix[5:7] + prefix[8:10] + prefix[11:13] + prefix[14:16] + prefix[17:19]
    return prefix[4] == "-" and prefix[7] == "-" and prefix[10] == "T" and prefix[13] == ":" and prefix[16] == ":" and digits.isdigit() and (value.endswith("Z") or "+" in value[19:] or "-" in value[19:])
