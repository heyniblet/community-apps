"""
Applet: Public Api
Summary: View random public apis
Description: Display a random public api from https://github.com/marcelscruz/public-apis
Author: noahpodgurski
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

REFRESH_TIME = 86400 * 7  #once a week
MAX_RESPONSE_BYTES = 1048576

# colors
YELLOW = "8eb707"
BLUE = "079ab7"

def get_all_apis():
    res = http.get("https://raw.githubusercontent.com/marcelscruz/public-apis/refs/heads/main/db/resources.json", ttl_seconds = REFRESH_TIME)
    body = res.body()
    data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    return data.get("entries", []) if res.status_code == 200 and type(data) == "dict" else []

def main():
    random.seed(time.now().unix // 30)
    all_apis = get_all_apis()
    if not all_apis:
        return render_message("Public API list unavailable")
    random_api = find_valid_api(all_apis, random.number(0, len(all_apis) - 1))
    if not random_api:
        return render_message("No API entries available")

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.WrappedText(align = "center", content = random_api["API"], color = YELLOW) if len(random_api["API"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(random_api["API"], color = YELLOW),
                        ),
                        render.Box(width = 64, height = 1, color = "857fc6"),
                        render.WrappedText(align = "center", content = random_api["Category"], font = "tom-thumb", color = BLUE) if len(random_api["Category"]) < 14 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(random_api["Category"], font = "tom-thumb", color = BLUE),
                        ),
                        # render.WrappedText("Auth: %s" % random_api["Auth"], font = "tom-thumb") if random_api["Auth"] else None,
                        render.WrappedText(align = "center", content = random_api["Description"], font = "tom-thumb") if len(random_api["Description"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            child = render.Text(random_api["Description"], font = "tom-thumb"),
                        ),
                    ],
                ),
            ),
        ),
    )

def find_valid_api(entries, start):
    for offset in range(len(entries)):
        entry = entries[(start + offset) % len(entries)]
        if type(entry) == "dict" and all([type(entry.get(key)) == "string" for key in ["API", "Category", "Description"]]):
            return entry
    return None

def render_message(message):
    return render.Root(child = render.Box(child = render.WrappedText(message, align = "center")))
