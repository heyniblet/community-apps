load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

EPOCH = time.time(year = 2000, month = 1, day = 1, hour = 12)
PLANETS = [
    (88.0, 4, "#aaa"),
    (224.7, 6, "#e2b56f"),
    (365.25, 8, "#4c9cff"),
    (687.0, 10, "#e05b3f"),
    (4332.6, 12, "#c99a62"),
    (10759.2, 14, "#eadb91"),
]

def main():
    days = (time.now() - EPOCH).hours / 24.0
    children = [render.Padding(pad = (30, 14, 0, 0), child = render.Circle(diameter = 4, color = "#ffd928"))]
    for period, radius, color in PLANETS:
        angle = days * 2 * math.pi / period
        x = int(31 + math.cos(angle) * radius * 2)
        y = int(15 + math.sin(angle) * radius)
        children.append(render.Padding(pad = (x, y, 0, 0), child = render.Circle(diameter = 2, color = color)))
    return render.Root(child = render.Stack(children = children))
