"""
Applet: Movie Challenge
Summary: Letterboxd watch progress
Description: This app shows your Letterboxd movie watching progress. It gets your Letterboxd list of watched movies, shows a counter of how many movies you've watched out of your goal (e.g., "42/100"), and displays a randomly selected movie from your list with its rating.
Author: caropinzonsilva
"""

load("html.star", "html")
load("http.star", "http")
load("images/film_icon.png", FILM_ICON_ASSET = "file")
load("images/half_star_icon.png", HALF_STAR_ICON_ASSET = "file")
load("images/movie_icon.png", MOVIE_ICON_ASSET = "file")
load("images/star_icon.png", STAR_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FILM_ICON = FILM_ICON_ASSET.readall()
HALF_STAR_ICON = HALF_STAR_ICON_ASSET.readall()
MOVIE_ICON = MOVIE_ICON_ASSET.readall()
STAR_ICON = STAR_ICON_ASSET.readall()

# Schema definition for the app's configuration
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # Username field for Letterboxd account
            schema.Text(
                id = "letterboxd_username",
                name = "Letterboxd Username",
                desc = "Your Letterboxd username",
                icon = "user",
                default = "flanaganfilm",
            ),
            # List name field - extracted from the Letterboxd list URL
            schema.Text(
                id = "letterboxd_list_name",
                name = "Letterboxd list name",
                desc = "The list name taken from the URL of your Letterboxd list",
                icon = "link",
                default = "flanagans-best-of-2025",
            ),
            # Goal field for number of movies to watch
            schema.Text(
                id = "movie_goal",
                name = "Movie Goal",
                desc = "Your target number of movies to watch",
                icon = "film",
                default = "50",
            ),
        ],
    )

def main(config):
    # Get configuration values with defaults
    letterboxd_username = config.get("letterboxd_username", "flanaganfilm")
    letterboxd_list_name = config.get("letterboxd_list_name", "flanagans-best-of-2025")
    if not valid_slug(letterboxd_username) or not valid_slug(letterboxd_list_name):
        return render_error("Use only letters, numbers, - and _ in Letterboxd names")
    movie_goal_str = config.get("movie_goal", "50")
    if not movie_goal_str.isdigit() or int(movie_goal_str) < 1:
        return render_error("Movie Goal must be a positive number")
    movie_goal = int(movie_goal_str)
    letterboxd_url = "https://letterboxd.com/%s/list/%s/detail/by/reverse/" % (letterboxd_username, letterboxd_list_name)

    # Fetch and parse the Letterboxd list page
    response = http.get(letterboxd_url)
    if response.status_code != 200:
        return render_error("Letterboxd returned error %d" % response.status_code)
    htmlstr = response.body()
    doc = html(htmlstr)
    watchedMovies = doc.find(".list-detailed-entry")

    # Display error message if no movies are found
    if watchedMovies.len() == 0:
        return render_error("No movies found - Check list URL and username")

    # Select a random movie from the list
    random_index = random.number(0, watchedMovies.len() - 1)
    movieDetails = watchedMovies.eq(random_index)
    movieName = movieDetails.find(".name").text()

    # Extract and process the movie's rating (if it exists)
    starImages = []
    ratingClass = movieDetails.find(".rating").attr("class")
    if ratingClass != None and "rated-" in ratingClass:
        rating_value = ratingClass.split("rated-")[1].split(" ")[0]
        ratingOverTen = int(rating_value) if rating_value.isdigit() else 0
        fullStars = int(ratingOverTen / 2)
        halfStars = ratingOverTen % 2

        # Add separator between movie name and rating
        starImages.append(render.Text(
            content = " - ",
            color = "#ffffff",
            font = "5x8",
        ))

        # Create list of star images based on rating
        for _i in range(fullStars):
            starImages.append(render.Image(src = STAR_ICON))
        if halfStars == 1:
            starImages.append(render.Image(src = HALF_STAR_ICON))

    # Calculate progress percentage for the progress bar
    leftPadding = 0 if watchedMovies.len() >= movie_goal else int((1 - (watchedMovies.len() / movie_goal)) * 128)

    # Render the main display
    return render.Root(
        child = render.Box(
            color = "#709AD1",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # Top row with movie counter and selected movie
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            # Movie icon
                            render.Image(src = MOVIE_ICON),
                            # Counter and movie details
                            render.Column(
                                children = [
                                    # Movies watched counter
                                    render.Text(
                                        content = "%d/%d" % (watchedMovies.len(), movie_goal),
                                        color = "#ffffff",
                                    ),
                                    # Scrolling movie name and rating
                                    render.Marquee(
                                        width = 40,
                                        child = render.Row(
                                            children = [
                                                render.Text(
                                                    content = "%s" % movieName,
                                                    color = "#ffffff",
                                                    font = "5x8",
                                                ),
                                            ] + starImages,  # Add rating stars if they exist
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    # Bottom progress bar
                    render.Padding(
                        pad = (0, 0, leftPadding, 0),  # (left, top, right, bottom)
                        child = render.Image(src = FILM_ICON),
                    ),
                ],
            ),
        ),
    )

def valid_slug(value):
    if not value:
        return False
    for char in value.elems():
        if not char.isalnum() and char != "-" and char != "_":
            return False
    return True

def render_error(message):
    return render.Root(
        child = render.Box(
            color = "#709AD1",
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [render.Marquee(width = 64, child = render.Text(content = message, color = "#ffffff"))],
            ),
        ),
    )
