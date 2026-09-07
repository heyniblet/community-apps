"""
Applet: RAA Fuel Watch
Summary: Shows petrol prices
Description: Enter your location and fuel type, then find the cheapest fuel in a 5km radius.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_PREFIX = "https://our.raa.com.au/assets/ajax/FuelPricesService.ashx?op=GetStationsByRadius&"
MAX_RESPONSE_BYTES = 512 * 1024
FUEL_TYPES = ["2", "3", "4", "5", "8", "12", "19"]

DEFAULT_LOCATION = """
{
    "lat": "-34.8789633",
    "lng": "138.5369358",
    "description": "Woodville, SA, Australia",
	"locality": "Woodville",
	"timezone": "Australia/Adelaide"
}
"""

def main(config):
    LocationDetails = json.decode(config.get("location", DEFAULT_LOCATION), None)
    FuelType = config.get("FuelType", "2")
    FuelType = FuelType if FuelType in FUEL_TYPES else "2"
    if type(LocationDetails) != "dict":
        return message("Invalid location")
    Lat = safe_coordinate(LocationDetails.get("lat"), -90, 90)
    Long = safe_coordinate(LocationDetails.get("lng"), -180, 180)
    if Lat == None or Long == None:
        return message("Invalid location")

    API_CALL = API_PREFIX + "Lon=" + str(Long) + "&" + "Lat=" + str(Lat) + "&Radius=5" + "&Brand=&FuelType=" + FuelType + "&Sort=true"

    # Update every 5 mins
    FuelData = get_cachable_data(API_CALL, 300)
    results = FuelData.get("Result", []) if type(FuelData) == "dict" else []
    station = results[0] if type(results) == "list" and len(results) > 0 and type(results[0]) == "dict" else None
    if station == None:
        return message("No fuel data")
    Outlet = station.get("name", "Unknown")
    Outlet = Outlet[:80] if type(Outlet) == "string" else "Unknown"
    Fuel = station.get("fuel", [])
    Price = None
    if type(Fuel) == "list":
        for fuel in Fuel:
            if type(fuel) == "dict" and str(fuel.get("type_id")) == FuelType and type(fuel.get("price")) in ["int", "float"]:
                Price = fuel["price"]
                break
    if Price == None:
        return message("No price found")

    mainFont = "CG-pixel-3x5-mono"
    priceFont = "Dina_r400-6"
    Price = str(Price) + "c"
    ListFuel = Type_to_Fuel(FuelType)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 7, color = "#fee600", child = render.Text(content = "RAA FUEL WATCH", color = "#000", font = mainFont)),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 1, color = "#000"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        Outlet_Name(Outlet),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 12, color = "#000", child = render.Text(content = Price, color = "#48a800", font = priceFont)),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 10, color = "#000", child = render.Text(content = ListFuel, color = "#FFF", font = mainFont)),
                    ],
                ),
            ],
        ),
    )

def Outlet_Name(Outlet):
    if len(Outlet) > 15:
        Outlet_Resp = render.Marquee(width = 64, height = 10, child = render.Text(content = Outlet, color = "#FFF", font = "CG-pixel-3x5-mono"))

    else:
        Outlet_Resp = render.Box(width = 64, height = 5, child = render.Text(content = Outlet, color = "#fff", font = "CG-pixel-3x5-mono"))

    return Outlet_Resp

def Type_to_Fuel(type_id):
    Type = ""

    if type_id == "2":
        Type = "Unleaded 91"
    elif type_id == "5":
        Type = "Premium 95"
    elif type_id == "8":
        Type = "Premium 98"
    elif type_id == "3":
        Type = "Diesel"
    elif type_id == "4":
        Type = "LPG"
    elif type_id == "12":
        Type = "e10"
    elif type_id == "19":
        Type = "e85"
    else:
        Type = ""

    return Type

def safe_coordinate(value, minimum, maximum):
    text = str(value).strip()
    if not text or len(text) > 20 or not any([char.isdigit() for char in text.codepoints()]) or text.count(".") > 1 or text.count("-") > 1 or ("-" in text and not text.startswith("-")):
        return None
    if any([char not in "0123456789.-" for char in text.codepoints()]):
        return None
    number = float(text)
    return text if minimum <= number and number <= maximum else None

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, align = "center")))

FuelOptions = [
    schema.Option(
        display = "Unleaded 91",
        value = "2",
    ),
    schema.Option(
        display = "Premium Unleaded 95",
        value = "5",
    ),
    schema.Option(
        display = "Premium Unleaded 98",
        value = "8",
    ),
    schema.Option(
        display = "Diesel",
        value = "3",
    ),
    schema.Option(
        display = "LPG",
        value = "4",
    ),
    schema.Option(
        display = "e10",
        value = "12",
    ),
    schema.Option(
        display = "e85",
        value = "19",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Enter Location",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "FuelType",
                name = "Select the fuel type",
                desc = "Select the fuel type",
                icon = "gasPump",
                default = FuelOptions[0].value,
                options = FuelOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)
    body = res.body()
    if res.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    return json.decode(body, None)
