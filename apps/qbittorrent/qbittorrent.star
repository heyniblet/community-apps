"""
Applet: Qbittorrent
Summary: Monitor your torrent server
Description: Displays server stats (speeds and active counts) along with the progress of your newest torrents.
Author: DoubleGremlin181
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEVICE_WIDTH = 64
DEVICE_HEIGHT = 32
HEADER_HEIGHT = 8
ROW_HEIGHT = 12
DELAY_MS = 60
MAX_RESPONSE_BYTES = 2 * 1024 * 1024

def main(config):
    servername = config.str("servername", "My Seedbox")[:80]
    base_url = config.str("base_url", "")
    username = config.str("username", "")
    password = config.str("password", "")
    category = config.str("category", "")

    if not category:
        category = ""
    else:
        category = "&category={}".format(humanize.url_encode(category))

    torrent_count_raw = config.get("torrent_count", "1")
    torrent_count = int(torrent_count_raw) if str(torrent_count_raw).isdigit() else 1
    torrent_count = min(3, max(0, torrent_count))
    if not valid_base_url(base_url) or not username or not password:
        return render_header(servername, [render.WrappedText(content = "Enter server details")])

    else:
        base_url = base_url.rstrip("/")
        sid = server_login(base_url, username, password)

        if not sid:
            return render_header(servername, [render.WrappedText(content = "Login failed :(")])
        else:
            speeds = get_transfer_speeds(base_url, sid)
            active_counts = get_active_torrents(base_url, category, sid)

            if (torrent_count > 0):
                torrents = get_latest_torrents(base_url, category, sid, torrent_count)
                if not speeds or not active_counts or torrents == None:
                    return render_header(servername, [render.WrappedText(content = "Failed to get data")])
            else:
                torrents = None

            # Get pages frames for the list of torrents.
            pages = [[get_stats_frame(speeds, active_counts)] * 30]

            if (torrents):
                pages += [get_page_frames(t) for t in torrents]
            if not pages:
                return []

            # Generate the list of frames to render.
            frames = []
            if len(pages) > 1:
                # Multiple pages to show, yay!
                for i, page_frames in enumerate(pages):
                    next_page_frames = pages[(i + 1) % len(pages)]
                    frames.extend(page_frames)
                    frames.extend(get_scroll_frames(page_frames[0], next_page_frames[0]))
            else:
                # Just one page, but that's okay.
                frames.extend(pages[0])

            # Render the list of frames as an aniamtion.
            return render_header(servername, frames)

def server_login(base_url, username, password):
    form_body = dict(
        username = username,
        password = password,
    )

    # Login to the server and return the session ID
    url = "{}/api/v2/auth/login".format(base_url)
    origin = base_url.split("/")[0] + "//" + base_url.split("/")[2]
    headers = {"Origin": origin, "Referer": base_url + "/"}
    response = http.post(url, form_body = form_body, headers = headers)
    if response.status_code != 200 or response.body() != "Ok.":
        return None
    cookie = response.headers.get("Set-Cookie", "")
    for part in cookie.split(";"):
        part = part.strip()
        if part.startswith("SID=") and len(part) > 4 and len(part) <= 260:
            return part[4:]
    return None

def get_transfer_speeds(base_url, sid):
    url = "{}/api/v2/transfer/info".format(base_url)
    headers = {"Cookie": "SID={}".format(sid)}
    data = get_json(url, headers)
    if type(data) != "dict":
        return None
    download_speed = number(data.get("dl_info_speed"))
    upload_speed = number(data.get("up_info_speed"))
    return {
        "download_speed": speed_to_human(download_speed),
        "upload_speed": speed_to_human(upload_speed),
    }

def get_active_torrents(base_url, category, sid):
    url = "{}/api/v2/torrents/info?filter=active{}".format(base_url, category)
    headers = {"Cookie": "SID={}".format(sid)}
    data = get_json(url, headers)
    if type(data) != "list":
        return None
    progress = [number(torrent.get("progress")) for torrent in data if type(torrent) == "dict"]
    return {
        "active_torrents": len(progress),
        "active_downloads": len([value for value in progress if value < 1]),
        "active_uploads": len([value for value in progress if value >= 1]),
    }

def get_latest_torrents(base_url, category, sid, torrent_count):
    url = "{}/api/v2/torrents/info?limit={}&sort=added_on&reverse=true{}".format(base_url, torrent_count, category)  # Get the latest torrents
    headers = {"Cookie": "SID={}".format(sid)}
    data = get_json(url, headers)
    if type(data) != "list":
        return None
    torrents = []
    for torrent in data[:torrent_count]:
        if type(torrent) != "dict":
            continue
        name = torrent.get("name", "")
        if type(name) != "string":
            continue
        torrents.append({
            "name": name[:128],
            "progress": min(1, max(0, number(torrent.get("progress")))),
            "download_speed": speed_to_human(number(torrent.get("dlspeed")), 0),
            "upload_speed": speed_to_human(number(torrent.get("upspeed")), 0),
        })
    return torrents

def get_json(url, headers):
    response = http.get(url, headers = headers)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    return json.decode(body, None)

def number(value):
    return max(0, value) if type(value) in ["int", "float"] else 0

def valid_base_url(value):
    parts = value.split("/")
    return type(value) == "string" and (value.startswith("https://") or value.startswith("http://")) and len(parts) >= 3 and parts[2] != "" and "@" not in value and "?" not in value and "#" not in value and "\\" not in value and " " not in value and "\n" not in value and "\r" not in value

def speed_to_human(speed, precision = 2):
    if speed < 1024:
        return "{}B/s".format(round(speed, precision))
    elif speed < 1024 * 1024:
        return "{}KB/s".format(round(speed / 1024, precision))
    elif speed < 1024 * 1024 * 1024:
        return "{}MB/s".format(round(speed / (1024 * 1024), precision))
    else:
        return "{}GB/s".format(round(speed / (1024 * 1024 * 1024), precision))

def round(num, precision):
    if precision == 0:
        return int(num)
    else:
        return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def get_stats_frame(speeds, active_counts):
    return render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_bewteen",
            cross_align = "start",
            children = [
                render.Box(
                    height = ROW_HEIGHT,
                    child = render.Row(main_align = "start", children = [
                        render.Box(width = 1),
                        render.Text("↓ ", color = "#00FF00"),
                        render.Column(children = [
                            render.Box(height = 1),  # Aligning tom-thumb font with tb-8
                            render.Row(children = [
                                render.Text("{}".format(speeds["download_speed"]), font = "tom-thumb"),
                                render.Text("({})".format(active_counts["active_downloads"]), font = "tom-thumb"),
                            ]),
                        ]),
                    ]),
                ),
                render.Box(
                    height = ROW_HEIGHT,
                    child = render.Row(main_align = "start", children = [
                        render.Box(width = 1),
                        render.Text("↑ ", color = "#FF0000"),
                        render.Column(children = [
                            render.Box(height = 1),  # Aligning tom-thumb font with tb-8
                            render.Row(children = [
                                render.Text("{}".format(speeds["upload_speed"]), font = "tom-thumb"),
                                render.Text("({})".format(active_counts["active_uploads"]), font = "tom-thumb"),
                            ]),
                        ]),
                    ]),
                ),
            ],
        ),
        height = DEVICE_HEIGHT,
    )

def get_page_frames(torrent):
    # This function is derived from a similar function in the
    # USGS Earthquakes Applet by Chris Silverberg (csilv).
    # https://github.com/tidbyt/community/blob/main/apps/usgsearthquakes/usgs_earthquakes.star

    name_str = torrent["name"]
    dw_speed = torrent["download_speed"]
    up_speed = torrent["upload_speed"]

    # Get the length of the place string.
    name_len = render.Text(name_str).size()[0]

    # Generate the pie chart segments.
    download_percent = torrent["progress"] * 100

    # Rotating the pie chart to start from the top
    if download_percent <= 25:
        pie_segments = [0, 75, download_percent, 25 - download_percent]
    else:
        pie_segments = [download_percent - 25, 100 - download_percent, 25, 0]

    if name_len > DEVICE_WIDTH:
        # Place string requires scrolling, so generate the first set of frames.
        frames_a = [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments)
            for place_x in range(0, -name_len, -1)
        ]

        # Followup with the next set of frames.
        frames_b = [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments)
            for place_x in range(DEVICE_WIDTH, -1, -1)
        ]

        # Return the combination.
        return frames_a + frames_b

    else:
        place_x = int((DEVICE_WIDTH - name_len) / 2)
        return [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments),
        ] * DEVICE_WIDTH

def get_page_frame(name_str, name_x, dw_speed, up_speed, pie_segments):
    # This function is derived from a similar function in the
    # USGS Earthquakes Applet by Chris Silverberg (csilv).
    # https://github.com/tidbyt/community/blob/main/apps/usgsearthquakes/usgs_earthquakes.star

    return render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_bewteen",
            cross_align = "start",
            children = [
                render.Box(
                    render.Row(children = [
                        render.Box(width = 1),
                        render.PieChart(weights = pie_segments, colors = ["#51CB20", "#808080"], diameter = 8),
                        render.Box(width = 1),
                        render.Box(
                            child = animation.AnimatedPositioned(
                                child = render.Text(name_str),
                                curve = "linear",
                                duration = 0,
                                x_start = name_x,
                                x_end = name_x,
                            ),
                        ),
                    ]),
                    width = DEVICE_WIDTH,
                    height = ROW_HEIGHT - 2,
                ),
                render.Box(render.Row(
                    children = [
                        render.Text(content = dw_speed, color = "#51CB20", font = "tom-thumb"),
                        render.Text(content = up_speed, color = "#E3170A", font = "tom-thumb"),
                    ],
                    expanded = True,
                    main_align = "space_around",
                ), height = ROW_HEIGHT),
            ],
        ),
        height = DEVICE_HEIGHT,
    )

def get_scroll_frames(item, next_item):
    # This function is derived from a similar function in the
    # BGG Hotness Applet by Henry So, Jr.
    # https://github.com/tidbyt/community/tree/main/apps/bgghotness
    return [
        render.Padding(
            pad = (0, offset, 0, 0),
            child = render.Stack([
                item,
                render.Padding(
                    pad = (0, DEVICE_HEIGHT, 0, 0),
                    child = next_item,
                ),
            ]),
        )
        for offset in range(-1, -DEVICE_HEIGHT - 1, -1)
    ]

def render_header(servername, frames):
    return render.Root(
        child = render.Column(children = [
            render.Box(
                height = HEADER_HEIGHT,
                width = DEVICE_WIDTH,
                color = "#004080",
                child = render.Text(servername),
            ),
            render.Box(height = 2, width = DEVICE_WIDTH),
            render.Animation(frames),
        ]),
        delay = DELAY_MS,
        show_full_animation = True,
    )

def get_schema():
    options = [
        schema.Option(
            display = "0",
            value = "0",
        ),
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "servername",
                name = "Server Name",
                desc = "The name of your server",
                icon = "font",
            ),
            schema.Text(
                id = "base_url",
                name = "Server Host or IP",
                desc = "The URL of your server",
                icon = "server",
            ),
            schema.Text(
                id = "username",
                name = "Username",
                desc = "qBittorrent username",
                icon = "user",
            ),
            schema.Text(
                id = "password",
                name = "Password",
                desc = "qBittorrent password",
                icon = "lock",
                secret = True,
            ),
            schema.Text(
                id = "category",
                name = "Category",
                desc = "Category to return, leave blank for all categories",
                icon = "list",
            ),
            schema.Dropdown(
                id = "torrent_count",
                name = "Torrent count",
                desc = "Number of torrents to show",
                icon = "listOl",
                default = options[1].value,
                options = options,
            ),
        ],
    )
