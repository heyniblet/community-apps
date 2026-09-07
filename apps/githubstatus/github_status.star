"""
Applet: GitHub Status
Summary: Monitor GitHub status
Description: Periodically call the GitHub status page and display any outages that occur.
Author: hross
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/github_icon.png", GITHUB_ICON_ASSET = "file")
load("images/github_icon_red.png", GITHUB_ICON_RED_ASSET = "file")
load("images/github_icon_yellow.png", GITHUB_ICON_YELLOW_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_ICON = GITHUB_ICON_ASSET.readall()
GITHUB_ICON_RED = GITHUB_ICON_RED_ASSET.readall()
GITHUB_ICON_YELLOW = GITHUB_ICON_YELLOW_ASSET.readall()

GITHUB_INCIDENTS_JSON = "https://www.githubstatus.com/api/v2/components.json"
MAX_RESPONSE_BYTES = 256 * 1024
SEVERITY = {"operational": 0, "under_maintenance": 1, "degraded_performance": 2, "partial_outage": 3, "major_outage": 4}

def main():
    rep = http.get(GITHUB_INCIDENTS_JSON, ttl_seconds = 240)
    body = rep.body()
    statusJson = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    components = statusJson.get("components") if type(statusJson) == "dict" else None
    if type(components) != "list":
        components = []

    op_state = "good"
    highest_severity = 0
    failing_components = []

    for component in components[:100]:
        status = component.get("status") if type(component) == "dict" else None
        name = component.get("name") if type(component) == "dict" else None
        severity = SEVERITY.get(status, 0)
        if severity > 0:
            if severity > highest_severity:
                highest_severity = severity
                op_state = status

            # add marquee text to outage info
            if type(name) == "string" and name and not "githubstatus.com" in name.lower():
                failing_components.append(
                    render.Marquee(width = 48, child = render.Text(" " + " ".join(name.split())[:80], color = "#a00" if severity >= 3 else "#FFFF00")),
                )

    if not components:
        op_state = "unavailable"
        failing_components = [render.Marquee(width = 48, child = render.Text(" Status unavailable", color = "#a00"))]
    elif (op_state == "good"):
        failing_components = [render.Marquee(width = 48, child = render.Text(" No Issues", color = "#0a0"))]

    # a lot of failures
    if (op_state != "good" and len(failing_components) > 4):
        failing_components = [
            render.Text("%d Services" % len(failing_components), color = "#a00" if op_state != "partial_outage" else "#FFFF00"),
            render.Text("    Down", color = "#a00" if op_state != "partial_outage" else "#FFFF00"),
        ]

    imgSrc = GITHUB_ICON
    if op_state == "partial_outage":
        imgSrc = GITHUB_ICON_YELLOW
    elif op_state != "good":
        imgSrc = GITHUB_ICON_RED

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = imgSrc, width = 15),
                    render.Column(
                        children = failing_components,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
