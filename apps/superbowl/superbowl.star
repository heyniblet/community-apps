load("render.star", "render")
load("time.star", "time")

DATES = [(2027, 2, 14), (2028, 2, 13), (2029, 2, 11), (2030, 2, 10), (2031, 2, 9)]

def main():
    now = time.now()
    target = time.time(year = now.year + 1, month = 2, day = 9)
    for year, month, day in DATES:
        candidate = time.time(year = year, month = month, day = day)
        if candidate.unix > now.unix:
            target = candidate
            break
    days = int((target - now).hours / 24)
    return render.Root(child = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(content = "SUPER BOWL", font = "tom-thumb", color = "#8ec5ff"),
            render.Text(content = "%d DAYS" % days, font = "6x13", color = "#ffffff"),
        ],
    ))
