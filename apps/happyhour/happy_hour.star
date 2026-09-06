"""
Applet: Happy Hour
Summary: Hourly Cocktail Generator
Description: Displays a new cocktail every hour, on the hour. Cheers to my mom for the color scheme, idea, AND name!
Author: Nicole Brooks
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/error_img.png", ERROR_IMG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ERROR_IMG = ERROR_IMG_ASSET.readall()
MAX_RESPONSE_BYTES = 1024 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024

def main():
    hourlyCocktail = getNewCocktail()

    if "error" in hourlyCocktail:
        imgSrc = ERROR_IMG
        ingredients = []
        drinkName = hourlyCocktail

    else:
        image_url = hourlyCocktail.get("strDrinkThumb", "")
        imgSrc = ERROR_IMG
        if valid_image_url(image_url):
            image_response = http.get(image_url + "/small", ttl_seconds = 3600)
            image_body = image_response.body()
            image_type = image_response.headers.get("Content-Type", "")
            if image_response.status_code == 200 and len(image_body) <= MAX_IMAGE_BYTES and image_type.startswith("image/"):
                imgSrc = image_body
        ingredients = formatIngredients(hourlyCocktail)
        drinkName = hourlyCocktail["strDrink"]

    # Render
    return render.Root(
        child =
            render.Column(
                expanded = True,
                children = [
                    render.Row(
                        children = [
                            # Drink Image
                            render.Image(
                                src = imgSrc,
                                width = 25,
                                height = 25,
                            ),
                            # Ingredient List
                            render.Marquee(
                                width = 35,
                                height = 25,
                                scroll_direction = "vertical",
                                child = render.Column(
                                    children = ingredients,
                                ),
                            ),
                        ],
                    ),
                    # Drink Name
                    render.Box(
                        color = "#2E0854",
                        child = render.Marquee(
                            width = 64,
                            #height = 20,
                            child = render.Column(
                                expanded = True,
                                children = [
                                    render.Box(
                                        height = 1,
                                        width = 64,
                                    ),
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = drinkName,
                                            font = "tom-thumb",
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
    )

# Gets the updated cocktail from the API.
def getNewCocktail():
    response = http.get("https://thecocktaildb.com/api/json/v1/1/random.php", ttl_seconds = 3600)
    body = response.body()

    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return "error: " + str(response.status_code)
    if "application/json" not in response.headers.get("Content-Type", ""):
        return "error :("

    data = json.decode(body, {})
    drinks = data.get("drinks", []) if type(data) == "dict" else []
    if type(drinks) != "list" or not drinks or type(drinks[0]) != "dict":
        return "error :("
    cocktail = drinks[0]
    name = cocktail.get("strDrink")
    if type(name) != "string" or not name:
        return "error :("
    cocktail["strDrink"] = name[:100]
    return cocktail

# Creates ingredients list as a list of strings.
def formatIngredients(cocktail):
    list = []
    for index in range(1, 16):
        propertyName = "strIngredient" + str(index)
        ingredient = cocktail.get(propertyName)
        if type(ingredient) == "string" and ingredient:
            ingWords = ingredient[:100].split()
            for ind, ing in enumerate(ingWords):
                if len(ing) > 8 and "-" in ing:
                    ingWords[ind] = ing[0:ing.index("-")] + "\n" + ing[ing.index("-"):]
                elif len(ing) > 8:
                    ingWords[ind] = ing[0:8] + "\n" + ing[8:]
            fullIngredientName = " ".join(ingWords)
            bgColor = "#080808"
            if index % 2 == 1:
                bgColor = "#606060"
            height = rowHeight(fullIngredientName)
            list.append(
                render.Box(
                    height = height,
                    padding = 1,
                    color = bgColor,
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        children = [
                            render.WrappedText(
                                content = fullIngredientName,
                                color = "#f0f0f0",
                                font = "tom-thumb",
                            ),
                        ],
                    ),
                ),
            )
    return list

# Returns the desired height of the ingredient row.
def rowHeight(str):
    height = 7
    if len(str) > 8:
        height = 14
    if len(str) > 16:
        height = 21
    return height

def valid_image_url(value):
    return type(value) == "string" and len(value) <= 2048 and (value.startswith("https://www.thecocktaildb.com/images/") or value.startswith("https://thecocktaildb.com/images/")) and not any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]])

# No schema.
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
