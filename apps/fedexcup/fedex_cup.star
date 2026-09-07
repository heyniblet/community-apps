"""Current FedExCup standings from the PGA TOUR media page."""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")

STANDINGS_URL = "https://pgatourmedia.pgatourhq.com/"

def main():
    response = http.get(STANDINGS_URL, headers = {"User-Agent": "Mozilla/5.0"}, ttl_seconds = 3600)
    if response.status_code != 200:
        fail("PGA TOUR request failed: %d" % response.status_code)

    document = html(response.body())
    headings = document.find("div.card-header")
    rows = None
    for index in range(headings.len()):
        heading = headings.eq(index)
        if heading.text().strip() == "FEDEXCUP STANDINGS":
            rows = heading.parent().find("tbody tr")
            break
    if not rows or rows.len() == 0:
        fail("FedExCup standings table was not found")

    players = []
    for index in range(rows.len()):
        cells = rows.eq(index).find("td")
        if cells.len() >= 3:
            players.append({
                "rank": cells.eq(0).text().strip(),
                "name": cells.eq(1).text().strip(),
                "points": cells.eq(2).text().strip(),
            })

    frames = []
    for start in range(0, len(players), 4):
        frames.append(render_frame(players[start:start + 4]))
    return render.Root(show_full_animation = True, delay = 2000, child = render.Animation(children = frames))

def render_frame(players):
    lines = [
        render.Box(width = 64, height = 5, color = "#0039a6", child = render.Text("FEDEX CUP", color = "#fff", font = "CG-pixel-3x5-mono")),
    ]
    for player in players:
        lines.append(render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("%s.%s" % (player["rank"], player["name"][:10]), font = "CG-pixel-3x5-mono"),
                render.Text(player["points"], color = "#7cc7ff", font = "CG-pixel-3x5-mono"),
            ],
        ))
    return render.Column(children = lines)
