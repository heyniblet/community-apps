"""
Applet: FBI Most Wanted
Summary: Top 10 Most Wanted by FBI
Description: Displays info on 10 most wanted criminals.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

FBI_BASE_URL = "https://api.fbi.gov/wanted/v1/list"
FBI_CACHE_TTL = 60 * 60
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024

FBI_BLUE = "#0033A0"  # Justice/loyalty (blue field)
FBI_GOLD = "#FFD61A"  # Value/history (stars, outlines, peaks)
FBI_RED = "#CF093F"  # Courage/valor/strength (red stripes)
FBI_WHITE = "#FFFFFF"  # Truth/light/peace (white stripes)

def safe_get(data, path):
    """Safely navigate nested dict access. Returns "" for missing keys or None values."""
    current = data
    for key in path:
        if type(current) != "dict" or key not in current:
            return ""
        current = current[key]
        if current == None or current == "None":
            return ""
    return current if current != None else ""

def clean_html(text):
    """Remove HTML tags without recursing over provider-controlled text."""
    result = []
    inside = False
    for char in text.elems():
        if char == "<":
            inside = True
        elif char == ">":
            inside = False
            result.append(" ")
        elif not inside:
            result.append(char)
    return "".join(result)

def cleanup_text(text):
    """Remove extra whitespace."""
    words = [w for w in text.split() if w]
    return " ".join(words)

def supported_image(body):
    if not body or len(body) < 12:
        return False
    octets = body.elem_ords()
    return body[0:3] == "GIF" or octets[0] == 137 and body[1:4] == "PNG" or octets[0] == 255 and octets[1] == 216 or body[0:4] == "RIFF" and body[8:12] == "WEBP"

def get_top_ten_wanted():
    # Simplified URL: 'pageSize' is the correct key.
    # Since there are only ever 10, one page is plenty.
    url = "{}?poster_classification=ten".format(FBI_BASE_URL)

    resp = http.get(
        url = url,
        headers = {
            "Accept": "application/json",
            "User-Agent": "TidbytApp/1.0",
        },
        ttl_seconds = FBI_CACHE_TTL,
    )

    if resp.status_code != 200:
        return []

    body = resp.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    items = data.get("items", []) if type(data) == "dict" else []
    if type(items) != "list":
        return []
    top_ten = []

    for item in items[:50]:
        if type(item) != "dict":
            continue

        # Extra safety check: ensure it's actually a Top 10 fugitive
        subjects = item.get("subjects", [])
        if type(subjects) == "list" and "Ten Most Wanted Fugitives" in subjects:
            images = item.get("images", [])
            thumb = images[0].get("thumb", "") if type(images) == "list" and len(images) > 0 and type(images[0]) == "dict" else ""
            if type(thumb) != "string" or len(thumb) > 2048 or not thumb.startswith("https://www.fbi.gov/wanted/"):
                thumb = ""

            top_ten.append({
                "title": str(safe_get(item, ["title"]))[:120],
                "reward_text": str(safe_get(item, ["reward_text"]))[:500],
                "thumbnail": thumb,
                "remarks": cleanup_text(clean_html(str(safe_get(item, ["remarks"]))[:2000]))[:500],
                "place_of_birth": str(safe_get(item, ["place_of_birth"]))[:120],
                "uid": str(safe_get(item, ["uid"]))[:120],
            })
            if len(top_ten) == 10:
                break

    return top_ten

def main(config):
    top_ten = get_top_ten_wanted()

    if not top_ten:
        return render.Root(
            child = render.Text("No FBI data", color = "#ff0000"),
        )

    # Pick one at random
    selected = top_ten[random.number(0, len(top_ten) - 1)]

    if selected["thumbnail"] != "":
        image_response = http.get(selected["thumbnail"], headers = {"Accept": "image/png,image/jpeg,image/*;q=0.8", "User-Agent": "Niblet/1.0"}, ttl_seconds = FBI_CACHE_TTL)
        image_body = image_response.body()
        artwork = image_body if image_response.status_code == 200 and len(image_body) <= MAX_IMAGE_BYTES and supported_image(image_body) else None
    else:
        artwork = None

    delay = int(config.get("scroll", "45"))
    if canvas.is2x():
        font = "terminus-16"
        image_width = 32
        font_width = 8
        delay = int(delay / 2)
    else:
        font = "5x8"
        image_width = 32
        font_width = 5

    row1 = selected["title"]
    row2 = "Reward: {}".format(selected["reward_text"])
    row3 = "Remarks: {}".format(selected["remarks"])
    row4 = "Place of Birth: {}".format(selected["place_of_birth"])

    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = int(canvas.width() - image_width),
                            child = render.Text(row1, font = font, color = FBI_GOLD),
                        ),
                        render.Marquee(
                            offset_start = len(row1) * font_width,
                            width = int(canvas.width() - image_width),
                            child = render.Text(row2, font = font, color = FBI_WHITE),
                        ),
                        render.Marquee(
                            offset_start = (len(row1) + len(row2)) * font_width,
                            width = int(canvas.width() - image_width),
                            child = render.Text(row3, font = font, color = FBI_RED),
                        ),
                        render.Marquee(
                            offset_start = (len(row1) + len(row2) + len(row3)) * font_width,
                            width = int(canvas.width()) - image_width,
                            child = render.Text(row4, font = font, color = FBI_BLUE),
                        ),
                    ],
                ),
                render.Image(src = artwork, width = 32) if artwork else render.Text("👮"),
            ],
        ),
        delay = delay,
        show_full_animation = True,
    )

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Speed",
                desc = "Speed of scrolling text.",
                icon = "clock",
                options = scroll_speed_options,
                default = "45",
            ),
        ],
    )
