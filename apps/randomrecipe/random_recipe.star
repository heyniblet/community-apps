"""
Applet: Random Recipe
Summary: Get a random recipe idea
Description: Display a random recipe from themealdb.com.
Author: noahpodgurski
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

SAMPLE_RESPONSE = {"meals": [{"idMeal": "53064", "strMeal": "Fettuccine Alfredo", "strDrinkAlternate": None, "strCategory": "Pasta", "strArea": "Italian", "strInstructions": "Cook pasta according to package instructions in a large pot of boiling water and salt. Add heavy cream and butter to a large skillet over medium heat until the cream bubbles and the butter melts. Whisk in parmesan and add seasoning (salt and black pepper). Let the sauce thicken slightly and then add the pasta and toss until coated in sauce. Garnish with parsley, and it's ready.", "strMealThumb": "https://www.themealdb.com/images/media/meals/0jv5gx1661040802.jpg", "strTags": None, "strYoutube": "https://www.youtube.com/watch?v=LPPcNPdq_j4", "strIngredient1": "Fettuccine", "strIngredient2": "Heavy Cream", "strIngredient3": "Butter", "strIngredient4": "Parmesan", "strIngredient5": "Parsley", "strIngredient6": "Black Pepper", "strIngredient7": "", "strIngredient8": "", "strIngredient9": "", "strIngredient10": "", "strIngredient11": "", "strIngredient12": "", "strIngredient13": "", "strIngredient14": "", "strIngredient15": "", "strIngredient16": "", "strIngredient17": "", "strIngredient18": "", "strIngredient19": "", "strIngredient20": "", "strMeasure1": "1 lb", "strMeasure2": "1/2 cup ", "strMeasure3": "1/2 cup ", "strMeasure4": "1/2 cup ", "strMeasure5": "2 tbsp", "strMeasure6": " ", "strMeasure7": " ", "strMeasure8": " ", "strMeasure9": " ", "strMeasure10": " ", "strMeasure11": " ", "strMeasure12": " ", "strMeasure13": " ", "strMeasure14": " ", "strMeasure15": " ", "strMeasure16": " ", "strMeasure17": " ", "strMeasure18": " ", "strMeasure19": " ", "strMeasure20": " ", "strSource": "https://www.delish.com/cooking/recipe-ideas/a55312/best-homemade-fettuccine-alfredo-recipe/", "strImageSource": None, "strCreativeCommonsConfirmed": None, "dateModified": None}]}
TITLE = "d95b52"
BLUE = "52c3d9"

REFRESH_TIME = 600
MAX_JSON_BYTES = 64 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024
IMAGE_PREFIX = "https://www.themealdb.com/images/"

def request():
    res = http.get("https://www.themealdb.com/api/json/v1/1/random.php", ttl_seconds = REFRESH_TIME)
    body = res.body()
    data = json.decode(body, None) if res.status_code == 200 and body and len(body) <= MAX_JSON_BYTES else None
    return data if valid_response(data) else SAMPLE_RESPONSE

def main():
    data = request()["meals"][0]

    imageUrl = data["strMealThumb"]
    imageSrc = get_image(imageUrl)
    name = data["strMeal"][:120]
    category = data["strCategory"][:80]
    area = data["strArea"][:80]

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Row(
                children = [
                    render.Column(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.WrappedText(align = "center", content = name, color = TITLE) if len(name) < 8 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                height = 6,
                                child = render.Text(name, color = TITLE),
                            ),
                            render.Box(width = 32, height = 1, color = "ffffff"),
                            render.WrappedText(align = "center", content = category, font = "tom-thumb", color = BLUE) if len(category) < 8 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                height = 6,
                                child = render.Text(category, font = "tom-thumb", color = BLUE),
                            ),
                            render.WrappedText(align = "center", content = area, font = "tom-thumb") if len(area) < 8 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                child = render.Text(area, font = "tom-thumb"),
                            ),
                        ],
                    ),
                    render.Image(height = 32, width = 32, src = imageSrc) if imageSrc != None else render.Box(width = 32),
                ],
            ),
        ),
    )

def valid_response(data):
    meals = data.get("meals") if type(data) == "dict" else None
    if type(meals) != "list" or len(meals) == 0 or type(meals[0]) != "dict":
        return False
    meal = meals[0]
    return all([type(meal.get(field)) == "string" for field in ["strMeal", "strCategory", "strArea", "strMealThumb"]])

def get_image(url):
    if not url.startswith(IMAGE_PREFIX):
        return None
    res = http.get(url, ttl_seconds = REFRESH_TIME)
    body = res.body()
    return body if res.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else None
