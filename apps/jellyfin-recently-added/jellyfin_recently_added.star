"""
Applet: Jellyfin Recently Added
Summary: Display Jellyfin recently added
Description: Displays recently added on Jellyfin server. Home screen sections plugin required.
Author: noahpodgurski
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/jellyfin_icon.png", JELLYFIN_ICON_ASSET = "file")
load("images/sample1.jpg", SAMPLE1_ASSET = "file")
load("images/sample2.jpg", SAMPLE2_ASSET = "file")
load("images/sample3.jpg", SAMPLE3_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

JELLYFIN_ICON = JELLYFIN_ICON_ASSET.readall()

SAMPLE_DATA = {
    "Items": [
        {
            "Name": "Aquaman",
            "Id": "abc",
        },
        {
            "Name": "A Walk to Remember",
            "Id": "def",
        },
        {
            "Name": "Enemy at the Gates",
            "Id": "ghi",
        },
    ],
}

SAMPLE_IMAGES = [
    SAMPLE1_ASSET.readall(),
    SAMPLE2_ASSET.readall(),
    SAMPLE3_ASSET.readall(),
]

def server_url(serverIP, serverPort):
    serverIP = (serverIP or "").strip().rstrip("/")
    serverPort = (serverPort or "").strip()
    if not serverIP or "@" in serverIP or "?" in serverIP or "#" in serverIP or " " in serverIP or "\t" in serverIP or "\n" in serverIP:
        return None
    if serverIP.startswith("https://"):
        return serverIP
    if "/" in serverIP or not serverPort.isdigit() or int(serverPort) < 1 or int(serverPort) > 65535:
        return None
    return "https://%s:%s" % (serverIP, serverPort)

def safe_id(value):
    return type(value) == "string" and len(value) > 0 and len(value) <= 128 and all([char.isalnum() or char in "-_" for char in value.elems()])

def requestStatus(base_url, collectionName, apiKey, userId):
    res = http.get(
        base_url + "/HomeScreen/Section/RecentlyAdded%s" % collectionName,
        headers = {
            "Accept": "application/json",
            "X-Emby-Token": apiKey,
        },
        params = {"UserId": userId},
    )
    if res.status_code != 200:
        return None
    data = res.json()
    return data if type(data) == "dict" and type(data.get("Items")) == "list" else None

def requestThumb(base_url, apiKey, id):
    if not safe_id(id):
        return None
    res = http.get(
        base_url + "/Items/%s/Images/Primary" % id,
        headers = {
            "Accept": "image/jpeg",
            "X-Emby-Token": apiKey,
        },
        params = {"fillHeight": "27", "fillWidth": "21", "quality": "96"},
    )
    body = res.body()
    return body if res.status_code == 200 and len(body) <= 4194304 else None

def main(config):
    usingSampleData = False
    serverIP = config.get("serverIP", "")
    serverPort = config.get("serverPort", "")
    apiKey = config.get("apiKey", "")
    userId = config.get("userId")
    collectionName = config.get("collectionName", "Movies")
    titleText = config.get("titleText", "Recently added")
    showTitleCard = config.bool("showTitleCard", True)
    title = ""
    base_url = server_url(serverIP, serverPort)

    if not serverIP:
        usingSampleData = True
    elif not base_url or not apiKey or not safe_id(userId) or collectionName not in ("Movies", "Shows"):
        return message("Use public HTTPS and valid Jellyfin settings")

    if usingSampleData:
        newData = {"Items": []}
        for i in range(0, 3):
            newData["Items"].append({"ImageTags": {}})
            newData["Items"][i]["Name"] = SAMPLE_DATA["Items"][i]["Name"]
            newData["Items"][i]["Id"] = SAMPLE_IMAGES[i]
        data = newData
    else:
        data = requestStatus(base_url, collectionName, apiKey, userId)
        if data == None:
            return message("Jellyfin is unavailable")

    recentlyAdded = []

    n = 3
    items = data.get("Items", [])
    l = len(items)
    if l < 3:
        n = l

    #only show last 3
    for i in range(0, n):
        entry = items[i]
        if type(entry) != "dict" or (not usingSampleData and not safe_id(entry.get("Id"))):
            continue
        id = entry["Id"]
        title = entry.get("Name", "Unknown")
        title = title[:120] if type(title) == "string" else "Unknown"

        if not usingSampleData:
            thumbnail = requestThumb(base_url, apiKey, id)
        else:
            thumbnail = entry["Id"]
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
        if i < n - 1:
            recentlyAdded.append(
                render.Box(height = 32, width = 1, color = "#a160c4"),
            )

    if not recentlyAdded:
        return message("Nothing recently added")
    if showTitleCard:
        return render.Root(
            render.Stack(
                children = [
                    animation.Transformation(
                        child = render.Column(
                            children = [
                                render.Box(height = 1, width = 64, color = "#a160c4"),
                                render.Box(
                                    width = 64,
                                    height = 30,
                                    child = render.Row(
                                        main_align = "center",
                                        cross_align = "center",
                                        expanded = True,
                                        children = [
                                            render.Image(src = JELLYFIN_ICON, width = 16),
                                            render.Box(width = 2),
                                            render.WrappedText(titleText, align = "center"),
                                        ],
                                    ),
                                ),
                                render.Box(height = 1, width = 64, color = "#a160c4"),
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

def message(text):
    return render.Root(child = render.WrappedText(text, align = "center"))

def get_schema():
    collectionNameOptions = [
        schema.Option(
            display = "Movies",
            value = "Movies",
        ),
        schema.Option(
            display = "Shows",
            value = "Shows",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Jellyfin Server URL",
                desc = "Public HTTPS Jellyfin or reverse-proxy URL",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port",
                desc = "Optional when the server field is a full HTTPS URL",
                icon = "gear",
            ),
            schema.Text(
                id = "apiKey",
                name = "Api Key",
                desc = "Add API key from server dashboard advanced settings",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "userId",
                name = "User Id",
                desc = "Id of the user's dashboard (find IDs in URL by clicking on users in server dashboard)",
                icon = "gear",
            ),
            schema.Dropdown(
                id = "collectionName",
                name = "Collection Name",
                icon = "gear",
                desc = "Select collection",
                default = collectionNameOptions[0].value,
                options = collectionNameOptions,
            ),
            schema.Text(
                id = "titleText",
                name = "Title Text",
                icon = "gear",
                desc = "Text to show on title card",
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
