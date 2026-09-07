"""
Applet: Armageddon Trackr
Summary: Closest Near Earth Object
Description: Provides information from NASA about the nearest Near Earth Object on a given date.
Author: flynnt
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/dino.png", DINO_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DINO = DINO_ASSET.readall()

BASE_URL = "https://api.nasa.gov/neo/rest/v1/feed"
DEFAULT_UNIT = "miles"
TERMINAL_TEXT_COLOR = "#33ff00"
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_NEOS = 100

def main(config):
    """
    App entrypoint.
    Retrieves the nearest earth objects from the NASA NeoWS.
    Returns rendered application root.
    """
    api_key = config.get("api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return render.Root(
            child = render_static_dino(),
        )
    else:
        unit = config.get("distance_key", DEFAULT_UNIT)
        if unit not in ["miles", "kilometers"]:
            unit = DEFAULT_UNIT
        now = time.now()
        pretty_now = now.format("January 2, 2006")
        query_now = now.format("2006-01-02")

        neos = get_neos(query_now, api_key, unit)
        if not neos:
            return render.Root(
                child = render.Box(
                    render.WrappedText("No asteroids today!", color = TERMINAL_TEXT_COLOR),
                ),
            )

        nearest_distance = get_shortest_distance(neos)
        nearest_neo = get_nearest_neo(neos, nearest_distance)
        pretty_distance = humanize.comma(int(nearest_distance))

        date_string = "On {}".format(pretty_now)
        asteroid_string = "Asteroid: \n {}".format(nearest_neo["name"][:80])
        pre_proximity_string = "Will miss the Earth by..."
        distance_string = unit
        proximity_string = "{} \n {}".format(pretty_distance, distance_string)

        static_dino = [
            render_static_dino()
            for frame in range(30)
        ]

        return render.Root(
            delay = 90,
            show_full_animation = bool(1),
            child = render.Row(
                children = [
                    render.Box(
                        width = 64,
                        child = render.Sequence(
                            children = [
                                render.Animation(generate_string_segments(date_string)),
                                render.Animation(generate_static_string_frames(date_string, 10)),
                                render.Animation(generate_string_segments(asteroid_string)),
                                render.Animation(generate_static_string_frames(asteroid_string, 10)),
                                render.Animation(generate_string_segments(pre_proximity_string)),
                                render.Animation(generate_static_string_frames(pre_proximity_string, 10)),
                                render.Animation(generate_string_segments(proximity_string)),
                                render.Animation(generate_static_string_frames(proximity_string, 10)),
                                animation.Transformation(
                                    child = render.Row(
                                        expanded = bool(1),
                                        cross_align = "end",
                                        main_align = "end",
                                        children = [
                                            render.Box(
                                                height = 32,
                                                width = 34,
                                                child = render.WrappedText("", font = "tom-thumb"),
                                            ),
                                            render.Box(
                                                height = 26,
                                                width = 28,
                                                child = render.Image(DINO),
                                            ),
                                        ],
                                    ),
                                    duration = 8,
                                    keyframes = [
                                        animation.Keyframe(
                                            percentage = 0.0,
                                            transforms = [animation.Translate(0, 32)],
                                            curve = "ease_out",
                                        ),
                                        animation.Keyframe(
                                            percentage = 1.0,
                                            transforms = [animation.Translate(0, 0)],
                                            curve = "ease_out",
                                        ),
                                    ],
                                ),
                                render.Animation(static_dino),
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
                id = "api_key",
                name = "NASA API Key",
                desc = "Your NASA API key. See https://api.nasa.gov/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "distance_key",
                name = "Distance Unit",
                desc = "Unit to use when displaying distances.",
                icon = "gear",
                default = DEFAULT_UNIT,
                options = [
                    schema.Option(
                        display = "Miles",
                        value = "miles",
                    ),
                    schema.Option(
                        display = "Kilometers",
                        value = "kilometers",
                    ),
                ],
            ),
        ],
    )

def get_neos(query_now, api_key, unit):
    params = {
        "api_key": api_key,
        "start_date": query_now,
        "end_date": query_now,
    }
    req = http.get(BASE_URL, params = params)
    if req.status_code != 200:
        return []

    body = req.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    if type(data) != "dict" or not data.get("element_count"):
        return []

    near_earth_objects = data.get("near_earth_objects", {})
    raw_neos = near_earth_objects.get(query_now, []) if type(near_earth_objects) == "dict" else []
    if type(raw_neos) != "list":
        return []

    neos = []
    for neo in raw_neos[:MAX_NEOS]:
        approaches = neo.get("close_approach_data", []) if type(neo) == "dict" else []
        approach = approaches[0] if type(approaches) == "list" and approaches and type(approaches[0]) == "dict" else {}
        distances = approach.get("miss_distance", {}) if type(approach) == "dict" else {}
        raw_distance = distances.get(unit) if type(distances) == "dict" else None
        name = neo.get("name") if type(neo) == "dict" else None
        if type(name) == "string" and name and valid_distance(raw_distance):
            neos.append({"name": name, "distance": float(raw_distance)})
    return neos

def valid_distance(value):
    return value != None and re.match(r"^[0-9]+(?:\.[0-9]+)?$", str(value)) != None

def get_nearest_neo(neos, nearest_distance):
    for neo in neos:
        if neo["distance"] == nearest_distance:
            return neo
    return None

def get_shortest_distance(neos):
    return min(*[neo["distance"] for neo in neos])

def generate_static_string_frames(string, duration):
    frames = []
    for _ in range(duration):
        frames.append(render_character(string, color = TERMINAL_TEXT_COLOR))

    return frames

def generate_string_segments(string):
    segments = []
    for i, _ in enumerate(string.elems()):
        segments.append(render_character(string[:i + 1], color = TERMINAL_TEXT_COLOR))

    return segments

def render_character(string, color):
    return render.WrappedText(string, color = color)

def render_static_dino():
    return render.Row(
        cross_align = "end",
        main_align = "space_between",
        expanded = bool(1),
        children = [
            render.Box(
                height = 32,
                width = 34,
                child = render.WrappedText("This is fine.", font = "tom-thumb"),
            ),
            render.Box(
                height = 26,
                width = 28,
                child = render.Image(DINO),
            ),
        ],
    )
