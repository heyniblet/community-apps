"""
Applet: ABC Radio
Summary: Now playing on ABC stations
Description: Shows the current playing song on various ABC stations in Australia.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TIMEOUT = 120
MAX_RESPONSE_BYTES = 64 * 1024
MAX_TEXT_LENGTH = 160

NOWPLAYING_PREFIX_URL = "https://music.abcradio.net.au/api/v1/plays/"
NOWPLAYING_SUFFIX_URL = "/now.json"
STATIONS = {
    "triplej": ["Triple J", "#e63228"],
    "doublej": ["Double J", "#000"],
    "h100": ["Hottest 100", "#e17800"],
    "classic": ["ABC Classic", "#0e6598"],
    "classic2": ["ABC Classic 2", "#5b7e81"],
    "jazz": ["ABC Jazz", "#015888"],
    "country": ["ABC Country", "#08686e"],
}

def main(config):
    station = config.get("station", "triplej")
    if station not in STATIONS:
        station = "triplej"

    now_playing_url = NOWPLAYING_PREFIX_URL + station + NOWPLAYING_SUFFIX_URL
    music = get_data(now_playing_url)
    recording = music.get("now") or music.get("prev") or {}
    recording = recording.get("recording") if type(recording) == "dict" else None
    artists = recording.get("artists") if type(recording) == "dict" else None
    title = recording.get("title") if type(recording) == "dict" else None
    artist = artists[0].get("name") if type(artists) == "list" and len(artists) > 0 and type(artists[0]) == "dict" else None
    if type(title) != "string" or type(artist) != "string":
        return render_error("Nothing playing")

    station_title = STATIONS[station]

    return render.Root(
        delay = 75,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    padding = 0,
                    color = station_title[1],
                    child = render.Text(content = station_title[0], color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 8,
                    padding = 0,
                    color = "#000",
                    child = render.Text("NOW PLAYING...", color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = title[:MAX_TEXT_LENGTH], color = "#42f545", font = "CG-pixel-3x5-mono"),
                ),
                render.Box(
                    width = 64,
                    height = 3,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = artist[:MAX_TEXT_LENGTH], color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Choose your station",
                desc = "Choose the station",
                icon = "radio",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
        ],
    )

def get_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TIMEOUT)
    body = res.body()
    if res.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return {}
    decoded = json.decode(body, None)
    return decoded if type(decoded) == "dict" else {}

def render_error(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("ABC RADIO", color = "#e63228", font = "CG-pixel-4x5-mono"),
                render.WrappedText(message, color = "#fff", font = "tom-thumb", width = 60, align = "center"),
            ],
        ),
    )

StationOptions = [
    schema.Option(
        display = "Triple J",
        value = "triplej",
    ),
    schema.Option(
        display = "Double J",
        value = "doublej",
    ),
    schema.Option(
        display = "Hottest 100",
        value = "h100",
    ),
    schema.Option(
        display = "Classic",
        value = "classic",
    ),
    schema.Option(
        display = "Classic 2",
        value = "classic2",
    ),
    schema.Option(
        display = "Jazz",
        value = "jazz",
    ),
    schema.Option(
        display = "Country",
        value = "country",
    ),
]
