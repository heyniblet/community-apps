"""
Applet: Fishbyt
Summary: Fish facts
Description: Gaze upon glorious marine life.
Author: vlauffer
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("images/fail_image.png", FAIL_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DIRECTORY_URL = "https://www.fisheries.noaa.gov/topic/sustainable-seafood/seafood-profiles"
NOAA_ORIGIN = "https://www.fisheries.noaa.gov"
MAX_HTML_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024
CACHE_TTL_SECONDS = 24 * 60 * 60

def fetch_html(url):
    response = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_HTML_BYTES:
        return ""
    return body

def clean_text(value, maximum = 140):
    if type(value) != "string":
        return ""
    return " ".join(value.split())[:maximum]

def seafood_profiles():
    body = fetch_html(DIRECTORY_URL)
    if not body:
        return []
    profiles = []
    for link in bsoup.parseHtml(body).find_all("a")[:1000]:
        title = link.find("div", {"class": "bold-font"})
        image = link.find("img")
        href = clean_text(link.attrs().get("href", ""), 180)
        src = clean_text(image.attrs().get("src", ""), 300) if image != None else ""
        name = clean_text(title.get_text(), 80) if title != None else ""
        if not href.startswith("/species/") or not href.rstrip().endswith("/seafood"):
            continue
        if not src.startswith("/s3/"):
            src = ""
        if name:
            profiles.append({"name": name, "url": NOAA_ORIGIN + href.strip(), "image": NOAA_ORIGIN + src if src else ""})
    return profiles

def profile_fact(url):
    body = fetch_html(url)
    if not body:
        return ["Fish fact", "NOAA profile unavailable"]
    facts = []
    for item in bsoup.parseHtml(body).find_all("div", {"class": "species-profile__status"})[:20]:
        title_node = item.find("h3", {"class": "species-profile__status-title"})
        value_node = item.find("p")
        title = clean_text(title_node.get_text(), 30) if title_node != None else ""
        value = clean_text(value_node.get_text(), 140) if value_node != None else ""
        if title and value:
            facts.append([title, value])
    return facts[random.number(0, len(facts) - 1)] if facts else ["Fish fact", "NOAA profile unavailable"]

def fetch_image(url):
    if not url.startswith(NOAA_ORIGIN + "/s3/"):
        return FAIL_IMAGE_ASSET.readall()
    response = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_IMAGE_BYTES:
        return FAIL_IMAGE_ASSET.readall()
    octets = body.elem_ords()
    if len(body) < 4 or not (octets[0] == 137 and body[1:4] == "PNG" or octets[0] == 255 and octets[1] == 216):
        return FAIL_IMAGE_ASSET.readall()
    return body

def main():
    profiles = seafood_profiles()
    if not profiles:
        return render.Root(child = render.WrappedText("FishWatch unavailable"))
    profile = profiles[random.number(0, len(profiles) - 1)]
    fact = profile_fact(profile["url"])
    return render.Root(
        delay = 60 if len(fact[1]) > 80 else 80,
        child = render.Marquee(
            width = 64,
            height = 32,
            offset_start = 39,
            offset_end = 39,
            scroll_direction = "vertical",
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.WrappedText(content = profile["name"], font = "tb-8"),
                    render.Image(src = fetch_image(profile["image"]), width = 40, height = 20),
                    render.WrappedText(content = fact[0] + ":", font = "tb-8"),
                    render.WrappedText(content = fact[1], font = "tb-8"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
