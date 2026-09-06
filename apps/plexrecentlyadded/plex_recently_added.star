"""
Applet: Plex Recently Added
Summary: Display Plex recently added
Description: Displays recently added media from a public HTTPS Plex or proxy endpoint.
Author: noahpodgurski
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/plex_icon.png", PLEX_ICON_ASSET = "file")
load("images/sample1.jpg", SAMPLE1_ASSET = "file")
load("images/sample2.jpg", SAMPLE2_ASSET = "file")
load("images/sample3.jpg", SAMPLE3_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_TIME = 3600

SAMPLE_DATA = {
    "MediaContainer": {
        "Metadata": [
            {
                "title": "Aquaman",
                "contentRating": "PG-13",
            },
            {
                "title": "A Walk to Remember",
                "titleSort": "Walk to Remember",
                "contentRating": "PG",
            },
            {
                "title": "Enemy at the Gates",
                "contentRating": "R",
            },
        ],
    },
}

SAMPLE_IMAGES = [
    SAMPLE1_ASSET,
    SAMPLE2_ASSET,
    SAMPLE3_ASSET,
]

def request_headers(plexToken, apiKey):
    headers = {
        "Accept": "application/json",
        "X-Plex-Token": plexToken,
        "X-Plex-Client-Identifier": "niblet-plex-recently-added",
    }
    if apiKey:
        headers["x-api-key"] = apiKey
    return headers

def server_url(serverIP, serverPort):
    serverIP = serverIP or ""
    serverPort = serverPort or ""
    serverIP = serverIP.strip().rstrip("/")
    if not serverIP or " " in serverIP or "\t" in serverIP or "\n" in serverIP or "@" in serverIP:
        return None
    if serverIP.startswith("http://"):
        return None
    if serverIP.startswith("https://"):
        return serverIP
    if "/" in serverIP or not serverPort.isdigit() or int(serverPort) < 1 or int(serverPort) > 65535:
        return None
    return "https://%s:%s" % (serverIP, serverPort)

def requestStatus(base_url, plexToken, apiKey):
    res = http.get(
        base_url + "/library/recentlyAdded",
        headers = request_headers(plexToken, apiKey),
        ttl_seconds = REFRESH_TIME,
    )
    body = res.body().strip()
    if res.status_code != 200 or len(body) > 2097152 or not body.startswith("{") or not body.endswith("}"):
        print("Plex library request failed with status %d" % res.status_code)
        return None
    data = res.json()
    return data if type(data) == "dict" else None

def requestThumb(base_url, plexToken, apiKey, thumbnailURL):
    if type(thumbnailURL) != "string" or not thumbnailURL.startswith("/") or thumbnailURL.startswith("//"):
        return None
    res = http.get(
        base_url + thumbnailURL,
        headers = request_headers(plexToken, apiKey),
        ttl_seconds = REFRESH_TIME,
    )
    body = res.body()
    if res.status_code != 200 or len(body) > 4194304:
        print("Plex thumbnail request failed with status %d" % res.status_code)
        return None
    return body

def main(config):
    usingSampleData = False
    serverIP = config.str("serverIP")
    serverPort = config.str("serverPort")
    plexToken = config.str("plexToken")
    apiKey = config.str("apiKey", "")
    showTitleCard = config.bool("showTitleCard", True)
    title = ""

    base_url = server_url(serverIP, serverPort)
    if not serverIP:
        usingSampleData = True
        print("Using sample data")
    elif not base_url or not plexToken:
        return render_message("Use HTTPS and add your Plex token")

    if usingSampleData:
        # have to do it this weird way to dodge frozen hash table error
        newData = {}
        newData["MediaContainer"] = {}
        newData["MediaContainer"]["Metadata"] = []
        for i in range(0, 3):
            newData["MediaContainer"]["Metadata"].append({})
            newData["MediaContainer"]["Metadata"][i]["title"] = SAMPLE_DATA["MediaContainer"]["Metadata"][i]["title"]
            newData["MediaContainer"]["Metadata"][i]["thumb"] = SAMPLE_IMAGES[i].readall()
            title = newData["MediaContainer"]["Metadata"][i]["title"]
        data = newData
    else:
        data = requestStatus(base_url, plexToken, apiKey)
        if not data:
            return render_message("Plex is unavailable")

    recentlyAdded = []

    # Only show up to 3 of the most recently added items.
    # Each item adds 2 elements to `recentlyAdded`, so we break when the length is 6.
    container = data.get("MediaContainer", {})
    metadata = container.get("Metadata", []) if type(container) == "dict" else []
    for entry in metadata if type(metadata) == "list" else []:
        if len(recentlyAdded) >= 6:
            break
        if type(entry) != "dict":
            continue

        thumbnailURL = entry.get("parentThumb") or entry.get("thumb") or entry.get("grandparentThumb") or entry.get("art")
        if not thumbnailURL:
            continue

        title = entry.get("parentTitle") or entry.get("title", "Unknown")
        title = title[:120] if type(title) == "string" else "Unknown"

        if not usingSampleData:
            thumbnail = requestThumb(base_url, plexToken, apiKey, thumbnailURL)
        else:
            thumbnail = thumbnailURL
        if not thumbnail:
            continue

        recentlyAdded.append(
            render.Column(
                children = [
                    render.Image(src = thumbnail, width = 21, height = 27),
                    render.Marquee(
                        width = 21,
                        offset_start = 60 if showTitleCard else 0,  #offset to wait to slide in
                        child = render.Text(title, font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        )
        recentlyAdded.append(
            render.Box(height = 32, width = 1, color = "#EFAF08"),
        )

    if not recentlyAdded:
        return render_message("Nothing recently added")
    if showTitleCard:
        return render.Root(
            render.Stack(
                children = [
                    animation.Transformation(
                        child = render.Column(
                            children = [
                                render.Box(height = 1, width = 64, color = "#EFAF08"),
                                render.Box(
                                    width = 64,
                                    height = 30,
                                    child = render.Row(
                                        main_align = "center",
                                        cross_align = "center",
                                        expanded = True,
                                        children = [
                                            render.Image(src = PLEX_ICON_ASSET.readall()),
                                            render.Box(width = 2),
                                            render.WrappedText("Recently Added", align = "center"),
                                        ],
                                    ),
                                ),
                                render.Box(height = 1, width = 64, color = "#EFAF08"),
                            ],
                        ),
                        duration = 200,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 0.2,
                                transforms = [animation.Translate(0, -32)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, -32)],
                            ),
                        ],
                    ),
                    animation.Transformation(
                        child = render.Row(
                            children = recentlyAdded,
                        ),
                        duration = 200,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 32)],
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(0, 32)],
                            ),
                            animation.Keyframe(
                                percentage = 0.2,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Row(
                children = recentlyAdded,
            ),
        )

def render_message(text):
    return render.Root(
        child = render.Column(
            children = [
                render.Image(src = PLEX_ICON_ASSET.readall()),
                render.WrappedText(text, align = "center"),
            ],
            main_align = "center",
            cross_align = "center",
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Plex HTTPS URL",
                desc = "Public HTTPS Plex or reverse-proxy URL. A bare host plus Server Port also works.",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port",
                desc = "Used only with a bare host, for example 32400",
                icon = "gear",
            ),
            schema.Text(
                id = "plexToken",
                name = "Plex-Token",
                desc = "\"X-Plex-Token\"",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "Use with proxy server (optional)",
                icon = "gear",
                secret = True,
            ),
            schema.Toggle(
                id = "showTitleCard",
                name = "Show title card",
                desc = "Show title card",
                icon = "gear",
                default = True,
            ),
        ],
    )
