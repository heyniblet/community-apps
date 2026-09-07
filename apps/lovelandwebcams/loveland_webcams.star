"""
Applet: Loveland Webcams
Summary: Loveland Ski Area Webcams
Description: Displays random webcam images from Loveland Ski Area.
Author: John Sprunger
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

def main():
    addresses = [
        "https://images.weserv.nl/?url=cams.skiloveland.com/snowcam/snowcam.jpg&w=128&h=64&fit=cover&output=png",
        "https://images.weserv.nl/?url=cams.skiloveland.com/lsacams/ptarmroost.jpg&w=128&h=64&fit=cover&output=png",
        "https://images.weserv.nl/?url=cams.skiloveland.com/lsacams/chetstop.jpg&w=128&h=64&fit=cover&output=png",
    ]

    #pulling images from here with a time stamp appended https://skiloveland.com/webcams/

    rand = random.number(0, len(addresses) - 1)

    url = addresses[rand]
    print(url)

    response = http.get(url, ttl_seconds = 300)
    img = response.body()
    if response.status_code != 200 or not img or len(img) > 4 * 1024 * 1024:
        return render.Root(render.WrappedText("Webcam unavailable", font = "tb-8"))

    #if it's image #1 scroll vertical, else scroll horizontal
    if (rand == 0):
        return render.Root(
            delay = 500,
            child = render.Box(
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 0,
                    offset_end = 32,
                    child = render.Image(
                        src = img,
                        width = 64,
                        height = 64,
                    ),
                ),
            ),
        )
    else:
        return render.Root(
            delay = 750,
            child = render.Box(
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 64,
                    offset_start = 0,
                    offset_end = 64,
                    child = render.Image(
                        src = img,
                        width = 95,
                        height = 35,
                    ),
                ),
            ),
        )
