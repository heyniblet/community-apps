load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

def main():
    resp = http.get("https://pandemicpictures.info/imdb", ttl_seconds = 21600)
    if resp.status_code != 200:
        fail("Best Picture API request failed with status %d", resp.status_code)
    movies = resp.json()
    if len(movies) == 0:
        fail("Best Picture API returned no movies")
    movie = movies[random.number(0, len(movies) - 1)]
    image_resp = http.get(movie["ImageUrl"], ttl_seconds = 21600)
    img = image_resp.body() if image_resp.status_code == 200 else None
    children = [
        render.WrappedText(
            content = "%s (%d) %s" % (movie["Title"], movie["OscarYear"], movie["Rating"]),
            color = "#099",
            width = 40 if img != None else 64,
            font = "tom-thumb",
        ),
    ]
    if img != None:
        children.append(render.Image(src = img, width = 20, height = 40))

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = children,
            ),
        ),
    )
