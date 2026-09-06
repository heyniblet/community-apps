"""Final medal standings for the Milano Cortina 2026 Winter Olympics."""

load("images/rings_logo.png", RINGS_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

RINGS_LOGO = RINGS_LOGO_ASSET.readall()

# The Games ended on February 22, 2026. Keeping the final table local avoids
# depending on the retired community API that originally powered this app.
MEDALS = [
    {"code": "NOR", "name": "Norway", "gold": 18, "silver": 12, "bronze": 11},
    {"code": "USA", "name": "United States", "gold": 12, "silver": 12, "bronze": 9},
    {"code": "NED", "name": "Netherlands", "gold": 10, "silver": 7, "bronze": 3},
    {"code": "ITA", "name": "Italy", "gold": 10, "silver": 6, "bronze": 14},
    {"code": "GER", "name": "Germany", "gold": 8, "silver": 10, "bronze": 8},
    {"code": "FRA", "name": "France", "gold": 8, "silver": 9, "bronze": 6},
    {"code": "SWE", "name": "Sweden", "gold": 8, "silver": 6, "bronze": 4},
    {"code": "SUI", "name": "Switzerland", "gold": 6, "silver": 9, "bronze": 8},
    {"code": "AUT", "name": "Austria", "gold": 5, "silver": 8, "bronze": 5},
    {"code": "JPN", "name": "Japan", "gold": 5, "silver": 7, "bronze": 12},
    {"code": "CAN", "name": "Canada", "gold": 5, "silver": 7, "bronze": 9},
    {"code": "CHN", "name": "China", "gold": 5, "silver": 4, "bronze": 6},
    {"code": "KOR", "name": "South Korea", "gold": 3, "silver": 4, "bronze": 3},
    {"code": "AUS", "name": "Australia", "gold": 3, "silver": 2, "bronze": 1},
    {"code": "GBR", "name": "Great Britain", "gold": 3, "silver": 1, "bronze": 1},
    {"code": "CZE", "name": "Czechia", "gold": 2, "silver": 2, "bronze": 1},
    {"code": "SLO", "name": "Slovenia", "gold": 2, "silver": 1, "bronze": 1},
    {"code": "ESP", "name": "Spain", "gold": 1, "silver": 0, "bronze": 2},
    {"code": "BRA", "name": "Brazil", "gold": 1, "silver": 0, "bronze": 0},
    {"code": "KAZ", "name": "Kazakhstan", "gold": 1, "silver": 0, "bronze": 0},
    {"code": "POL", "name": "Poland", "gold": 0, "silver": 3, "bronze": 1},
    {"code": "NZL", "name": "New Zealand", "gold": 0, "silver": 2, "bronze": 1},
    {"code": "FIN", "name": "Finland", "gold": 0, "silver": 1, "bronze": 5},
    {"code": "LAT", "name": "Latvia", "gold": 0, "silver": 1, "bronze": 1},
    {"code": "DEN", "name": "Denmark", "gold": 0, "silver": 1, "bronze": 0},
    {"code": "EST", "name": "Estonia", "gold": 0, "silver": 1, "bronze": 0},
    {"code": "GEO", "name": "Georgia", "gold": 0, "silver": 1, "bronze": 0},
    {"code": "BUL", "name": "Bulgaria", "gold": 0, "silver": 0, "bronze": 2},
    {"code": "BEL", "name": "Belgium", "gold": 0, "silver": 0, "bronze": 1},
]

def main(config):
    country_code = config.str("country", "all")
    if country_code == "all":
        return render_standings()

    for position in range(len(MEDALS)):
        if MEDALS[position]["code"] == country_code:
            return render_country(MEDALS[position], position + 1)

    return render_standings()

def render_standings():
    return render.Root(
        child = render.Column(
            children = [render_header()] + [build_row(MEDALS[position], position + 1) for position in range(3)],
        ),
    )

def render_country(country, position):
    return render.Root(
        child = render.Column(
            children = [
                render_header(),
                render.Box(height = 1, color = "#000"),
                render.Row(
                    children = [
                        render.Box(width = 15, child = render.Text("#%d" % position, font = "tom-thumb")),
                        render.Marquee(width = 49, child = render.Text(country["name"], font = "tom-thumb")),
                    ],
                ),
                build_row(country, position),
            ],
        ),
    )

def build_row(country, position):
    color = ["#3b3b3b", "#000000"][position % 2]
    total = country["gold"] + country["silver"] + country["bronze"]
    return render.Row(
        children = [
            render.Box(width = 14, height = 7, color = color, child = render.Text(country["code"], font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(country["gold"]), color = "#f4ca72", font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(country["silver"]), color = "#e5e5e5", font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(country["bronze"]), color = "#d5b58c", font = "tom-thumb", offset = -1)),
            render.Box(width = 14, height = 7, color = color, child = render.Text(str(total), font = "tom-thumb", offset = -1)),
        ],
    )

def render_header():
    return render.Row(
        children = [
            render.Padding(pad = (1, 1, 1, 0), child = render.Image(height = 10, src = RINGS_LOGO)),
            render.Box(height = 11, child = render.Text("MILANO 2026", font = "tom-thumb", offset = -1, color = "#d4c482")),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "country",
                name = "Country",
                desc = "Show the final top three or one country.",
                icon = "flag",
                options = [schema.Option(display = "Top 3 Countries", value = "all")] + [
                    schema.Option(display = country["name"], value = country["code"])
                    for country in MEDALS
                ],
                default = "all",
            ),
        ],
    )
