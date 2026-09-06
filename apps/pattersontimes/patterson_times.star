"""
Applet: Patterson Times
Summary: Patterson SkyTrain Times
Description: Displays next train times for Patterson SkyTrain station in Vancouver. More stations coming soon.
Author: Aiden Mitchell
"""

load("http.star", "http")
load("images/expo_icon.png", EXPO_ICON_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("time.star", "time")

EXPO_ICON = EXPO_ICON_ASSET.readall()

API_URL = "https://gist.githubusercontent.com/aidenmitchell/95184f9d8a352908afc118b08a537d3f/raw"
DATA_TTL_SECONDS = 3600
MAX_RESPONSE_BYTES = 128 * 1024

def fetch_train_data():
    r = http.get(API_URL, ttl_seconds = DATA_TTL_SECONDS)
    body = r.body()
    if r.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    payload = r.json()
    return payload if type(payload) == "dict" else None

def get_local_time():
    return time.now().in_location("America/Vancouver")

def format_time_difference(time_diff):
    """Format the time difference. If it's 0, return 'now'."""
    return "now" if time_diff == 0 else "{} min".format(time_diff)

def parse_time_to_minutes(time_str):
    """Convert a time string in the format 'HH:MM:SS' to minutes since midnight."""
    if type(time_str) != "string" or not re.match(r"^([01]\d|2[0-3]):[0-5]\d:[0-5]\d$", time_str):
        return None
    hours, minutes, _ = [int(part) for part in time_str.split(":")]
    return hours * 60 + minutes

def time_difference_in_minutes(start, end):
    """Calculate minutes until a departure, wrapping across midnight."""
    return (end - start) % (24 * 60)

def get_towards_waterfront_times(train_data, current_time_minutes):
    """Retrieve the two nearest train times towards Waterfront."""
    departures = [parse_time_to_minutes(t) for t, dest in train_data.items() if dest == "Waterfront"]
    return sorted([time_difference_in_minutes(current_time_minutes, departure) for departure in departures if departure != None])[:2]

def get_away_from_waterfront_times(train_data, current_time_minutes):
    """Retrieve the nearest "away from Waterfront" destination and its two nearest departure times."""
    departures = []
    for departure_time, destination in train_data.items():
        departure = parse_time_to_minutes(departure_time)
        if destination != "Waterfront" and type(destination) == "string" and departure != None:
            departures.append((time_difference_in_minutes(current_time_minutes, departure), destination))
    if not departures:
        return "No service", []
    nearest_away_destination = sorted(departures)[0][1]
    return nearest_away_destination, sorted([diff for diff, destination in departures if destination == nearest_away_destination])[:2]

def render_train_times():
    train_data = fetch_train_data()
    if not train_data:
        return render.Root(child = render.Text("Failed to fetch train data."))

    # Retrieve times
    local_time = get_local_time()
    current_time_minutes = local_time.hour * 60 + local_time.minute
    towards_waterfront_diff = get_towards_waterfront_times(train_data, current_time_minutes)
    nearest_away_destination, away_from_waterfront_diff = get_away_from_waterfront_times(train_data, current_time_minutes)

    # Convert times to relative format
    waterfront_relative_times = [format_time_difference(diff) for diff in towards_waterfront_diff] or ["No service"]
    kg_pwu_relative_times = [format_time_difference(diff) for diff in away_from_waterfront_diff] or ["No service"]

    return render.Root(
        child = render.Column(
            children = [
                # First row for "Waterfront"
                render.Row(
                    children = [
                        # Column 1
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 2
                        render.Column(
                            children = [
                                render.Marquee(width = 64, child = render.Text("Waterfront", font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(waterfront_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
                # Padding of 8 pixels between rows
                render.Box(height = 4),
                # Second row for the nearest away destination
                render.Row(
                    children = [
                        # Column 3
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 4
                        render.Column(
                            children = [
                                render.Marquee(width = 64 - 10, child = render.Text(nearest_away_destination, font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(kg_pwu_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main():
    return render_train_times()
