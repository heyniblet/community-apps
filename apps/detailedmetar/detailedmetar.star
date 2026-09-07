"""
Applet: DetailedMETAR
Summary: Display detailed METAR
Description: Display detailed, decoded METAR information.
Author: SamuelSagarino
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_AIRPORT = "KORL"
METAR_URL = "https://aviationweather.gov/api/data/metar"
MAX_RESPONSE_BYTES = 512 * 1024

def render_error(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.Text("METAR", color = "#fff"), render.Text(message, color = "#888")],
        ),
    )

def parse_airport(value):
    if type(value) != "string":
        return None
    value = value.strip().upper()
    return value if len(value) == 4 and all([char.isalnum() for char in value.codepoints()]) else None

def number(value, minimum, maximum):
    if type(value) not in ["int", "float"] or value < minimum or value > maximum:
        return None
    return value

def parse_report_time(value):
    if type(value) != "string" or not re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?Z$", value):
        return None
    year = int(value[0:4])
    month = int(value[5:7])
    day = int(value[8:10])
    hour = int(value[11:13])
    minute = int(value[14:16])
    second = int(value[17:19])
    if year < 2000 or year > 2100 or month < 1 or month > 12 or hour > 23 or minute > 59 or second > 59:
        return None
    days = [31, 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if day < 1 or day > days[month - 1]:
        return None
    return time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "UTC")

def sanitize_metar(value, airport):
    if type(value) != "dict" or value.get("icaoId") != airport:
        return None
    observation_time = value.get("reportTime")
    if parse_report_time(observation_time) == None:
        return None
    temperature = number(value.get("temp"), -100, 100)
    dewpoint = number(value.get("dewp"), -100, 100)
    wind_speed = number(value.get("wspd", 0), 0, 300)
    wind_gust = number(value.get("wgst"), 0, 400) if value.get("wgst") != None else None
    wind_direction = value.get("wdir", 0)
    if wind_direction != "VRB":
        wind_direction = number(wind_direction, 0, 360)
    visibility = value.get("visib")
    if visibility != "10+":
        visibility = number(visibility, 0, 100)
    if None in [temperature, dewpoint, wind_speed, wind_direction, visibility]:
        return None

    clouds = []
    raw_clouds = value.get("clouds", [])
    if type(raw_clouds) != "list":
        return None
    for layer in raw_clouds[:4]:
        if type(layer) != "dict" or layer.get("cover") not in ["SKC", "CLR", "FEW", "SCT", "BKN", "OVC", "VV"]:
            continue
        base = number(layer.get("base"), 0, 100000)
        clouds.append({"cover": layer["cover"], "base": int(base) if base != None else 12000})

    weather = value.get("wxString")
    weather = weather if type(weather) == "string" and len(weather) <= 64 else None
    return {
        "icaoId": airport,
        "reportTime": observation_time,
        "temp": temperature,
        "dewp": dewpoint,
        "wdir": wind_direction,
        "wspd": wind_speed,
        "wgst": wind_gust,
        "visib": visibility,
        "clouds": clouds,
        "wxString": weather,
    }

def main(config):
    # Define schema options from the user.
    airport = parse_airport(config.str("airport", DEFAULT_AIRPORT))
    f_selector = config.bool("fahrenheit_temperatures", False)
    if not airport:
        return render_error("Invalid airport")

    rep = http.get(
        METAR_URL,
        params = {"format": "json", "ids": airport, "hours": "2"},
        ttl_seconds = 300,
        headers = {"User-Agent": "Niblet DetailedMETAR/1.0 (+https://heyniblet.com)"},
    )
    body = rep.body()
    metar_data = json.decode(body, None) if rep.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES else None
    decodedMetar = sanitize_metar(metar_data[0], airport) if type(metar_data) == "list" and metar_data else None
    if decodedMetar == None:
        return render_error("No data")

    # Get observation time.
    observationDate = parse_report_time(decodedMetar["reportTime"])

    # Create "humanized" readout. Ex; "5 minutes ago"
    humanizedTime = humanize.time(observationDate)

    # Primary display
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    child = render.Column(
                        expanded = True,
                        children = [
                            # Bottom line changes color based upon status.
                            render.Row(
                                children = [
                                    render.Box(height = 2, width = 64, color = getBackgroundColor(decodedMetar)),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Text(getStationID(decodedMetar), color = getTextColor(decodedMetar), font = "tb-8"),
                                                render.Box(height = 1, color = "#1a1a1a"),
                                                wxDisplay(decodedMetar),
                                            ],
                                        ),
                                        width = 22,
                                        height = 14,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        width = 16,
                                        height = 16,
                                        child = render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = getWindBadge(decodedMetar),
                                        ),
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Temperature / dew point readout
                                                getTempDP(decodedMetar, f_selector),
                                                #getPresentWeather(decodedMetar),
                                                # Time of observation readout.
                                                render.Marquee(
                                                    width = 21,
                                                    child = render.Text(humanizedTime, color = "#8CADA7", font = "tom-thumb"),
                                                ),
                                            ],
                                        ),
                                        width = 22,
                                        height = 14,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Current wind speed.
                                                getWindDirection(decodedMetar),
                                                # Current wind direction.
                                                getWindSpeed(decodedMetar),
                                            ],
                                        ),
                                        width = 32,
                                        height = 15,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Present cloud cover layer animation.
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "cover"),
                                                        ),
                                                    height = 6,
                                                ),
                                                # Present ceiling animation.
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "levels"),
                                                        ),
                                                    height = 6,
                                                ),
                                            ],
                                        ),
                                        width = 32,
                                        height = 15,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(height = 1),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airport",
                name = "Airport",
                desc = "What airport to retrieve METAR from",
                icon = "planeArrival",
            ),
            schema.Toggle(
                id = "fahrenheit_temperatures",
                name = "Fahrenheit",
                desc = "Display temperatures in fahrenheit",
                icon = "thermometer",
                default = False,
            ),
        ],
    )

# Station ID; returns "KMCO", "KBOS", etc
def getStationID(decodedMetar):
    stationID = decodedMetar["icaoId"]
    return stationID

# Returns temperature in celsius.
def getTemperature(decodedMetar):
    result = decodedMetar["temp"]
    return result

# Returns dew point in celsius.
def getDewpoint(decodedMetar):
    result = decodedMetar["dewp"]
    return result

# Returns temperature / dewpoint display.
def getTempDP(decodedMetar, f_selector):
    temperature = getTemperature(decodedMetar)
    dewPoint = getDewpoint(decodedMetar)
    resultTextColor = getSecondaryTextColor(decodedMetar)

    temperature = int(float(temperature))
    dewPoint = int(float(dewPoint))

    # Determine dew point spread.
    temperature_h = temperature + 4
    temperature_l = temperature - 4

    # If dewpoint spread is +- 4 / display text orange.
    if (dewPoint >= temperature_l):
        if (temperature_h >= dewPoint):
            resultTextColor = "#f0a13a"

    if (dewPoint == temperature):
        resultTextColor = "#db3d5d"

    # If the user wants readouts in fahrenheit.
    if (f_selector == True):
        temperature = (temperature * 9 / 5) + 32
        dewPoint = (dewPoint * 9 / 5) + 32

        temperature = int(float(temperature))
        dewPoint = int(float(dewPoint))

    result = render.Text(str(temperature) + "/" + str(dewPoint), color = resultTextColor, font = "tom-thumb")

    return result

# Returns the cloud cover animation for the type designated. "Cover" or "levels".
def getCloudCover(decodedMetar, type):
    # This function returns the animation for the cloud layers.

    output = []
    layerZero = None
    layerOne = None
    layerTwo = None
    layerThr = None
    layerCount = len(decodedMetar["clouds"])

    # This function can be used to return either "cover" = sky cover or "levels" = base levels.

    if (type == "cover"):
        if (layerCount == 0):
            layerZero = render.Text("CLR", color = getCloudCeiling_textColor(12000), font = "tom-thumb")

        if (layerCount >= 1):
            layerZero = render.Text(decodedMetar["clouds"][0]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][0]["base"]), font = "tom-thumb")

        if (layerCount >= 2):
            layerOne = render.Text(decodedMetar["clouds"][1]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][1]["base"]), font = "tom-thumb")

        if (layerCount >= 3):
            layerTwo = render.Text(decodedMetar["clouds"][2]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][2]["base"]), font = "tom-thumb")

        if (layerCount >= 4):
            layerThr = render.Text(decodedMetar["clouds"][3]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][3]["base"]), font = "tom-thumb")

    if (type == "levels"):
        if (layerCount == 0):
            layerZero = None

        if (layerCount >= 1):
            if decodedMetar["clouds"][0]["base"] != None:
                layerZero = render.Text(str(int(decodedMetar["clouds"][0]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][0]["base"]), font = "tom-thumb")
            else:
                layerZero = None

        if (layerCount >= 2):
            layerOne = render.Text(str(int(decodedMetar["clouds"][1]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][1]["base"]), font = "tom-thumb")

        if (layerCount >= 3):
            layerTwo = render.Text(str(int(decodedMetar["clouds"][2]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][2]["base"]), font = "tom-thumb")

        if (layerCount >= 4):
            layerThr = render.Text(str(int(decodedMetar["clouds"][3]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][3]["base"]), font = "tom-thumb")

    if (layerCount >= 0):
        extendedOutput = [
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
        ]

        output = extendedOutput

    if (layerCount >= 2):
        extendedOutput = [
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
        ]

        # Fix for flicker issue that happens when you only have 2 values in the animation.
        if (layerCount == 2):
            output.extend(extendedOutput)
            output.extend(output)
        else:
            output.extend(extendedOutput)

    if (layerCount >= 3):
        extendedOutput = [
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
        ]

        output.extend(extendedOutput)

    if (layerCount >= 4):
        extendedOutput = [
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
        ]

        output.extend(extendedOutput)

    return output

# Returns wind speed in knots
def getWindSpeed(decodedMetar):
    result = None
    resultTextColor = getSecondaryTextColor(decodedMetar)

    windSpeed = getWindSpeed_value(decodedMetar)

    # If wind speed is 0 return "Calm" otherwise - respond xx kts
    if windSpeed != 0:
        windSpeedText = str(windSpeed) + "kts"
    else:
        windSpeedText = "Calm"

    # Set wind gust variable
    if decodedMetar.get("wgst", None) != None:
        windGust = int(decodedMetar["wgst"])
        windSpeedText = str(windSpeed) + "-" + str(windGust) + "kts"

    # Wind speed color determinations
    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    result = render.Text(windSpeedText, color = resultTextColor, font = "tom-thumb")

    return result

# Returns raw wind direction value.
def getWindSpeed_value(decodedMetar):
    return int(decodedMetar.get("wspd", 0))

# Returns wind direction in degrees
def getWindDirection(decodedMetar):
    resultTextColor = getSecondaryTextColor(decodedMetar)

    #Determine if wind speed is high. Will apply wind speed color to direction to match.
    windSpeed = int(getWindSpeed_value(decodedMetar))

    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    if int(getWindDirection_value(decodedMetar)) == 0:
        windDirection = "VRB @"
    else:
        windDirection = getWindDirection_value(decodedMetar) + " @"

    result = render.Text(str(windDirection), color = resultTextColor, font = "tom-thumb")

    return result

# Returns raw wind direction value.
def getWindDirection_value(decodedMetar):
    if (decodedMetar.get("wdir", 0) == "VRB"):
        return "0"
    return str(int(decodedMetar.get("wdir", 0)))

def getWindBadge(decodedMetar):
    fillColor = getBackgroundColor(decodedMetar)
    direction = int(getWindDirection_value(decodedMetar))
    return render.Box(
        width = 15,
        height = 15,
        child = render.Stack(
            children = [
                render.Circle(
                    diameter = 15,
                    color = getBackgroundColor(decodedMetar),
                ),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Circle(
                        diameter = 13,
                        color = "#1a1a1a",
                    ),
                ),
                getWindSector(direction, fillColor),
            ],
        ),
    )

def getWindSector(direction, color):
    if direction == 0:
        return render.Stack(children = [])

    direction = quantizeDirection(direction)

    points = getSectorPoints(direction)
    return render.Stack(children = [pixel(p[0], p[1], getSectorColor(p[0], p[1], direction, color)) for p in points])

def quantizeDirection(directionDegrees):
    # Stabilize rendering and avoid tiny per-degree raster differences.
    bucketSize = 30
    normalized = directionDegrees % 360
    return int((normalized + (bucketSize / 2)) / bucketSize) * bucketSize % 360

def getSectorPoints(directionDegrees):
    # True angular sector clipped to the inner circle (15x15 grid).
    cx = 7.5
    cy = 7.5
    innerRadius = 7.5

    # Tuned for 30-degree buckets so each step still reads like a slice.
    halfAngleDegrees = 32

    theta = (directionDegrees % 360) * math.pi / 180.0
    unitX = math.sin(theta)
    unitY = -math.cos(theta)
    cosHalfAngle = math.cos((halfAngleDegrees * math.pi) / 180.0)
    cosHalfAngleSq = cosHalfAngle * cosHalfAngle

    points = []
    for y in range(15):
        for x in range(15):
            if shouldFillSectorAnglePixel(x, y, cx, cy, innerRadius, unitX, unitY, cosHalfAngleSq):
                points.append([x, y])

    return points

def shouldFillSectorAnglePixel(x, y, centerX, centerY, radius, unitX, unitY, cosHalfAngleSq):
    if x == 7 and y == 7:
        return True

    sampleOffsets = [0.2, 0.5, 0.8]
    hits = 0
    for sy in sampleOffsets:
        for sx in sampleOffsets:
            px = x + sx
            py = y + sy
            dx = px - centerX
            dy = py - centerY
            distanceSq = (dx * dx) + (dy * dy)
            if distanceSq > (radius * radius):
                continue

            # # Always fill a tiny core so sectors stay anchored and don't "tuck in".
            # if distanceSq <= 1.6:
            #     hits = hits + 1
            #     continue

            dot = (dx * unitX) + (dy * unitY)
            if dot < 0:
                continue

            # inside heading cone if angle-to-heading <= half angle
            if (dot * dot) >= (distanceSq * cosHalfAngleSq):
                hits = hits + 1

    return hits >= 4

def isInsideCircle(px, py, cx, cy, radius):
    dx = px - cx
    dy = py - cy
    return (dx * dx) + (dy * dy) <= (radius * radius)

def getSectorColor(x, y, directionDegrees, baseColor):
    # Fill gradient: brighter toward the outer edge to emulate depth.
    centerX = 7.5
    centerY = 7.5
    px = x + 0.5
    py = y + 0.5
    dx = px - centerX
    dy = py - centerY

    theta = (directionDegrees % 360) * math.pi / 180.0
    unitX = math.sin(theta)
    unitY = -math.cos(theta)
    perpX = -unitY
    perpY = unitX

    forward = (dx * unitX) + (dy * unitY)
    lateral = abs((dx * perpX) + (dy * perpY))

    gradient = getSectorGradient(baseColor)
    highlight = gradient["highlight"]
    mid = gradient["mid"]
    shadow = gradient["shadow"]

    if forward >= 5.0:
        color = highlight
    elif forward >= 3.7:
        color = mid
    elif forward >= 2.4:
        color = baseColor
    else:
        color = shadow

    # Soften wedge shoulders for a more rounded visual.
    if lateral >= 1.9 and forward >= 2.0:
        if color == highlight:
            color = mid
        elif color == mid:
            color = baseColor
        elif color == baseColor:
            color = shadow

    return color

def getSectorGradient(baseColor):
    # Keep gradient tied to the active category color.
    if baseColor == "#62f55f":  # VFR
        return {
            "highlight": "#9cff97",
            "mid": "#7bf777",
            "shadow": "#3bbd38",
        }
    if baseColor == "#8d87fa":  # MVFR
        return {
            "highlight": "#b5b0ff",
            "mid": "#9f99ff",
            "shadow": "#625dd0",
        }
    if baseColor == "#db3d5d":  # IFR
        return {
            "highlight": "#ff6d8d",
            "mid": "#f05778",
            "shadow": "#c93453",
        }
    if baseColor == "#f25ce3":  # LIFR
        return {
            "highlight": "#ff8ff4",
            "mid": "#f777eb",
            "shadow": "#cc36be",
        }

    # Fallback if palette changes in the future.
    return {
        "highlight": "#ffffff",
        "mid": baseColor,
        "shadow": "#808080",
    }

def pixel(x, y, color):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = 1, height = 1, color = color),
    )

# Returns current flight category.
def getFlightCategory(decodedMetar):
    flightCategory = None
    cloudLayers = decodedMetar["clouds"]

    if (decodedMetar["visib"] == "10+"):
        visibility = 10
    else:
        visibility = int(decodedMetar["visib"])

    baseClouds = 12000
    for layer in cloudLayers:
        if layer["cover"] in ["BKN", "OVC", "VV"] and layer["base"] < baseClouds:
            baseClouds = layer["base"]

    #IFR
    if baseClouds > 3000 and visibility >= 5:
        flightCategory = "VFR"

    if baseClouds <= 3000 or visibility <= 5:
        flightCategory = "MVFR"

    if baseClouds <= 1000 or visibility <= 3:
        flightCategory = "IFR"

    if baseClouds < 500 or visibility < 1:
        flightCategory = "LIFR"

    return flightCategory

# Returns primary text color based upon current flight category.
def getTextColor(decodedMetar):
    category = getFlightCategory(decodedMetar)
    if category == "VFR":
        return "#87fa8b"
    elif category == "MVFR":
        return "#73b8f5"
    elif category == "IFR":
        return "#f5737c"
    elif category == "LIFR":
        return "#e88bf0"
    else:
        return "#f5737c"

# Returns secondary text color based upon current flight category.
def getSecondaryTextColor(decodedMetar):
    category = getFlightCategory(decodedMetar)
    if category == "VFR":
        return "#8CADA7"
    elif category == "MVFR":
        return "#8CADA7"
    elif category == "IFR":
        return "#8CADA7"
    elif category == "LIFR":
        return "#8CADA7"
    else:
        return "#8CADA7"

# Returns current background color (shapes & lines) for current flight category.
def getBackgroundColor(decodedMetar):
    category = getFlightCategory(decodedMetar)
    if category == "VFR":
        return "#62f55f"
    elif category == "MVFR":
        return "#8d87fa"
    elif category == "IFR":
        return "#db3d5d"
    elif category == "LIFR":
        return "#f25ce3"
    else:
        return "#f5737c"

# Returns cloud cover text color.
def getCloudCeiling_textColor(ceilingHeight):
    ceilingColor = "#8cada7"

    if ceilingHeight != None:
        ceilingHeight = int(ceilingHeight)
    else:
        ceilingHeight = 12000

    # Ceiling is less than or equal to 500
    if ceilingHeight <= 500:
        ceilingColor = "#e88bf0"

    # Ceiling is between 501 & 1000
    if ceilingHeight > 500:
        if ceilingHeight <= 999:
            ceilingColor = "#f5737c"

    # Ceiling is between 1000 & 3000
    if ceilingHeight > 999:
        if ceilingHeight <= 3001:
            ceilingColor = "#73b8f5"

    # Ceiling is above 3000
    return ceilingColor

def wxDisplay(decodedMetar):
    presentWeather = decodedMetar.get("wxString", None)

    result = "empty"
    color = getTextColor(decodedMetar)

    if presentWeather != None:
        if "BR" in presentWeather:
            result = "Mist"

        if "DU" in presentWeather:
            result = "Dust"

        if "FG" in presentWeather:
            result = "Fog"

        if "FU" in presentWeather:
            result = "Smoke"

        if "HZ" in presentWeather:
            result = "Haze"

        if "SA" in presentWeather:
            result = "Sand"

        if "VA" in presentWeather:
            result = "Volcanic Ash"

        if "DZ" in presentWeather:
            result = "Drizzle"

        if "GR" in presentWeather:
            result = "Hail"

        if "GS" in presentWeather:
            result = "Snow Pellets"

        if "IC" in presentWeather:
            result = "Ice Crystals"

        if "PL" in presentWeather:
            result = "Ice Pellets"

        if "RA" in presentWeather:
            result = "Rain"

        if "SG" in presentWeather:
            result = "Snow Grains"

        if "SN" in presentWeather:
            result = "Snow"

        if "UP" in presentWeather:
            result = "Unknown Precipitation"

        if "SH" in presentWeather:
            result = "Showers in Vicinity"

        if "TS" in presentWeather:
            result = "Thunderstorm in Vicinity"

        result = render.Marquee(width = 20, child = render.Text(result, color = color, font = "tom-thumb"))
    else:
        result = None

    return result
