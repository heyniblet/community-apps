load("render.star", "render")
load("time.star", "time")

def main():
    now = time.now()
    value = now.format("15:04")
    frames = []
    for separator in [":", " "]:
        frames.append(render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = value.replace(":", separator), font = "tom-thumb", color = "#f3a45f"),
                render.Box(width = 42, height = 1, color = "#6b2c22"),
            ],
        ))
    return render.Root(delay = 500, child = render.Animation(children = frames))
