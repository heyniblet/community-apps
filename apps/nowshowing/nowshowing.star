"""
Applet: NowShowing
Summary: Current movies in theaters
Description: Displays current movies in theaters.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MOVIE_DATASET_URL = "https://www.moviefone.com/movies/in-theaters/"
SINGLE_MOVIE_CACHE = 1200  # 20 minutes
MOVIE_DATASET_CACHE = 3600
REQUEST_HEADERS = {"user-agent": "Mozilla/5.0 (compatible; Niblet/1.0; +https://heyniblet.com)"}

def get_movie_data():
    fallback = {"title": "Movies", "description": "Listings unavailable", "image": ""}
    resp = http.get(MOVIE_DATASET_URL, headers = REQUEST_HEADERS, ttl_seconds = MOVIE_DATASET_CACHE)
    if resp.status_code != 200:
        return fallback
    body = resp.body()
    if not body or len(body) > 2000000:
        return fallback
    scripts = re.findall(r'<script type="application/ld\+json">([\s\S]*?)</script>', body)
    if not scripts:
        return fallback
    prefix = '<script type="application/ld+json">'
    data = json.decode(scripts[0][len(prefix):-len("</script>")])
    main_entity = data.get("mainEntity", {}) if type(data) == "dict" else {}
    items = main_entity.get("itemListElement", []) if type(main_entity) == "dict" else []
    movies = []
    for entry in items[:50]:
        movie = entry.get("item", {}) if type(entry) == "dict" else {}
        title = movie.get("name") if type(movie) == "dict" else None
        if type(title) != "string" or not title.strip():
            continue
        rating = movie.get("aggregateRating", {})
        rating = rating.get("ratingValue") if type(rating) == "dict" else None
        description = "In theaters" if rating == None else "In theaters • {}/10".format(rating)
        image = movie.get("image", "")
        image = image if type(image) == "string" and image.startswith("https://cdn.moviefone.com/") else ""
        movies.append({"title": title[:120], "description": description, "image": image})
    if not movies:
        return fallback
    return movies[int(time.now().unix // SINGLE_MOVIE_CACHE) % len(movies)]

def main(config):
    #get the movie data for a single movie that we will display
    movie_data = get_movie_data()

    #Fonts: 10x20 5x8 6x10-rounded 6x10 6x13 CG-pixel-3x5-mono CG-pixel-4x5-mono Dina_r400-6 tb-8 tom-thumb
    font = "5x8"

    # we will add items in display_items... these will be stacked on top of each other in the display
    display_items = []

    # do we display the movie image?
    if config.bool("artwork", True) and movie_data["image"]:
        movie_image_url = movie_data["image"]
        artwork_resp = http.get(movie_image_url, ttl_seconds = 86400)
        artwork = artwork_resp.body() if artwork_resp.status_code == 200 else None
        if artwork and len(artwork) <= 2000000:
            display_items.append(render.Image(src = artwork, width = 64, height = 32))

    # do we append black overlay?
    if config.bool("cc", False):
        black_box = render.Box(width = 64, height = 7, color = "#000000")
        display_items.append(black_box)
        black_box = add_padding_to_child_element(black_box, 0, 25)
        display_items.append(black_box)

    # append title
    display_items.append(render.Marquee(
        width = 64,
        child = render.Text(content = movie_data["title"], color = config.get("color_1", "#ffffff"), font = font),
    ))

    # append description
    description = movie_data["description"]
    description = render.Marquee(
        width = 64,
        offset_start = 40,
        child = render.Text(content = description, color = config.get("color_2", "#ffffff"), font = font),
    )
    description = add_padding_to_child_element(description, 0, 24)
    display_items.append(description)

    # Secret Code to display "Display Count" -- Make the font color black for both title and description (a crazy combo nobody wants)
    # This should help me make sure the app works as expected on the devices like it does locally
    # This will simply tell me how often this particular movie was cached as the current movie since the dataset was downloaded
    if config.get("color_1") == "#000000" and config.get("color_2") == "#000000":
        display_count_text = str(movie_data["display_count"])
        display_count_text = render.Text(content = display_count_text, color = "#ffffff", font = font)
        display_count_text = add_padding_to_child_element(display_count_text, 30, 15)
        display_items.append(display_count_text)

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
        schema.Option(
            display = "Lightning",
            value = "15",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "artwork",
                name = "Display Movie Artwork?",
                desc = "Displays the movie artwork under the marquee information of the movie coming out.",
                icon = "photoFilm",
                default = True,
            ),
            schema.Toggle(
                id = "cc",
                name = "Closed Caption Style?",
                desc = "Add black overlay over image to make text easier to read.",
                icon = "glasses",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Color(
                id = "color_1",
                name = "Movie Title Color",
                desc = "Color of the text at the top displaying the movie title.",
                icon = "brush",
                default = "#f4a306",
            ),
            schema.Color(
                id = "color_2",
                name = "Movie Information Color",
                desc = "Color of the text at the bottom displaying the movie information.",
                icon = "brush",
                default = "#ffffff",
            ),
        ],
    )
