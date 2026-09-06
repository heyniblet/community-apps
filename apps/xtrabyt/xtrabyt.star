"""
Applet: Xtrabyt
Summary: Display Xtrabyt.com View
Description: Display a custom drawing or integration view from Xtrabyt.com.
Author: vmitchell85
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://xtrabyt.com"

def main(config):
    key = config.get("key") or None

    if (key == None):
        return renderWelcome()
    if type(key) != "string" or len(key) > 128 or not all([char.isalnum() or char in "_-" for char in key.elems()]):
        return renderError("invalid key")

    response = http.get(BASE_URL + "/views/" + key)

    if response.status_code == 200:
        data = response.json()
        if type(data) == "dict" and data.get("type") == "image":
            return renderImage(data.get("content"))
        return renderError(data.get("type", "invalid response") if type(data) == "dict" else "invalid response")
    elif response.status_code == 503:
        return renderMaintenance()
    else:
        return renderError(response.status_code)

def renderError(status):
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Xtrabyt Error",
                        font = "CG-pixel-3x5-mono",
                    ),
                    render.Text(
                        content = str(status),
                        font = "6x13",
                    ),
                ],
            ),
        ),
    )

def renderWelcome():
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Welcome To",
                        font = "CG-pixel-4x5-mono",
                    ),
                    render.Text(
                        content = "XTRABYT",
                        font = "6x13",
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "Get started at Xtrabyt.com",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ],
            ),
        ),
    )

def renderMaintenance():
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Xtrabyt.com is ",
                        font = "CG-pixel-4x5-mono",
                    ),
                    render.Text(
                        content = "down for",
                        font = "6x13",
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "maintnenace",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ],
            ),
        ),
    )

def renderImage(imgUrl):
    if type(imgUrl) != "string" or not imgUrl.startswith(BASE_URL + "/"):
        return renderError("invalid image")
    response = http.get(imgUrl)
    if response.status_code != 200:
        return renderError(response.status_code)
    img = response.body()
    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Image(
                        src = img,
                        width = 64,
                        height = 32,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "Xtrabyt Key",
                desc = "The Xtrabyt.com key for your view",
                icon = "key",
                secret = True,
            ),
        ],
    )
