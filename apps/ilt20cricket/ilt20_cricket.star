"""
Applet: ILT20 Cricket
Summary: Current scores and match status
Author: M0ntyP
"""

load("http.star", "http")
load("render.star", "render")

SCOREBOARD_URL = "https://site.api.espn.com/apis/site/v2/sports/cricket/20921/scoreboard"
LEAGUE = "ILT20"

def main():
    response = http.get(SCOREBOARD_URL, ttl_seconds = 300)
    if response.status_code != 200:
        fail("ESPN scoreboard request failed: %d" % response.status_code)
    events = [event for event in response.json().get("events", []) if event.get("competitions")]
    if not events:
        return message("No matches")

    event = events[0]
    competition = event["competitions"][0]
    teams = competition["competitors"]
    rows = [render.Text(content = LEAGUE, font = "tom-thumb", color = "#f2a900")]
    for team in teams[:2]:
        label = "%s %s" % (team["team"]["abbreviation"], team.get("score") or "-")
        rows.append(render.Marquee(width = 64, child = render.Text(content = label, font = "tb-8")))
    rows.append(render.Marquee(
        width = 64,
        child = render.Text(content = competition["status"].get("summary") or event["status"]["type"]["description"], font = "tom-thumb", color = "#a8c7ff"),
    ))
    return render.Root(child = render.Column(children = rows))

def message(text):
    return render.Root(child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = [render.Text(text)]))
