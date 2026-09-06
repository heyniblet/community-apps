"""
Applet: CR Anime Checker
Summary: Check anime on Crunchyroll
Description: Checks for the lastest episodes (subs and dubs) for an anime on Crunchyroll.
Author: Schoperation
"""

load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LANG = "en-US"
DEFAULT_ANIME = "one-piece"  # It'll go on forever as far as I can tell...
DEFAULT_SHOW_SUB = True
DEFAULT_SHOW_DUB = False
DEFAULT_IMAGE_TYPE = "poster_full"

DEFAULT_TITLE_COLOR = "#ffc266"
DEFAULT_SUB_ID_COLOR = "#a6a6a6"
DEFAULT_DUB_ID_COLOR = "#a6a6a6"

def main(config):
    lang_cfg = config.str("lang", DEFAULT_LANG)
    anime_cfg = config.str("anime", DEFAULT_ANIME)
    show_sub_cfg = config.bool("show_sub", DEFAULT_SHOW_SUB)
    show_dub_cfg = config.bool("show_dub", DEFAULT_SHOW_DUB)
    image_cfg = config.str("image_type", DEFAULT_IMAGE_TYPE)
    if lang_cfg not in ["en-US", "es-419"] or not re.match(r"^[a-z0-9-]{1,100}$", anime_cfg):
        return show_error("Invalid anime settings")

    title_color_cfg = config.str("title_color", DEFAULT_TITLE_COLOR)
    sub_id_color_cfg = config.str("sub_id_color", DEFAULT_SUB_ID_COLOR)
    dub_id_color_cfg = config.str("dub_id_color", DEFAULT_DUB_ID_COLOR)

    file_id, anime_name = get_file_id_and_anime_name(anime_cfg)
    if file_id == None:
        return show_error("Couldn't load master list (GH down?)")

    latest_episodes = get_latest_episodes(lang_cfg, anime_cfg)
    if latest_episodes == None:
        return show_error("Couldn't load latest episodes :(")

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        font = "tom-thumb",
                        color = title_color_cfg,
                        content = anime_name,
                    ),
                ),
                render.Row(
                    children = [
                        display_image(file_id, anime_cfg, image_cfg, latest_episodes),
                        render.Column(
                            cross_align = "center",
                            children = display_latest_episodes(image_cfg, show_sub_cfg, sub_id_color_cfg, show_dub_cfg, dub_id_color_cfg, latest_episodes),
                        ),
                    ],
                ),
            ],
        ),
    )

def display_image(file_id, anime_cfg, image_cfg, latest_episodes):
    if image_cfg == "none":
        return None

    anime_image = ""
    if image_cfg.count("poster") > 0:
        anime_image = get_poster(file_id, anime_cfg, image_cfg)
    else:
        anime_image = get_thumbnail(file_id, anime_cfg, image_cfg, latest_episodes)

    if anime_image == None:
        return render.WrappedText(
            content = "No image",
        )

    if image_cfg == "poster_top_half":
        return render.Image(
            width = 26,
            height = 54,
            src = anime_image,
        )
    elif image_cfg == "poster_wide":
        return render.Image(
            width = 64,
            height = 26,
            src = anime_image,
        )

    return render.Image(
        width = 26,
        height = 26,
        src = anime_image,
    )

def display_latest_episodes(image_cfg, show_sub_cfg, sub_id_color_cfg, show_dub_cfg, dub_id_color_cfg, latest_episodes):
    textObjs = [
        # Add blank line
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                font = "CG-pixel-3x5-mono",
                content = "",
            ),
        ),
    ]

    if show_sub_cfg:
        textObjs.extend(display_sub(image_cfg, show_dub_cfg, sub_id_color_cfg, latest_episodes))

    if show_dub_cfg:
        textObjs.extend(display_dub(image_cfg, show_sub_cfg, dub_id_color_cfg, latest_episodes))

    return textObjs

def display_sub(image_cfg, show_dub_cfg, sub_id_color_cfg, latest_episodes):
    marquee_width = 36
    if image_cfg == "none":
        marquee_width = 64

    if not show_dub_cfg:
        return (
            render.Text(
                font = "CG-pixel-3x5-mono",
                color = "#8A8A8A",
                content = "Sub:",
            ),
            render.Marquee(
                width = marquee_width,
                align = "center",
                child = render.Text(
                    font = "CG-pixel-3x5-mono",
                    color = sub_id_color_cfg,
                    content = "S{s}E{e}".format(s = latest_episodes["sub"]["season"], e = latest_episodes["sub"]["episode"]),
                ),
            ),
            render.Marquee(
                width = marquee_width,
                align = "start",
                offset_start = 10,
                child = render.Text(
                    font = "CG-pixel-3x5-mono",
                    content = latest_episodes["sub"]["title"],
                ),
            ),
        )

    return (
        render.Marquee(
            width = marquee_width,
            align = "center",
            child = render.Text(
                font = "CG-pixel-3x5-mono",
                color = sub_id_color_cfg,
                content = "S:S{s}E{e}".format(s = latest_episodes["sub"]["season"], e = latest_episodes["sub"]["episode"]),
            ),
        ),
        render.Marquee(
            width = marquee_width,
            align = "start",
            offset_start = 10,
            child = render.Text(
                font = "CG-pixel-3x5-mono",
                content = latest_episodes["sub"]["title"],
            ),
        ),
    )

def display_dub(image_cfg, show_sub_cfg, dub_id_color_cfg, latest_episodes):
    marquee_width = 36
    if image_cfg == "none":
        marquee_width = 64

    if not show_sub_cfg:
        return (
            render.Text(
                font = "CG-pixel-3x5-mono",
                color = "#8A8A8A",
                content = "Dub:",
            ),
            render.Marquee(
                width = marquee_width,
                align = "center",
                child = render.Text(
                    font = "CG-pixel-3x5-mono",
                    color = dub_id_color_cfg,
                    content = "S{s}E{e}".format(s = latest_episodes["dub"]["season"], e = latest_episodes["dub"]["episode"]),
                ),
            ),
            render.Marquee(
                width = marquee_width,
                align = "start",
                offset_start = 10,
                child = render.Text(
                    font = "CG-pixel-3x5-mono",
                    content = latest_episodes["dub"]["title"],
                ),
            ),
        )

    return (
        render.Marquee(
            width = marquee_width,
            align = "center",
            child = render.Text(
                font = "CG-pixel-3x5-mono",
                color = dub_id_color_cfg,
                content = "D:S{s}E{e}".format(s = latest_episodes["dub"]["season"], e = latest_episodes["dub"]["episode"]),
            ),
        ),
        render.Marquee(
            width = marquee_width,
            align = "start",
            offset_start = 10,
            child = render.Text(
                font = "CG-pixel-3x5-mono",
                content = latest_episodes["dub"]["title"],
            ),
        ),
    )

def get_file_id_and_anime_name(anime_cfg):
    anime_csv = get_sensei_list()
    if anime_csv == None:
        return None, None

    for anime in anime_csv:
        if len(anime) < 4 or anime[2] != anime_cfg:
            continue

        if type(anime[0]) == "string" and re.match(r"^[A-Za-z0-9._-]{1,100}$", anime[0]) and type(anime[3]) == "string":
            return anime[0], anime[3][:200]
        return None, None

    return None, None

def get_latest_episodes(lang_cfg, anime_cfg):
    url = "https://raw.githubusercontent.com/Schoperation/Tidbyt-Anime-Files/sensei/latest_episodes/{}.json".format(lang_cfg)
    resp = http.get(url = url, headers = {"Accept": "application/json", "User-Agent": "Crunchyroll Anime Checker - Tidbyt App"}, ttl_seconds = 300)
    if resp.status_code != 200 or len(resp.body()) > 2097152:
        return None

    data = json.decode(resp.body())
    latest_episodes = data.get("latest_episodes") if type(data) == "dict" else None

    if type(latest_episodes) != "dict" or anime_cfg not in latest_episodes or not valid_latest(latest_episodes[anime_cfg]):
        return None

    return latest_episodes[anime_cfg]

def get_poster(file_id, anime_cfg, image_cfg):
    url = "https://raw.githubusercontent.com/Schoperation/Tidbyt-Anime-Files/sensei/posters/{}.json".format(file_id)
    resp = http.get(url = url, headers = {"Accept": "application/json", "User-Agent": "Crunchyroll Anime Checker - Tidbyt App"}, ttl_seconds = 300)
    if resp.status_code != 200 or len(resp.body()) > 8388608:
        return None

    data = json.decode(resp.body())
    posters = data.get("posters") if type(data) == "dict" else None
    if type(posters) != "dict":
        return None

    poster = ""
    if anime_cfg not in posters:
        poster = data.get("default_poster_encoded", "")
    else:
        anime_posters = posters[anime_cfg]
        if type(anime_posters) != "dict":
            return None
        poster = anime_posters.get("poster_wide_encoded" if image_cfg == "poster_wide" else "poster_tall_encoded", "")

    return base64.decode(poster) if type(poster) == "string" and 0 < len(poster) and len(poster) <= 6291456 else None

def get_thumbnail(file_id, anime_cfg, image_cfg, latest_episodes):
    url = "https://raw.githubusercontent.com/Schoperation/Tidbyt-Anime-Files/sensei/thumbnails/{}.json".format(file_id)
    resp = http.get(url = url, headers = {"Accept": "application/json", "User-Agent": "Crunchyroll Anime Checker - Tidbyt App"}, ttl_seconds = 300)
    if resp.status_code != 200 or len(resp.body()) > 8388608:
        return None

    data = json.decode(resp.body())
    thumbnails = data.get("thumbnails") if type(data) == "dict" else None
    if type(thumbnails) != "dict":
        return None

    thumbnail = ""
    if anime_cfg not in thumbnails:
        thumbnail = data.get("default_thumbnail_encoded", "")
        return base64.decode(thumbnail) if type(thumbnail) == "string" and 0 < len(thumbnail) and len(thumbnail) <= 6291456 else None

    key = ""
    if image_cfg == "thumb_sub":
        key = "{s}-{e}".format(s = latest_episodes["sub"]["season"], e = latest_episodes["sub"]["episode"])
    else:
        key = "{s}-{e}".format(s = latest_episodes["dub"]["season"], e = latest_episodes["dub"]["episode"])

    if key == "0-0":
        thumbnail = data.get("default_thumbnail_encoded", "")
    else:
        anime_thumbnails = thumbnails.get(anime_cfg)
        episode = anime_thumbnails.get(key) if type(anime_thumbnails) == "dict" else None
        thumbnail = episode.get("encoded", "") if type(episode) == "dict" else ""

    return base64.decode(thumbnail) if type(thumbnail) == "string" and 0 < len(thumbnail) and len(thumbnail) <= 6291456 else None

def get_sensei_list():
    anime_sensei_list_url = "https://raw.githubusercontent.com/Schoperation/Tidbyt-Anime-Files/sensei/anime_sensei_list.csv"
    resp = http.get(url = anime_sensei_list_url, headers = {"Accept": "application/json", "User-Agent": "Crunchyroll Anime Checker - Tidbyt App"}, ttl_seconds = 300)
    if resp.status_code != 200 or len(resp.body()) > 524288:
        return None

    return csv.read_all(source = resp.body(), skip = 1, comma = "|")

def get_schema():
    config_fields = [
        schema.Dropdown(
            id = "lang",
            name = "Language",
            desc = "Language of subs and dubs to search for. More coming soon.",
            icon = "language",
            default = DEFAULT_LANG,
            options = [
                schema.Option(
                    display = "English (US)",
                    value = "en-US",
                ),
                schema.Option(
                    display = "Español (América Latina)",
                    value = "es-419",
                ),
            ],
        ),
        schema.Text(
            id = "anime",
            name = "Anime",
            desc = "Anime slug, for example one-piece.",
            icon = "tv",
            default = DEFAULT_ANIME,
        ),
        schema.Toggle(
            id = "show_sub",
            name = "Show Sub",
            desc = "Show the latest episode with subtitles in your language.",
            icon = "list",
            default = DEFAULT_SHOW_SUB,
        ),
        schema.Toggle(
            id = "show_dub",
            name = "Show Dub",
            desc = "Show the latest episode dubbed in your language.",
            icon = "comment",
            default = DEFAULT_SHOW_DUB,
        ),
        schema.Dropdown(
            id = "image_type",
            name = "Image",
            desc = "The image to show with the info.",
            icon = "image",
            default = DEFAULT_IMAGE_TYPE,
            options = [
                schema.Option(
                    display = "None",
                    value = "none",
                ),
                schema.Option(
                    display = "Poster (Full)",
                    value = "poster_full",
                ),
                schema.Option(
                    display = "Poster (Top Half)",
                    value = "poster_top_half",
                ),
                schema.Option(
                    display = "Poster (Wide)",
                    value = "poster_wide",
                ),
                schema.Option(
                    display = "Latest Episode Thumbnail (Sub)",
                    value = "thumb_sub",
                ),
                schema.Option(
                    display = "Latest Episode Thumbnail (Dub)",
                    value = "thumb_dub",
                ),
            ],
        ),
        schema.Color(
            id = "title_color",
            name = "Anime Title Color",
            desc = "Color of the anime's title at the top.",
            icon = "brush",
            default = DEFAULT_TITLE_COLOR,
        ),
        schema.Color(
            id = "sub_id_color",
            name = "Sub Identifier Color",
            desc = "Color of the latest sub's identifier (S:S1E2).",
            icon = "brush",
            default = DEFAULT_SUB_ID_COLOR,
        ),
        schema.Color(
            id = "dub_id_color",
            name = "Dub Identifier Color",
            desc = "Color of the latest dub's identifier (D:S1E2).",
            icon = "brush",
            default = DEFAULT_DUB_ID_COLOR,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = config_fields,
    )

def valid_latest(latest):
    if type(latest) != "dict":
        return False
    for kind in ["sub", "dub"]:
        episode = latest.get(kind)
        if type(episode) != "dict" or type(episode.get("title")) != "string" or len(episode["title"]) > 500:
            return False
        if type(episode.get("season")) not in ["int", "float"] or type(episode.get("episode")) not in ["int", "float"]:
            return False
    return True

def show_error(message):
    return render.Root(
        child = render.WrappedText(
            content = message,
        ),
    )
