"""
Applet: Anime Next Ep
Summary: Anime next episode
Description: Tells when the next episode of an anime is via anilist.
Author: brianmakesthings
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ANILIST_ENDPOINT = "https://graphql.anilist.co"
DEFAULT_ANIME_ID = 21  # One Piece
MAX_RESPONSE_BYTES = 256 * 1024
MAX_IMAGE_BYTES = 8 * 1024 * 1024

def main(config):
    id = configured_anime_id(config.get("anime_name", str(DEFAULT_ANIME_ID)))
    if id == None:
        return render_error("Enter a valid AniList anime ID")

    media = fetch_airing_info(id)

    if media == None:
        return not_found(id)

    title = media["title"]["romaji"]
    cover_url = media["coverImage"]["medium"]
    next_episode = media.get("nextAiringEpisode")
    status = media["status"]  # Get the status field

    # Full-width title at the top
    title_display = render.Marquee(
        child = render.Text(title, font = "tb-8", color = "#FFFFFF"),
        scroll_direction = "horizontal",
        width = canvas.width(),
    )

    return render.Root(
        child = render.Column(
            # Stack title + image/text row
            children = [
                title_display,  # Top: Full-width title
                render.Row(
                    # Bottom: Image + Episode Info
                    children = [
                        render_cover(cover_url),
                        next_episode_info(next_episode, status),  # Right: Airing Info OR "Finished Airing"
                    ],
                ),
            ],
        ),
    )

def configured_anime_id(raw):
    if type(raw) != "string":
        return None
    legacy = re.findall(r'"value"\s*:\s*"([0-9]{1,10})"', raw)
    value = legacy[0] if legacy else raw.strip()
    if not re.findall("^[0-9]{1,10}$", value):
        return None
    anime_id = int(value)
    return anime_id if anime_id > 0 else None

def fetch_image(image_url):
    if type(image_url) != "string" or not image_url.startswith("https://s4.anilist.co/"):
        return None

    response = http.get(image_url, ttl_seconds = 24 * 60 * 60)
    body = response.body()

    if response.status_code != 200 or not body or len(body) > MAX_IMAGE_BYTES:
        return None

    return body

def render_cover(image_url):
    scale = 2 if canvas.is2x() else 1
    cover_image = fetch_image(image_url)
    if cover_image == None:
        return render.Box(width = 18 * scale, height = 24 * scale)
    return render.Padding(
        child = render.Image(
            width = 18 * scale,
            src = cover_image,
        ),
        pad = (0, 0, 1 * scale, 0),
    )

def not_found(id):
    return render.Root(
        child = render.WrappedText("Anime ID {} not found".format(id), color = "#FF0000"),
    )

def render_error(message):
    return render.Root(
        child = render.WrappedText(message, width = canvas.width(), align = "center", color = "#FF0000"),
    )

def next_episode_info(next_episode, status):
    if status == "FINISHED":
        return render.WrappedText("Finished Airing", font = "tom-thumb", color = "#FF0000")  # Red text

    if next_episode == None:
        return render.WrappedText("Next Air Date Unknown", font = "tom-thumb", color = "#FFFF00")  # Yellow text

    # If still airing, display next episode info
    episode = int(next_episode["episode"])
    nextAirDate = time.from_timestamp(int(next_episode["airingAt"]))
    humanized_time = humanize.time(nextAirDate)

    episode_text = "Ep {}: {}".format(episode, humanized_time)

    return (
        render.Marquee(
            child = render.WrappedText(episode_text, font = "tom-thumb", color = "#FFA500"),
            scroll_direction = "vertical",
            height = 32,
        )
    )

def fetch_airing_info(anime_id):
    query = {
        "query": """
        query ($id: Int) {
          Media(id: $id, type: ANIME) {
            title {
              romaji
            }
            coverImage {
              medium
            }
            nextAiringEpisode {
              episode
              airingAt
            }
            status
          }
        }
        """,
        "variables": {"id": anime_id},
    }

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    response = http.post(ANILIST_ENDPOINT, headers = headers, json_body = query, ttl_seconds = 3600)

    body = response.body()
    if response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None

    payload = json.decode(body, None)
    data = payload.get("data") if type(payload) == "dict" else None
    media = data.get("Media") if type(data) == "dict" else None
    if type(media) != "dict" or type(media.get("title")) != "dict" or type(media.get("coverImage")) != "dict":
        return None

    title = media["title"].get("romaji")
    cover_url = media["coverImage"].get("medium")
    status = media.get("status")
    next_episode = media.get("nextAiringEpisode")
    if type(title) != "string" or not title or len(title) > 200:
        return None
    if type(cover_url) != "string" or not cover_url.startswith("https://s4.anilist.co/"):
        return None
    if type(status) != "string" or len(status) > 40:
        return None
    if next_episode != None:
        if type(next_episode) != "dict" or type(next_episode.get("episode")) != "int" or type(next_episode.get("airingAt")) != "int":
            return None
    return media

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "anime_name",
                name = "AniList anime ID",
                desc = "Numeric anime ID from anilist.co (for example, 21 for One Piece)",
                icon = "tv",
                default = str(DEFAULT_ANIME_ID),
            ),
        ],
    )
