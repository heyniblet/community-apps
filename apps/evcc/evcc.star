"""
Applet: EVCC
Summary: EVCC metrics for your EV
Description: EVCC is an energy management system with a focus on electromobility. This app to display the most essential data.
Author: cruschke
"""

load("encoding/csv.star", "csv")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/car0_icon.png", CAR0_ICON_ASSET = "file")
load("images/car1_blue_icon.png", CAR1_BLUE_ICON_ASSET = "file")
load("images/car1_green_icon.png", CAR1_GREEN_ICON_ASSET = "file")
load("images/car2_blue_icon.png", CAR2_BLUE_ICON_ASSET = "file")
load("images/car2_green_icon.png", CAR2_GREEN_ICON_ASSET = "file")
load("images/car3_blue_icon.png", CAR3_BLUE_ICON_ASSET = "file")
load("images/car3_green_icon.png", CAR3_GREEN_ICON_ASSET = "file")
load("images/car4_blue_icon.png", CAR4_BLUE_ICON_ASSET = "file")
load("images/car4_green_icon.png", CAR4_GREEN_ICON_ASSET = "file")
load("images/car5_blue_icon.png", CAR5_BLUE_ICON_ASSET = "file")
load("images/car5_green_icon.png", CAR5_GREEN_ICON_ASSET = "file")
load("images/car6_blue_icon.png", CAR6_BLUE_ICON_ASSET = "file")
load("images/car6_green_icon.png", CAR6_GREEN_ICON_ASSET = "file")
load("images/car7_blue_icon.png", CAR7_BLUE_ICON_ASSET = "file")
load("images/car7_green_icon.png", CAR7_GREEN_ICON_ASSET = "file")
load("images/nuclear_outline_icon.png", NUCLEAR_OUTLINE_ICON_ASSET = "file")
load("images/nuclear_solid_icon.png", NUCLEAR_SOLID_ICON_ASSET = "file")
load("images/solarenergy_icon.png", SOLARENERGY_ICON_ASSET = "file")
load("images/sun_icon.png", SUN_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

CAR0_ICON = CAR0_ICON_ASSET.readall()
CAR1_BLUE_ICON = CAR1_BLUE_ICON_ASSET.readall()
CAR1_GREEN_ICON = CAR1_GREEN_ICON_ASSET.readall()
CAR2_BLUE_ICON = CAR2_BLUE_ICON_ASSET.readall()
CAR2_GREEN_ICON = CAR2_GREEN_ICON_ASSET.readall()
CAR3_BLUE_ICON = CAR3_BLUE_ICON_ASSET.readall()
CAR3_GREEN_ICON = CAR3_GREEN_ICON_ASSET.readall()
CAR4_BLUE_ICON = CAR4_BLUE_ICON_ASSET.readall()
CAR4_GREEN_ICON = CAR4_GREEN_ICON_ASSET.readall()
CAR5_BLUE_ICON = CAR5_BLUE_ICON_ASSET.readall()
CAR5_GREEN_ICON = CAR5_GREEN_ICON_ASSET.readall()
CAR6_BLUE_ICON = CAR6_BLUE_ICON_ASSET.readall()
CAR6_GREEN_ICON = CAR6_GREEN_ICON_ASSET.readall()
CAR7_BLUE_ICON = CAR7_BLUE_ICON_ASSET.readall()
CAR7_GREEN_ICON = CAR7_GREEN_ICON_ASSET.readall()
NUCLEAR_OUTLINE_ICON = NUCLEAR_OUTLINE_ICON_ASSET.readall()
NUCLEAR_SOLID_ICON = NUCLEAR_SOLID_ICON_ASSET.readall()
SOLARENERGY_ICON = SOLARENERGY_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()

DEFAULT_BUCKET = "evcc"
DEFAULT_LOCATION = {
    "lat": 52.52136203907116,
    "lng": 13.413308033057413,
    "locality": "Weltzeituhr Alexanderplatz",
}
DEFAULT_TIMEZONE = "Europe/Berlin"

INFLUXDB_HOST_DEFAULT = "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query"
INFLUXDB_HOST_US = "https://us-east-1-1.aws.cloud2.influxdata.com/api/v2/query"
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_SERIES_POINTS = 100

# COLOR DEFINITIONS

BLACK = "#000"
DARK_GREEN = "#062E03"
FIREBRICK = "E1121F"
FIREBRICK_DARK = "#380508"
GREY = "#1A1A1A"
RED = "#F00"
STEELBLUE = "39A2E4"
STEELBLUE_DARK = "#092a3f"
SUNGLOW = "FFCA3A"
WHITE = "#FFF"
YELLOW = "FFD166"
YELLOWGREEN = "AAE926"
YELLOWGREEN_DARK = "#2c3d06"

FONT = "tom-thumb"

# ICONS

####

# the main function
def main(config):
    # read the configuration
    influxdb_host = config.str("influxdb", INFLUXDB_HOST_DEFAULT)
    if influxdb_host not in [INFLUXDB_HOST_DEFAULT, INFLUXDB_HOST_US]:
        influxdb_host = INFLUXDB_HOST_DEFAULT
    api_key = safe_api_key(config.str("api_key", ""))
    vehicle = safe_flux_value(config.str("vehicle", "mycar"), "mycar")
    bucket = safe_flux_value(config.get("bucket", DEFAULT_BUCKET), DEFAULT_BUCKET)
    if api_key == None:
        return api_error()

    location = config.get("location")
    loc = json.decode(location, None) if type(location) == "string" and location and len(location) <= 8192 else None
    loc = loc if type(loc) == "dict" else DEFAULT_LOCATION
    timezone = safe_timezone(loc.get("timezone", DEFAULT_TIMEZONE))

    # some FluxQL query parameters that every single query needs
    flux_defaults = '                                                     \
        import "timezone"                                               \
        option location = timezone.location(name: "' + timezone + '")   \
        from(bucket:"' + bucket + '")'

    if not api_key or api_key == "UNDEFINED":
        gridPowerSeries = [(0, 382.5), (1, 437.3), (2, 142), (3, 907.), (4, 758), (5, 632), (6, -0.0), (7, 745), (8, 674), (9, 781), (10, 985), (11, 547), (12, 967), (13, 1043), (14, 604), (15, 2709), (16, 2267), (17, 1763.4), (18, -142), (19, 2100), (20, 3900), (21, 3800), (22, 3600), (23, 3900), (24, 2900), (25, 3200), (26, 3200), (27, 3100), (28, 2400), (29, 3700), (30, 3400), (31, 455), (32, 844), (33, 1942), (34, 765), (35, 551), (36, 710), (37, 384), (38, -36), (39, 213), (40, -1974), (41, -1451), (42, -2165), (43, -2614.5), (44, -2450), (45, -2233.6), (46, -2111), (47, -2100), (48, -1800)]
        chargePowerSeries = [(0, 0.0), (1, 0.0), (2, 0.0), (3, 0.0), (4, 0.0), (5, 0.0), (6, 0.0), (7, 0.0), (8, 0.0), (9, 0.0), (10, 0.0), (11, 0.0), (12, 0.0), (13, 0.0), (14, 0.0), (15, 0.0), (16, 0.0), (17, 0.0), (18, 0.0), (19, 0.0), (20, 812), (21, 1973), (22, 3367), (23, 3514), (24, 3320), (25, 3503), (26, 2691), (27, 2979), (28, 2185), (29, 2787), (30, 1790), (31, 0.0), (32, 0.0), (33, 0.0), (34, 0.0), (35, 0.0), (36, 0.0), (37, 0.0), (38, 0.0), (39, 0.0), (40, 0.0), (41, 0.0), (42, 1800), (43, 1750), (44, 1800), (45, 1900), (46, 1800), (47, 1700), (48, 1645)]

        chargePowerLast = 1645
        chargePowerMax = 3584
        gridPowerLast = 348
        gridPowerMax = 2644

        #homePowerLast = 100
        phasesActive = 1
        pvPowerLast = 2654
        pvPowerMax = 5378
        vehicleSocLast = 79
        vehicleRangeLast = 428

    else:
        # individual queries for the values
        chargePowerLast = getLastValue("chargePower", influxdb_host, flux_defaults, api_key)
        if chargePowerLast == None:
            return api_error()
        chargePowerMax = getMaxValue("chargePower", influxdb_host, flux_defaults, api_key)
        gridPowerLast = getLastValue("gridPower", influxdb_host, flux_defaults, api_key)
        gridPowerMax = getMaxValue("gridPower", influxdb_host, flux_defaults, api_key)

        #homePowerLast = getLastValue("homePower", influxdb_host, flux_defaults, api_key)
        phasesActive = getLastValue("phasesActive", influxdb_host, flux_defaults, api_key)
        pvPowerLast = getLastValue("pvPower", influxdb_host, flux_defaults, api_key)
        pvPowerMax = getMaxValue("pvPower", influxdb_host, flux_defaults, api_key)
        vehicleSocLast = getLastValueCar("vehicleSoc", vehicle, influxdb_host, flux_defaults, api_key)
        vehicleRangeLast = getLastValueCar("vehicleRange", vehicle, influxdb_host, flux_defaults, api_key)  # buildifier: disable=unused-variable

        # the time series for the plots
        chargePowerSeries = getSeries("chargePower", influxdb_host, flux_defaults, api_key)
        gridPowerSeries = getgridPowerSeries(influxdb_host, flux_defaults, api_key)
        if any([value == None for value in [chargePowerMax, gridPowerLast, gridPowerMax, phasesActive, pvPowerLast, pvPowerMax, vehicleSocLast, vehicleRangeLast, chargePowerSeries, gridPowerSeries]]):
            return api_error()

    # the main display

    # color coding for the columns
    if pvPowerLast > gridPowerLast:  # TODO or homePowerLast?
        col2_icon = SUN_ICON
        col2_color = YELLOWGREEN
    else:
        col2_icon = NUCLEAR_OUTLINE_ICON
        col2_color = FIREBRICK

    col3_phase1 = DARK_GREEN
    col3_phase2 = DARK_GREEN
    col3_phase3 = DARK_GREEN

    if phasesActive == 0:
        # use green colored cars
        CAR_ICON = [CAR0_ICON, CAR1_GREEN_ICON, CAR2_GREEN_ICON, CAR3_GREEN_ICON, CAR4_GREEN_ICON, CAR5_GREEN_ICON, CAR6_GREEN_ICON, CAR7_GREEN_ICON]
    else:
        # use the blue colored cars
        CAR_ICON = [CAR0_ICON, CAR1_BLUE_ICON, CAR2_BLUE_ICON, CAR3_BLUE_ICON, CAR4_BLUE_ICON, CAR5_BLUE_ICON, CAR6_BLUE_ICON, CAR7_BLUE_ICON]

    if phasesActive >= 1:
        col3_phase1 = YELLOWGREEN

    if phasesActive >= 2:
        col3_phase2 = YELLOWGREEN

    if phasesActive >= 3:
        col3_phase3 = YELLOWGREEN

    # for the case Soc and range are not available
    if vehicleSocLast == 0:
        str_vehicleSocLast = "?"
        CAR_ICON_DYNAMIC = CAR0_ICON
    else:
        str_vehicleSocLast = str(vehicleSocLast) + "%"

    if vehicleRangeLast == 0:
        str_vehicleRangeLast = "?"
    else:
        str_vehicleRangeLast = str(vehicleRangeLast)

    # calculating the car progress bar
    # based on the vehicleSocLast value
    if vehicleSocLast >= 87:
        CAR_ICON_DYNAMIC = CAR_ICON[7]
    elif vehicleSocLast >= 75:
        CAR_ICON_DYNAMIC = CAR_ICON[6]
    elif vehicleSocLast >= 62:
        CAR_ICON_DYNAMIC = CAR_ICON[5]
    elif vehicleSocLast >= 50:
        CAR_ICON_DYNAMIC = CAR_ICON[4]
    elif vehicleSocLast >= 37:
        CAR_ICON_DYNAMIC = CAR_ICON[3]
    elif vehicleSocLast >= 25:
        CAR_ICON_DYNAMIC = CAR_ICON[2]
    elif vehicleSocLast >= 12:
        CAR_ICON_DYNAMIC = CAR_ICON[1]
    else:
        CAR_ICON_DYNAMIC = CAR_ICON[0]

    ############################################################
    # the screen1 main columns
    ############################################################
    screen_1_1 = [
        # this is the PV power column
        render.Image(src = SOLARENERGY_ICON),
        render.Box(width = 2, height = 2, color = BLACK),  # for better horizontal alignment
        render.Text(humanize(pvPowerLast), color = YELLOWGREEN, font = FONT),
    ]
    screen_1_2 = [
        # this is the grid power column
        render.Image(src = col2_icon),
        render.Box(width = 2, height = 2, color = BLACK),  # for better horizontal alignment
        render.Text(humanize(abs(gridPowerLast)), color = col2_color, font = FONT),  # abs() because I don't want to report negative numbers, thats why we have the color coding
        render.Box(width = 1, height = 2, color = BLACK),
        render.Text(str(chargePowerLast), color = STEELBLUE, font = FONT),
    ]

    screen_1_3 = [
        # this is the car charging column
        render.Image(src = CAR_ICON_DYNAMIC),
        render.Row(
            children = [
                render.Box(width = 1, height = 1, color = col3_phase1),
                render.Box(width = 1, height = 1, color = col3_phase2),
                render.Box(width = 1, height = 1, color = col3_phase3),
            ],
        ),
        render.Box(width = 2, height = 1, color = BLACK),  # for better horizontal alignment
        render.Text(str_vehicleRangeLast, color = WHITE, font = FONT),
        render.Box(width = 1, height = 2, color = BLACK),
        render.Text(str_vehicleSocLast, color = WHITE, font = FONT),
    ]

    screen_1 = render.Row(
        children = [
            render.Column(
                children = screen_1_1,
                main_align = "center",
                cross_align = "center",
            ),
            render.Column(
                children = [render.Box(width = 1, height = 32, color = GREY)],
            ),
            render.Column(
                children = screen_1_2,
                main_align = "center",
                cross_align = "center",
            ),
            render.Column(
                children = [render.Box(width = 1, height = 32, color = GREY)],
            ),
            render.Column(
                children = screen_1_3,
                main_align = "center",
                cross_align = "center",
            ),
        ],
        main_align = "space_evenly",
        expanded = True,
    )

    ############################################################
    # the screen2 main columns
    ############################################################

    # pvPowerMax + gridPowerMax
    screen_2_1_1 = [
        render.Text(humanize(pvPowerMax), color = YELLOWGREEN, font = FONT),
        render.Box(width = 5, height = 1),  # some extra space
        render.Text(humanize(gridPowerMax), color = FIREBRICK, font = FONT),
    ]

    # chargePowerMax
    screen_2_1_2 = [
        render.Text(humanize(chargePowerMax), color = STEELBLUE, font = FONT),
    ]

    # gridPowerSeries
    screen_2_2_1 = [
        render.Box(
            child = render.Plot(
                data = gridPowerSeries,
                width = 47,
                height = 16,
                color = YELLOWGREEN,
                color_inverted = FIREBRICK,
                fill_color = YELLOWGREEN_DARK,
                fill_color_inverted = FIREBRICK_DARK,
                fill = True,
            ),
            width = 45,
            height = 16,
        ),
    ]

    # chargePowerSeries
    screen_2_2_2 = [
        render.Box(
            child = render.Plot(
                data = chargePowerSeries,
                width = 47,
                height = 15,
                color = STEELBLUE,
                fill_color_inverted = STEELBLUE_DARK,
                fill = True,
            ),
            width = 45,
            height = 15,
        ),
    ]

    screen2_columns_1 = render.Row(
        children = [
            render.Box(
                child = render.Column(
                    # pvPowerMax + gridPowerMax
                    children = screen_2_1_1,
                    main_align = "center",
                    cross_align = "center",
                ),
                width = 15,
                height = 15,
            ),
            render.Column(
                children = [render.Box(width = 1, height = 16, color = GREY)],
            ),
            render.Column(
                # pvPowerSeries
                children = screen_2_2_1,
                main_align = "center",
                cross_align = "center",
            ),
        ],
        main_align = "space_evenly",
        expanded = True,
    )

    screen2_columns_2 = render.Row(
        children = [
            render.Box(
                child = render.Column(
                    # chargePowerMax
                    children = screen_2_1_2,
                    main_align = "center",
                    cross_align = "center",
                ),
                width = 15,
                height = 15,
            ),
            render.Column(
                children = [render.Box(width = 1, height = 32, color = GREY)],
            ),
            render.Column(
                # chargePowerSeries
                children = screen_2_2_2,
                main_align = "center",
                cross_align = "center",
            ),
        ],
        main_align = "space_evenly",
        expanded = True,
    )

    screen_2 = render.Column(
        children = [
            screen2_columns_1,
            render.Column(
                children = [render.Box(width = 64, height = 1, color = GREY)],
            ),
            screen2_columns_2,
        ],
    )

    return render.Root(
        delay = 7 * 1000,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Animation(
                    children = [screen_1, screen_2],
                ),
            ],
        ),
    )

# https://github.com/evcc-io/docs/blob/main/docs/reference/configuration/messaging.md?plain=1#L156
# grid power - Current grid feed-in(-) or consumption(+) in watts (__float__)
# inverted the series for more natural display of the data series
# multiply by -1 to make it display logically correct in Plot

def getSeries(measurement, dbhost, defaults, api_key):
    fluxql = defaults + ' \
        |> range(start: -12h)                                    \
        |> filter(fn: (r) => r._measurement == "' + measurement + '") \
        |> group() \
        |> aggregateWindow(every: 15m, fn: mean)                    \
        |> fill(value: 0.0)                                         \
        |> map(fn: (r) => ({r with _value: (float(v: r._value)) })) \
        |> keep(columns: ["_time", "_value"])'

    #print ("query=" + fluxql)
    return getTouples(dbhost, fluxql, api_key)

# this one is special as I need inverted numbers (multiply by -1)
def getgridPowerSeries(dbhost, defaults, api_key):
    fluxql = defaults + ' \
        |> range(start: -12h)                                    \
        |> filter(fn: (r) => r._measurement == "gridPower")         \
        |> aggregateWindow(every: 15m, fn: mean)                    \
        |> fill(value: 0.0)                                         \
        |> map(fn: (r) => ({r with _value: (float(v: r._value) * -1.0) })) \
        |> keep(columns: ["_time", "_value"])'

    #print ("query=" + fluxql)
    return getTouples(dbhost, fluxql, api_key)

# average over 5 min, cached for 15 min
def getMaxValue(measurement, dbhost, defaults, api_key):
    fluxql = defaults + ' \
        |> range(start: today()) \
        |> filter(fn: (r) => r._measurement == "' + measurement + '") \
        |> group() \
        |> aggregateWindow(every: 5m, fn: mean)          \
        |> max() \
        |> toInt() \
        |> keep(columns: ["_value"])'

    return csv_number(readInfluxDB(dbhost, fluxql, api_key))

# average over 5 min, cached for 5 min
def getLastValue(measurement, dbhost, defaults, api_key):
    fluxql = defaults + ' \
        |> range(start: -5m) \
        |> filter(fn: (r) => r._measurement == "' + measurement + '") \
        |> group() \
        |> aggregateWindow(every: 5m, fn: mean)                    \
        |> toInt() \
        |> keep(columns: ["_value"])'

    return csv_number(readInfluxDB(dbhost, fluxql, api_key))

# By default, when the car is not connected to a charger, SOC and range are not updated. Hence looking back a little longer
# Check evcc loadpoint documentation how to change this behaviour.
def getLastValueCar(measurement, vehicle, dbhost, defaults, api_key):
    fluxql = defaults + ' \
        |> range(start: -12h) \
        |> filter(fn: (r) => r._measurement == "' + measurement + '"  and r.vehicle == "' + vehicle + '" and r._value > 0) \
        |> last() \
        |> toInt() \
        |> keep(columns: ["_value"])'

    return csv_number(readInfluxDB(dbhost, fluxql, api_key))

def readInfluxDB(dbhost, query, api_key):
    rep = http.post(
        dbhost,
        headers = {
            "Authorization": "Token " + api_key,
            "Accept": "application/csv",
            "Content-type": "application/json",
        },
        json_body = {"query": query, "type": "flux"},
    )

    body = rep.body()
    return body if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None

def getTouples(dbhost, query, api_key):
    result = readInfluxDB(dbhost, query, api_key)
    return csv2touples(result) if result else None

# InfluxDB returns time series as CSV, we want touples instead
def csv2touples(csvinput):
    data = csv.read_all(csvinput)
    result = []
    line_number = 0
    for row in data[1:MAX_SERIES_POINTS + 1]:
        if not row:
            continue
        value = row[-1]
        value = safe_number(value)
        if value == None:
            continue
        result.append((line_number, value))
        line_number += 1
    return result if result else None

def csv_number(body):
    if not body:
        return None
    data = csv.read_all(body)
    value = None
    for row in data[:MAX_SERIES_POINTS + 20]:
        candidate = safe_number(row[-1]) if row else None
        if candidate != None:
            value = candidate
    return int(value) if value != None else None

def safe_number(value):
    text = str(value or "").strip()
    unsigned = text[1:] if text.startswith("-") or text.startswith("+") else text
    if not unsigned or len(text) > 32 or unsigned.count(".") > 1 or not unsigned.replace(".", "").isdigit():
        return None
    return float(text)

def safe_api_key(value):
    value = str(value or "").strip()
    return value if len(value) <= 4096 and "\r" not in value and "\n" not in value else None

def safe_flux_value(value, fallback):
    value = str(value or "").strip()
    return value if value and len(value) <= 64 and all([char.isalnum() or char in "-_. " for char in value.codepoints()]) else fallback

def safe_timezone(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 64 and all([char.isalnum() or char in "/_-+" for char in value.codepoints()]) else DEFAULT_TIMEZONE

def api_error():
    return render.Root(child = render.WrappedText("InfluxDB unavailable", font = FONT))

def custom_round(number):
    integer_part = number // 1000
    remainder = number % 1000
    if remainder == 0:
        return str(integer_part) + "k"
    else:
        # Manually round to nearest thousand
        if remainder >= 500:
            integer_part += 1
        return str(integer_part) + "k"

def humanize(number):
    #print("number=" + str(number))
    if number < 10000:
        return str(number)
    else:
        rounded_number = custom_round(number)

        #print("rounded_number=" + str(rounded_number))
        return str(rounded_number)

options_screen = [
    schema.Option(
        display = "3 columns",
        value = "screen_1",
    ),
    schema.Option(
        display = "gridPower and chargePower graphs (last 12 hours)",
        value = "screen_2",
    ),
]

# see https://docs.influxdata.com/influxdb/cloud-serverless/reference/regions/

options_influxdb = [
    schema.Option(
        display = "EU Frankfurt",
        value = "https://eu-central-1-1.aws.cloud2.influxdata.com/api/v2/query",
    ),
    schema.Option(
        display = "US East (Virginia)",
        value = INFLUXDB_HOST_US,
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "influxdb",
                name = "InfluxDB region",
                desc = "the region you picked for your InfluxDB setup",
                icon = "cloud",
                default = options_influxdb[0].value,
                options = options_influxdb,
            ),
            schema.Text(
                id = "api_key",
                name = "InfluxDB API key",
                desc = "API key for InfluxDB Cloud, if not set the app is in DEMO MODE",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "bucket",
                name = "InfluxDB bucket",
                desc = "The name of the InfluxDB bucket",
                icon = "database",
                default = "evcc",
            ),
            schema.Text(
                id = "vehicle",
                name = "vehicle name",
                desc = "The vehicle you want to display",
                icon = "car",
                default = "mycar",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your device location",
                icon = "locationDot",
            ),
        ],
    )
