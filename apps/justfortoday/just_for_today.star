"""
Applet: Just For Today
Summary: Today's "Just for Today"
Description: Show today's N.A. "Just for Today".
Author: elliotstoner
"""

load("http.star", "http")
load("images/jft_header.png", JFT_HEADER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JFT_HEADER = JFT_HEADER_ASSET.readall()

JFT_SOURCE = "na-just-for-today"
FILE_TYPE = ".txt"
DEFAULT_TEXT = "God, grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference."

def getCurrentDate():
    return time.now().format("01-02")

def getJftText(config):
    curr_date = getCurrentDate()

    root_url = config.get("JFT_DATA_ROOT_URL")
    if root_url == None:
        return DEFAULT_TEXT
    if not valid_root_url(root_url):
        return DEFAULT_TEXT
    root_url = root_url.removesuffix("/")
    req_url = "%s/%s/%s%s" % (
        root_url,
        JFT_SOURCE,
        curr_date,
        FILE_TYPE,
    )
    request = http.get(req_url)
    body = request.body()
    if request.status_code != 200 or not body or len(body) > 64 * 1024:
        return DEFAULT_TEXT
    return body[:4000]

def valid_root_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://"):
        return False
    return not any([char in value for char in ["@", "?", "#", "\\", " ", "\t", "\r", "\n"]])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "JFT_DATA_ROOT_URL",
                name = "JFT Data Root URL",
                desc = "The root URL for the JFT data.",
                icon = "link",
            ),
        ],
    )

def main(config):
    jft_text = getJftText(config)
    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            scroll_direction = "vertical",
            offset_start = 32,
            child = render.Column(
                children = [
                    render.Image(
                        src = JFT_HEADER,
                    ),
                    render.WrappedText(
                        content = jft_text,
                        width = 64,
                        font = "tb-8",
                    ),
                ],
            ),
        ),
    )
