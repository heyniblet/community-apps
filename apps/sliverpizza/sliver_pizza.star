"""
Applet: Sliver Pizza
Summary: Sliver's Pizza of the Day
Author: Aaron Janse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SLIVER_URL = "https://sliverpizzeria-api-production.up.railway.app/api/v1/pizza-of-day/public"
SLIVER_LOCATIONS = {
    "shattuck": "Shattuck",
    "telegraph": "Telegraph",
    "valdez": "Broadway",
    "moraga": "Lafayette",
    "antioch": "Montclair - Oakland",
    "capitol": "Fremont-Capitol",
}
DEFAULT_LOCATION = "telegraph"
MAX_RESPONSE_BYTES = 64 * 1024

def main(config):
    location = config.str("location", DEFAULT_LOCATION)
    if location not in SLIVER_LOCATIONS:
        location = DEFAULT_LOCATION
    response = http.get(
        SLIVER_URL,
        params = {"date_filter": time.now().format("2006-01-02")},
        headers = {"User-Agent": "tronbyt-sliver-pizza/1.0"},
        ttl_seconds = 3600,
    )
    body = response.body()
    pizzas = json.decode(body, []) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else []
    if type(pizzas) != "list":
        pizzas = []

    selected = None
    for pizza in pizzas[:24]:
        if type(pizza) == "dict" and pizza.get("location_name") == SLIVER_LOCATIONS[location]:
            selected = pizza
            break
    if selected == None:
        return error_frame("Pizza unavailable")

    name = bounded_text(selected.get("name"), 120)
    description = bounded_text(selected.get("description"), 400)
    if not name or not description:
        return error_frame("Pizza unavailable")
    return render.Root(child = render.Column(children = [
        render.Text(SLIVER_LOCATIONS[location][:20], font = "tom-thumb", color = "#ff7a24"),
        render.Marquee(width = 64, child = render.Text(name, font = "tb-8")),
        render.Marquee(width = 64, child = render.Text(description, font = "tom-thumb", color = "#ddd")),
    ]))

def bounded_text(value, limit):
    return value[:limit] if type(value) == "string" else ""

def error_frame(message):
    return render.Root(child = render.WrappedText(content = message, width = 64, color = "#f00"))

def get_schema():
    return schema.Schema(version = "1", fields = [schema.Dropdown(
        id = "location",
        name = "Location",
        desc = "Which Sliver Pizzeria location's pizza to display.",
        icon = "locationDot",
        default = DEFAULT_LOCATION,
        options = [schema.Option(display = name, value = code) for code, name in SLIVER_LOCATIONS.items()],
    )])
