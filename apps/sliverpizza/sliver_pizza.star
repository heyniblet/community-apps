"""
Applet: Sliver Pizza
Summary: Sliver's Pizza of the Day
Author: Aaron Janse
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

SLIVER_URL = "https://www.sliverpizzeria.com/locations/{}"
SLIVER_LOCATIONS = {
    "telegraph": "Telegraph",
    "shattuck": "Shattuck",
    "valdez": "Valdez",
    "moraga": "Lafayette",
    "antioch": "Montclair",
    "capitol": "Capitol",
}
DEFAULT_LOCATION = "telegraph"

def main(config):
    location = config.str("location", DEFAULT_LOCATION)
    response = http.get(SLIVER_URL.format(location), headers = {"User-Agent": "Mozilla/5.0"}, ttl_seconds = 3600)
    if response.status_code != 200:
        fail("Sliver request failed: %d" % response.status_code)
    pizza = html(response.body()).find("h3")
    if not pizza:
        return render.Root(child = render.Text("Pizza unavailable"))

    description = pizza.parent().find("p").text()
    return render.Root(child = render.Column(children = [
        render.Text(SLIVER_LOCATIONS[location], font = "tom-thumb", color = "#ff7a24"),
        render.Marquee(width = 64, child = render.Text(pizza.text(), font = "tb-8")),
        render.Marquee(width = 64, child = render.Text(description, font = "tom-thumb", color = "#ddd")),
    ]))

def get_schema():
    return schema.Schema(version = "1", fields = [schema.Dropdown(
        id = "location",
        name = "Location",
        desc = "Which Sliver Pizzeria location's pizza to display.",
        icon = "locationDot",
        default = DEFAULT_LOCATION,
        options = [schema.Option(display = name, value = code) for code, name in SLIVER_LOCATIONS.items()],
    )])
