# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""

# ################################
# ###### App module loading ######
# ################################

load("http.star", "http")
load("images/ferry_icon.png", FERRY_ICON_ASSET = "file")

# Required modules
load("render.star", "render")
load("schema.star", "schema")

FERRY_ICON = FERRY_ICON_ASSET.readall()

# ###########################
# ###### App constants ######
# ###########################

# Base64 ferry icon data

# Mapping from ferry stop IDs to stop names
FERRY_STOP_IDS = {
    360901: "Bahnhof",
    360902: "Seegarten",
    703599: "Reventloubrücke",
    360905: "Mönkeberg",
    360907: "Möltenort, Heikendorf",
    360908: "Friedrichsort",
    370909: "Falckenstein",
    360910: "Laboe",
    360911: "Schilksee",
    360912: "Strande",
}

# Default ferry stop ID
DEFAULT_FERRY_STOP_ID = str(FERRY_STOP_IDS.keys()[0])

# Terminus ferry stop IDs (ferry directions)
FERRY_DIRECTION_IDS = [
    360910,  # Laboe
    360901,  # Bahnhof
    703599,  # Reventloubrücke
]

# Default ferry direction ID
DEFAULT_FERRY_DIRECTION_ID = str(FERRY_DIRECTION_IDS[0])

# Cache time to live
FERRY_CACHE_TTL = 60

FERRY_QUERY_URL = "https://transit.land/api/v2/rest/stops/f-germany~urban~transport:%s/departures?next=21600&limit=20"

# Function to retrieve next ferry data.
# Returns a tripple of
# - validity: Indicates if data is usable
# - next ferry: Timestamp string or None
# - status code: Status code of last query

def getNextFerry(ferryStopID, ferryDirection, apiKey):
    response = http.get(
        FERRY_QUERY_URL % ferryStopID,
        headers = {"apikey": apiKey, "Accept": "application/json"},
        ttl_seconds = FERRY_CACHE_TTL,
    )

    # Set query status code.
    queryStatusCode = response.status_code

    # Set next ferry according to response,
    # or to an empty string to denote
    # no scheduled ferry departure in cache
    # (can't cache None).
    if queryStatusCode == 200 and len(response.body()) <= 1024 * 1024:
        payload = response.json()
        stops = payload.get("stops", []) if type(payload) == "dict" else []
        departures = stops[0].get("departures", []) if stops else []
        nextFerry = ""
        for departure in departures:
            trip = departure.get("trip", {}) if type(departure) == "dict" else {}
            route = trip.get("route", {}) if type(trip) == "dict" else {}
            headsign = str(trip.get("trip_headsign") or departure.get("stop_headsign") or "")
            routeName = str(route.get("route_short_name") or route.get("route_id") or "")
            if routeName != "F1" and routeName != "4502":
                continue
            if ferryDirection not in headsign:
                continue
            event = departure.get("departure", {})
            nextFerry = str(event.get("estimated") or event.get("scheduled") or departure.get("departure_time") or "")[:5]
            break
    else:
        nextFerry = ""

    # Return (a) validity of data (status code 200),
    # (b) next ferry departure data or None,
    # (c) status code
    return (
        queryStatusCode == 200,
        nextFerry if len(nextFerry) > 0 else None,
        queryStatusCode,
    )

# ################################################
# ###### Function to render an error screen ######
# ################################################

# Function to render an error screen given a query
# status code, to be used if no valid ferry departure
# data can be retrieved from the API
def renderError(statusCode):
    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Text(
                            content = "No data",
                            color = "#990000",
                            font = "CG-pixel-4x5-mono",
                        ),
                        render.Image(src = FERRY_ICON),
                        render.Text(
                            content = "HTTP %d" % statusCode,
                            color = "#3399ff",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
            expanded = True,
            main_align = "center",
        ),
    )

# ######################################################
# ###### Functions to render ferry departure data ######
# ######################################################

# Get all required ferry departure strings for rendering.
# Returns a tuple of
# - The route, consisting of stop and direction
# - The formatted departure time
# - The formatted wait duration
def getFerryDataStrings(ferryStop, ferryDirection, nextFerry):
    route = "%s --> %s" % (ferryStop, ferryDirection)
    departureTimeStr = "-:-"
    waitDurationStr = "No service"
    if nextFerry != None:
        departureTimeStr = nextFerry
        waitDurationStr = "Scheduled"
    return (route, departureTimeStr, waitDurationStr)

# Render ferry departure data
def renderFerryData(ferryStop, ferryDirection, nextFerry):
    route, departureTime, waitDuration = getFerryDataStrings(
        ferryStop,
        ferryDirection,
        nextFerry,
    )
    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Marquee(
                        child = render.Text(
                            content = route,
                            color = "#3399ff",
                        ),
                        width = 62,
                    ),
                    render.Row(
                        children = [
                            render.Image(src = FERRY_ICON),
                            render.Column(
                                children = [
                                    render.Text(
                                        content = departureTime,
                                        font = "6x13",
                                    ),
                                    render.Text(
                                        content = waitDuration,
                                        color = "#ff6600",
                                        font = "tom-thumb",
                                    ),
                                ],
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
            ),
            padding = 1,
        ),
    )

# #############################
# ###### App entry point ######
# #############################

# Main entrypoint
def main(config):
    # Get ferry stop and ferry direction names and IDs from config
    ferryStopID = config.str(
        "ferry_stop_id",
        DEFAULT_FERRY_STOP_ID,
    )
    ferryStop = FERRY_STOP_IDS[int(ferryStopID)]
    ferryDirectionID = config.str(
        "ferry_direction_id",
        DEFAULT_FERRY_DIRECTION_ID,
    )
    ferryDirection = FERRY_STOP_IDS[int(ferryDirectionID)]
    apiKey = config.str("api_key")
    if not apiKey:
        return renderError(401)

    # Retrieve data for next ferry departure
    valid, nextFerry, statusCode = getNextFerry(ferryStopID, ferryDirection, apiKey)

    # If ferry departure data is valid, render it
    if valid:
        return renderFerryData(ferryStop, ferryDirection, nextFerry)

    # Otherwise, render an error
    return renderError(statusCode)

# ###############################################
# ###### Functions to construct app schema ######
# ###############################################

# Construct ferry stop options
def getFerryStopOptions():
    ret = []
    for stop in FERRY_STOP_IDS:
        ret.append(
            schema.Option(
                display = FERRY_STOP_IDS[stop],
                value = str(stop),
            ),
        )
    return ret

# Construct ferry direction options
def getFerryDirectionOptions():
    ret = []
    for direction in FERRY_DIRECTION_IDS:
        ret.append(
            schema.Option(
                display = FERRY_STOP_IDS[direction],
                value = str(direction),
            ),
        )
    return ret

# Construct schema
def get_schema():
    ferryStopOptions = getFerryStopOptions()
    ferryDirectionOptions = getFerryDirectionOptions()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "ferry_stop_id",
                name = "Ferry Stop",
                desc = "Display next departure for this ferry stop.",
                icon = "ferry",
                default = ferryStopOptions[0].value,
                options = ferryStopOptions,
            ),
            schema.Dropdown(
                id = "ferry_direction_id",
                name = "Ferry Direction",
                desc = "Display next departure for this ferry direction.",
                icon = "compass",
                default = ferryDirectionOptions[0].value,
                options = ferryDirectionOptions,
            ),
            schema.Text(
                id = "api_key",
                name = "Transitland API key",
                desc = "A Transitland v2 API key.",
                icon = "key",
                secret = True,
            ),
        ],
    )
