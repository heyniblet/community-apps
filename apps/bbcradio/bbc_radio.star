"""
Applet: BBC Radio
Summary: What's live now on the BBC
Description: Shows what programme is currently being broadcast on each of the BBC's radio stations.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STATIONS_URL = "https://www.bbc.co.uk/sounds/stations"
USER_AGENT = "https://github.com/heyniblet/community-apps/tree/niblet/portable-fixes-2026-09-04/apps/bbcradio"
TIMEZONE = "Europe/London"
RADIO_4 = "bbc_radio_four"
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_TEXT_LENGTH = 240
FONT = "tom-thumb"
GREEN = "#22ff7b"
ORANGE = "#ff7b22"
PURPLE = "#7b22ff"
LIGHT_GREY = "#b0b2b4"
DARK_GREY = "#3a3c3e"

STATIONS = [
    ["Radio 1", "bbc_radio_one"],
    ["Radio 1 Anthems", "bbc_radio_one_anthems"],
    ["Radio 1 Dance", "bbc_radio_one_dance"],
    ["Radio 1Xtra", "bbc_1xtra"],
    ["Radio 2", "bbc_radio_two"],
    ["Radio 3", "bbc_radio_three"],
    ["Radio 3 Unwind", "bbc_radio_three_unwind"],
    ["Radio 4", "bbc_radio_four"],
    ["Radio 4 Extra", "bbc_radio_four_extra"],
    ["Radio 5 Live", "bbc_radio_five_live"],
    ["Radio 5 Sports Extra", "bbc_radio_five_live_sports_extra"],
    ["Radio 5 Sports Extra 2", "bbc_radio_five_sports_extra_2"],
    ["Radio 5 Sports Extra 3", "bbc_radio_five_sports_extra_3"],
    ["Radio 6 Music", "bbc_6music"],
    ["Radio 6 Indie Forever", "bbc_radio_six_indie_forever"],
    ["Asian Network", "bbc_asian_network"],
    ["World Service", "bbc_world_service"],
    ["Live News", "bbc_sounds_news"],
    ["Radio Scotland", "bbc_radio_scotland"],
    ["Radio Scotland Extra", "bbc_radio_scotland_mw"],
    ["Radio Orkney", "bbc_radio_orkney"],
    ["Radio Shetland", "bbc_radio_shetland"],
    ["Radio nan Gàidheal", "bbc_radio_nan_gaidheal"],
    ["Radio Ulster", "bbc_radio_ulster"],
    ["Radio Foyle", "bbc_radio_foyle"],
    ["Radio Wales", "bbc_radio_wales"],
    ["Radio Wales Extra", "bbc_radio_wales_am"],
    ["Radio Cymru", "bbc_radio_cymru"],
    ["Radio Cymru 2", "bbc_radio_cymru_2"],
    ["CBeebies Radio", "cbeebies_radio"],
    ["Radio Berkshire", "bbc_radio_berkshire"],
    ["Radio Bristol", "bbc_radio_bristol"],
    ["Radio Cambridgeshire", "bbc_radio_cambridge"],
    ["Radio Cornwall", "bbc_radio_cornwall"],
    ["CWR", "bbc_radio_coventry_warwickshire"],
    ["Radio Cumbria", "bbc_radio_cumbria"],
    ["Radio Derby", "bbc_radio_derby"],
    ["Radio Devon", "bbc_radio_devon"],
    ["Essex", "bbc_radio_essex"],
    ["Radio Gloucestershire", "bbc_radio_gloucestershire"],
    ["Radio Guernsey", "bbc_radio_guernsey"],
    ["Hereford & Worcester", "bbc_radio_hereford_worcester"],
    ["Radio Humberside", "bbc_radio_humberside"],
    ["Radio Jersey", "bbc_radio_jersey"],
    ["Radio Kent", "bbc_radio_kent"],
    ["Radio Lancashire", "bbc_radio_lancashire"],
    ["Radio Leeds", "bbc_radio_leeds"],
    ["Radio Leicester", "bbc_radio_leicester"],
    ["Radio Lincolnshire", "bbc_radio_lincolnshire"],
    ["Radio London", "bbc_london"],
    ["Radio Manchester", "bbc_radio_manchester"],
    ["Radio Merseyside", "bbc_radio_merseyside"],
    ["Radio Newcastle", "bbc_radio_newcastle"],
    ["Radio Norfolk", "bbc_radio_norfolk"],
    ["Radio Northampton", "bbc_radio_northampton"],
    ["Radio Nottingham", "bbc_radio_nottingham"],
    ["Radio Oxford", "bbc_radio_oxford"],
    ["Radio Sheffield", "bbc_radio_sheffield"],
    ["Radio Shropshire", "bbc_radio_shropshire"],
    ["Radio Solent", "bbc_radio_solent"],
    ["Radio Solent Dorset", "bbc_radio_solent_west_dorset"],
    ["Radio Somerset", "bbc_radio_somerset_sound"],
    ["Radio Stoke", "bbc_radio_stoke"],
    ["Radio Suffolk", "bbc_radio_suffolk"],
    ["Radio Surrey", "bbc_radio_surrey"],
    ["Radio Sussex", "bbc_radio_sussex"],
    ["Radio Tees", "bbc_tees"],
    ["Three Counties Radio", "bbc_three_counties_radio"],
    ["Radio Wiltshire", "bbc_radio_wiltshire"],
    ["Radio WM", "bbc_wm"],
    ["Radio York", "bbc_radio_york"],
]

def extract_station(station):
    if type(station) != "dict":
        return None
    result = {}
    network = station.get("network")
    if type(network) == "dict":
        station_id = network.get("id")
        if type(station_id) != "string" or not station_id or len(station_id) > 120:
            return None
        result["id"] = station_id

        name = network.get("short_title")
        if type(name) != "string" or not name:
            return None
        result["name"] = name[:MAX_TEXT_LENGTH]
    else:
        return None

    titles = station.get("titles")
    if type(titles) == "dict":
        programme = titles.get("primary")
        if type(programme) == "string" and programme:
            result["programme"] = programme[:MAX_TEXT_LENGTH]

        timing = titles.get("secondary")
        if type(timing) == "string" and timing:
            result["timing"] = timing[:80]

    synopses = station.get("synopses")
    if type(synopses) == "dict":
        synopsis = synopses.get("short")
        if type(synopsis) == "string" and synopsis:
            result["synopsis"] = synopsis[:MAX_TEXT_LENGTH]
    return result

def extract_stations(module):
    raw = module.get("data") if type(module) == "dict" else None
    if type(raw) != "list":
        return {}
    stations = [extract_station(s) for s in raw if s]
    return {s["id"]: s for s in stations if s}

def load_stations():
    resp = http.get(
        url = STATIONS_URL,
        headers = {
            "User-Agent": USER_AGENT,
        },
        ttl_seconds = 60,
    )
    if resp.status_code != 200:
        return {}, {}
    body = resp.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return {}, {}
    page = html(body)
    script = page.find("script#__NEXT_DATA__")
    if not script:
        return {}, {}

    raw = json.decode(script.text())
    props = raw.get("props") if type(raw) == "dict" else None
    page_props = props.get("pageProps") if type(props) == "dict" else None
    dehydrated = page_props.get("dehydratedState") if type(page_props) == "dict" else None
    queries = dehydrated.get("queries") if type(dehydrated) == "dict" else None
    first_query = queries[0] if type(queries) == "list" and len(queries) > 0 and type(queries[0]) == "dict" else None
    state = first_query.get("state") if type(first_query) == "dict" else None
    state_data = state.get("data") if type(state) == "dict" else None
    modules = state_data.get("data") if type(state_data) == "dict" else None
    if type(modules) != "list" or len(modules) < 2:
        return {}, {}

    return extract_stations(modules[0]), extract_stations(modules[1])

def render_station(station):
    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Marquee(
            width = 62,
            height = 6,
            scroll_direction = "horizontal",
            align = "center",
            child = render.Text(
                content = station["name"],
                font = FONT,
                color = LIGHT_GREY,
            ),
        ),
    )

def render_program(station, show_synopsis, colour):
    title = station.get("programme", "No programme info")
    synopsis = station.get("synopsis", "No synopsis info")
    timing = station.get("timing", "No timing info")
    if show_synopsis:
        content = title + " - " + synopsis
    else:
        content = title
    return render.Padding(
        pad = (1, 8, 1, 0),
        child = render.Column(
            children = [
                render.Marquee(
                    width = 62,
                    height = 14,
                    scroll_direction = "vertical",
                    align = "center",
                    child = render.WrappedText(
                        content = content,
                        width = 62,
                        font = FONT,
                        align = "center",
                        color = colour,
                    ),
                ),
                render.Box(
                    height = 2,
                    width = 1,
                ),
                render.WrappedText(
                    content = timing,
                    font = FONT,
                    color = LIGHT_GREY,
                    width = 62,
                    align = "center",
                ),
            ],
        ),
    )

def render_progress_bar(station, colour):
    # Can't trust the "progress" field in the API response to be up to date.
    timing = station.get("timing")
    parts = timing.split(" ") if type(timing) == "string" else []
    start_parts = parts[0].split(":") if len(parts) == 3 else []
    end_parts = parts[2].split(":") if len(parts) == 3 else []
    start_hour = 0
    start_min = 0
    end_hour = 0
    end_min = 0
    valid_time = len(start_parts) == 2 and len(end_parts) == 2 and all([part.isdigit() for part in start_parts + end_parts])
    if valid_time:
        start_hour, start_min = [int(x) for x in start_parts]
        end_hour, end_min = [int(x) for x in end_parts]
        valid_time = start_hour < 24 and end_hour < 24 and start_min < 60 and end_min < 60
    if valid_time:
        now = time.now().in_location(TIMEZONE)
        begin = time.time(year = now.year, month = now.month, day = now.day, hour = start_hour, minute = start_min, location = TIMEZONE)
        finish = time.time(year = now.year, month = now.month, day = now.day, hour = end_hour, minute = end_min, location = TIMEZONE)
        if finish < begin:
            finish += 24 * time.hour  # Wrap past midnight
        duration = finish - begin
        elapsed = now - begin
        progress = max(0, min(64, int(64.0 * (elapsed / duration)))) if finish != begin else 0
    else:
        progress = 0
    return render.Padding(
        pad = (0, 30, 0, 0),
        child = render.Row(
            children = [
                render.Box(
                    width = progress,
                    height = 2,
                    color = colour,
                ),
                render.Box(
                    width = 64 - progress,
                    height = 2,
                    color = DARK_GREY,
                ),
            ],
        ),
    )

def main(config):
    station = config.get("station", RADIO_4)
    colour = config.get("colour", GREEN)
    show_synopsis = config.bool("show_synopsis", False)
    national, local = load_stations()
    stations = dict(national, **local)
    station = stations.get(station) or stations.get(RADIO_4)
    if station == None:
        return render.Root(child = render.Text("BBC unavailable", color = LIGHT_GREY, font = FONT))

    return render.Root(
        child = render.Stack(
            children = [
                render_station(station),
                render_program(station, show_synopsis, colour),
                render_progress_bar(station, colour),
            ],
        ),
    )

def get_schema():
    stations = [
        schema.Option(display = station[0], value = station[1])
        for station in STATIONS
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Which BBC radio station to show",
                icon = "radio",
                options = stations,
                default = RADIO_4,
            ),
            schema.Toggle(
                id = "show_synopsis",
                name = "Show synopsis",
                desc = "Show more info about programme",
                icon = "info",
                default = False,
            ),
            schema.Color(
                id = "colour",
                name = "Colour",
                desc = "Colour for programme info",
                icon = "brush",
                default = GREEN,
                palette = [
                    GREEN,
                    ORANGE,
                    PURPLE,
                    LIGHT_GREY,
                ],
            ),
        ],
    )
