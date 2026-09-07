load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LOGO_URL = "https://user-images.githubusercontent.com/10697207/186202043-26947e28-b1cc-459a-8f20-ffcc7fc0c71c.png"
RSS_URL = "https://dev.unleashedflip.com/rss"
CACHE_TTL = 300  # 5 minutes
MAX_RSS_BYTES = 128 * 1024
MAX_IMAGE_BYTES = 1024 * 1024
MAX_TEXT_LENGTH = 160

DEFAULT_LOGO_WIDTH = "48"
DEFAULT_LOGO_HEIGHT = "28"

def main(config):
    logo_width_value = str(config.get("logo_width", DEFAULT_LOGO_WIDTH))
    logo_height_value = str(config.get("logo_height", DEFAULT_LOGO_HEIGHT))
    logo_width = int(logo_width_value) if logo_width_value in [str(i) for i in range(16, 65, 8)] else int(DEFAULT_LOGO_WIDTH)
    logo_height = int(logo_height_value) if logo_height_value in [str(i) for i in range(10, 33, 2)] else int(DEFAULT_LOGO_HEIGHT)
    text_color = config.get("text_color", "#FFFFFF")
    date_color = config.get("date_color", "#FFB700")
    show_title = config.bool("show_title", True)
    show_date = config.bool("show_date", True)

    rss_data = get_rss_data()
    if not rss_data:
        return render.Root(
            child = render.Text("Failed to fetch RSS data"),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render_logo(logo_width, logo_height),
                render_build_info(rss_data, text_color, date_color, show_title, show_date),
            ],
        ),
    )

def get_rss_data():
    resp = http.get(RSS_URL, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return None

    data = resp.body()
    if len(data) > MAX_RSS_BYTES:
        return None
    items = data.split("<item>")
    if len(items) < 2:
        return None

    latest_item = items[1]
    title = extract_tag_content(latest_item, "title")
    pub_date = extract_tag_content(latest_item, "pubDate")
    if not title:
        content = extract_tag_content(latest_item, "content:encoded")
        marker = "Build - "
        start = content.find(marker)
        if start >= 0:
            build = content[start + len(marker):].split("<")[0].strip()
            title = "Build " + build[:32]
    if not title:
        title = "Unleashed FW"

    rss_data = {
        "title": title[:MAX_TEXT_LENGTH],
        "pub_date": pub_date[:80],
    }

    return rss_data

def extract_tag_content(text, tag):
    start_tag = "<" + tag + ">"
    end_tag = "</" + tag + ">"
    start_index = text.find(start_tag)
    if start_index == -1:
        return ""
    start_index += len(start_tag)
    end_index = text.find(end_tag, start_index)
    if end_index == -1:
        return ""
    return text[start_index:end_index].strip()

def render_logo(width, height):
    resp = http.get(LOGO_URL, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return render.Text("Failed to load logo")
    body = resp.body()
    if len(body) > MAX_IMAGE_BYTES:
        return render.Text("Logo too large")

    return render.Image(src = body, width = width, height = height)

def render_build_info(rss_data, text_color, date_color, show_title, show_date):
    title = rss_data["title"]
    pub_date = rss_data["pub_date"]

    formatted_date = format_date(pub_date)

    children = []
    if show_title:
        children.append(render.WrappedText(content = title, font = "CG-pixel-3x5-mono", width = 64, color = text_color))
    if show_date:
        children.append(render.Text(content = formatted_date, font = "CG-pixel-3x5-mono", color = date_color))

    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = children,
    )

def pad_number(number):
    if number < 10:
        return "0" + str(number)
    return str(number)

def format_date(date_string):
    parsed_time = time.parse_time(date_string, "Mon, 02 Jan 2006 15:04:05 -0700")
    if parsed_time == None:
        return "Unknown Date"

    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    month_name = months[parsed_time.month - 1]

    day = str(parsed_time.day)
    hour = parsed_time.hour
    minute = pad_number(parsed_time.minute)

    if hour > 12:
        hour = hour - 12
        am_pm = "PM"
    elif hour == 12:
        am_pm = "PM"
    elif hour == 0:
        hour = 12
        am_pm = "AM"
    else:
        am_pm = "AM"

    return month_name + " " + day + " " + str(hour) + ":" + minute + " " + am_pm

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "logo_width",
                name = "Logo Width",
                desc = "Select the width of the logo",
                icon = "gear",
                default = DEFAULT_LOGO_WIDTH,
                options = [schema.Option(display = str(i), value = str(i)) for i in range(16, 65, 8)],
            ),
            schema.Dropdown(
                id = "logo_height",
                name = "Logo Height",
                desc = "Select the height of the logo",
                icon = "gear",
                default = DEFAULT_LOGO_HEIGHT,
                options = [schema.Option(display = str(i), value = str(i)) for i in range(10, 33, 2)],
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color of the title text",
                icon = "palette",
                default = "#FFFFFF",
            ),
            schema.Color(
                id = "date_color",
                name = "Date Color",
                desc = "Color of the date text",
                icon = "palette",
                default = "#FFB700",
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show Date",
                desc = "Display the build date",
                icon = "calendar",
                default = True,
            ),
        ],
    )
