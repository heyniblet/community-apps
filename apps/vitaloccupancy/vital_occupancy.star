"""
Applet: Vital Occupancy
Summary: Vital Gym Current Occupancy
Description: The Current Occupancy of Vital Climbing's Brooklyn, NY location.
Author: flip-z
"""

load("http.star", "http")
load("images/logo.png", LOGO_ASSET = "file")
load("render.star", "render")

GYM_URL = "https://display.safespace.io/value/live/a7796f34"

def main():
    req = http.get(GYM_URL, ttl_seconds = 60)
    currocc = req.body().strip()
    if req.status_code != 200 or not currocc or len(currocc) > 6 or not currocc.isdigit():
        return render.Root(child = render.WrappedText(content = "Occupancy unavailable", width = 64, color = "#f00"))
    occupancy = int(currocc)
    if occupancy > 5000:
        return render.Root(child = render.WrappedText(content = "Invalid occupancy", width = 64, color = "#f00"))

    color = "#cd0800"  # red
    if occupancy < 120:
        color = "#26ff7b"  # green
    elif occupancy < 150:
        color = "#ffd766"  # yellow

    if occupancy == 69:
        currocc_child = render.Animation(
            children = [
                render.Text(currocc, font = "10x20", color = color),
                render.Text(currocc, font = "10x20", color = "#aa39d3"),
                render.Text(currocc, font = "10x20", color = "#d2b1ea"),
                render.Text(currocc, font = "10x20", color = "#d6daff"),
            ],
        )
    else:
        currocc_child = render.Text(currocc, font = "10x20", color = color)

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    currocc_child,
                    render.Image(src = LOGO_ASSET.readall()),
                ],
            ),
        ),
    )
