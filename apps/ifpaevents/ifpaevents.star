"""
Applet: IFPAEvents
Summary: See Upcoming IFPA Events
Description: Display a list of upcoming International Flipper Pinball Association events based on location.
Author: coreyhulse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TIME_IN_SECONDS = 3600
DEFAULT_MAX_DISTANCE = 50

# Default location is the old PAPA Headquarters in Carnegie, PA
DEFAULT_LOCATION = json.encode({
    "lat": "40.400046",
    "lng": "-80.095728",
    "description": "Carnegie, PA, USA",
    "locality": "Carnegie",
    "place_id": "ChIJTR1tUdj3NIgRtGxUcq5Luk4",
    "timezone": "America/New_York",
})

def main(config):
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    max_distance = config.str("max_distance", DEFAULT_MAX_DISTANCE)

    api_key = config.str("ifpa_api_key")
    upcoming_events_breakout = []
    upcoming_events = []

    calendar = []
    if api_key and max_distance and len(max_distance) <= 4 and not any([c not in "0123456789" for c in max_distance.elems()]):
        response = http.get(
            "https://api.ifpapinball.com/v2/calendar/search",
            params = {
                "latitude": str(location.get("lat", "")),
                "longitude": str(location.get("lng", "")),
                "distance": max_distance,
                "distance_type": "Miles",
                "api_key": api_key,
            },
        )
        if response.status_code == 200:
            calendar = response.json().get("calendar", [])[:3]

    if calendar:
        for event_data in calendar:
            if event_data.get("tournament_name") and event_data.get("city") and event_data.get("start_date"):
                upcoming_events_breakout.append(event_data["tournament_name"] + " in " + event_data["city"] + " on " + event_data["start_date"])

        for event in upcoming_events_breakout:
            upcoming_events.append(
                render.Row(
                    children = [
                        render.Marquee(
                            child = render.Text(event, font = "tom-thumb"),
                            width = 64,
                            offset_start = 32,
                            offset_end = 32,
                            align = "start",
                        ),
                    ],
                ),
            )
    else:
        upcoming_events.append(
            render.Row(
                children = [
                    render.Marquee(
                        child = render.Text("No upcoming events", font = "tom-thumb"),
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        align = "start",
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Text("IFPA", font = "tom-thumb", color = "#ff0"),
                        render.Text(" %s " % location["locality"], font = "tom-thumb", color = "#c50"),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = upcoming_events,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "max_distance",
                name = "Max Distance",
                desc = "The maximum number of miles away you want to monitor",
                icon = "user",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Monitor new machines from this location",
                icon = "locationDot",
            ),
            schema.Text(
                id = "ifpa_api_key",
                name = "IFPA API Key",
                desc = "An IFPA API key to access the IFPA API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
