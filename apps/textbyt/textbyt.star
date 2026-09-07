"""
Applet: Textbyt
Summary: Display text messages
Description: Display a scrolling message sent in via text.
Author: Josh Reed
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

TEXTBYT_API_URL = "https://us-central1-textbyt-rest-api.cloudfunctions.net/textbyt/v1/"

def main(config):
    feed = config.get("feed", "HelloWorld")
    author = "Textbyt"

    if (feed == None or feed == ""):
        msg_txt = "Enter a Textbyt feed id to get started"
    elif not re.match(r"^[A-Za-z0-9_-]{1,80}$", feed):
        msg_txt = "Invalid Textbyt feed id"
    else:
        textbyt = http.get(TEXTBYT_API_URL + feed)
        body = textbyt.body()
        data = json.decode(body, {}) if textbyt.status_code == 200 and body and len(body) <= 32 * 1024 else {}
        if type(data) != "dict" or type(data.get("author")) != "string" or type(data.get("message")) != "string":
            msg_txt = "Unknown Textbyt feed: " + feed
        else:
            author = data["author"][:80] + ":"
            msg_txt = data["message"][:1000]

    return render.Root(
        delay = 120,
        child = render.Column(
            children = [
                render.WrappedText(
                    content = author,
                    color = "#D2691E",
                    linespacing = 0,
                    width = 64,
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = "#D2691E",
                ),
                render.Marquee(
                    height = 23,  # 32 - 8 (author line) - 1 (divider line)
                    offset_start = 24,
                    offset_end = 24,
                    child = render.WrappedText(
                        content = msg_txt,
                        width = 64,
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed",
                name = "Feed ID",
                desc = "The Textbyt Feed ID",
                icon = "gear",
            ),
        ],
    )
