"""
Applet: WFMU
Summary: WFMU Now Playing
Description: Displays what's currently playing on the WFMU radio station. WFMU-FM 91.1/Jersey City, NJ; 90.1/Hudson Valley.
Author: Tom O'Dea
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/wfmu_logo.png", WFMU_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

WFMU_LOGO = WFMU_LOGO_ASSET.readall()

DEFAULT_COLOR = "#6699FF"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Color of the song title.",
                icon = "brush",
                default = DEFAULT_COLOR,
                palette = [
                    DEFAULT_COLOR,
                    "#FFFFFF",
                    "#FF00FF",
                    "#33FFFF",
                    "#00FF00",
                    "#FF6600",
                    "#FF0000",
                    "#FFFF00",
                ],
            ),
        ],
    )

WFMU_NOW_PLAYING_URL = "https://wfmu.org/wp-content/themes/wfmu-theme/library/php/includes/liveNow.php"

def api_error():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = WFMU_LOGO, width = 64),
                render.Text("No Connection", font = "tb-8", color = "#CC0000"),
            ],
        ),
    )

def main(config):
    color = config.str("color", DEFAULT_COLOR)
    rep = http.get(WFMU_NOW_PLAYING_URL, ttl_seconds = 30)
    if rep.status_code != 200:
        return api_error()

    body = rep.body()
    data = json.decode(body, {}) if body and len(body) <= 256 * 1024 else {}
    if type(data) != "dict":
        return api_error()
    song = str(data.get("song") or "")[:200]
    show = str(data.get("show") or "")[:200]

    # if song is empty, display the show name instead
    if song:
        now_playing = song
    else:
        now_playing = show
        show = ""

    return render.Root(
        child = render.Column(
            children = [
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 14,
                            color = "#000",
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 22,
                            child = render.Text(now_playing, color = color, font = "6x13"),
                        ),
                    ],
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    color = "#000",
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 8,
                            color = "#000",
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            delay = 22,
                            child = render.Text(show, color = "#999", font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#333",
                        ),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#000",
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 64,
                    child = render.Text("WFMU.ORG  91.1FM", color = "#666", font = "tom-thumb"),
                ),
            ],
        ),
    )
