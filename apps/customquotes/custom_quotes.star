"""
Applet: Custom Quotes
Summary: Display custom quotes
Description: Display quotes from a Google sheet with a quote and author column
Author: vipulchhajer
"""

load("http.star", "http")
load("images/black_background.png", BLACK_BACKGROUND_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set default spreadsheet, API keys and supported range (1000)
default_spreadsheet_id = ""
default_api_key = ""
range = "Sheet1%21A1%3AB1000"

# Set fonts
QUOTE_FONT = "tom-thumb"
AUTHOR_FONT = "CG-pixel-3x5-mono"
QUOTE_COLOR = "#FFFFFF"
AUTHOR_COLOR = "#DCDCDC"
BOX_COLOR = "#00000099"

# Set width and height
OUTER_HEIGHT = 32
OUTER_WIDTH = 64
PADDING = 2
INNER_HEIGHT = OUTER_HEIGHT - 2 * PADDING
INNER_WIDTH = OUTER_WIDTH - 2 * PADDING

def valid_id(value, max_length):
    if not value or len(value) > max_length:
        return False
    for c in value.elems():
        if c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return False
    return True

def main(config):
    # Get spreadsheet and API key from user entry
    spreadsheet_id = config.str("spreadsheet_id", default_spreadsheet_id)
    api_key = config.str("api_key", default_api_key)
    if not valid_id(spreadsheet_id, 128) or not valid_id(api_key, 256):
        return render.Root(child = render.WrappedText("Set a valid sheet ID and API key", width = 64, align = "center"))
    url = "https://sheets.googleapis.com/v4/spreadsheets/{}/values/{}".format(spreadsheet_id, range)

    # Make a GET request to input data from Google Sheet
    r = http.get(url, params = {"key": api_key})

    # check the HTTP response code
    # if we fail, send back error message
    status_code = r.status_code
    if status_code != 200 or len(r.body()) > 2 * 1024 * 1024:
        quote = "Check spreadsheet ID or API key"
        author = ""
    else:
        # Extract the values array from the response
        values = r.json().get("values", [])
        rows = [item for item in values[1:1001] if type(item) == "list" and len(item) > 0 and item[0]]
        if not rows:
            quote = "No quote to display"
            author = ""
        else:
            row = rows[int(time.now().nanosecond / 1000) % len(rows)]
            quote = str(row[0])[:500]
            author = str(row[1])[:100] if len(row) > 1 else ""

        # Display error if no quote
        if (quote == ""):
            quote = "No quote to display"

        # Add hyphen if there's an author
        if (author != ""):
            author = "-" + author

    image = get_image()

    return render.Root(
        show_full_animation = True,
        delay = 200,
        child = render.Stack(
            children = [
                render.Image(src = image, height = OUTER_HEIGHT, width = OUTER_WIDTH),
                render.Padding(
                    pad = PADDING,
                    child = render.Box(
                        color = BOX_COLOR,
                        height = INNER_HEIGHT,
                        width = INNER_WIDTH,
                        child = render.Marquee(
                            height = INNER_HEIGHT,
                            width = INNER_WIDTH,
                            child = render.Column(
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = quote,
                                        font = QUOTE_FONT,
                                        color = QUOTE_COLOR,
                                        linespacing = 1,
                                        width = INNER_WIDTH,
                                    ),
                                    render.Box(width = INNER_WIDTH, height = 1),
                                    render.WrappedText(
                                        content = author,
                                        font = AUTHOR_FONT,
                                        color = AUTHOR_COLOR,
                                        linespacing = 2,
                                        width = INNER_WIDTH,
                                    ),
                                ],
                            ),
                            scroll_direction = "vertical",
                            offset_start = 16,
                            align = "end",
                        ),
                    ),
                ),
            ],
        ),
    )

# Define function to get random image
def get_image():
    # Return a minimal black background image (1x1 pixel)
    return BLACK_BACKGROUND_ASSET.readall()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "spreadsheet_id",
                name = "Spreadsheet ID",
                desc = "spreadsheet ID is in the URL of your Google Sheet",
                icon = "file",
            ),
            schema.Text(
                id = "api_key",
                name = "Google Sheets API Key",
                desc = "Google how to get API Key if you're not familiar",
                icon = "code",
                secret = True,
            ),
        ],
    )
