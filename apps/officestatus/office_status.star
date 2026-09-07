"""
Applet: Office Status
Summary: Show coworkers your status
Description: Show a manually configured availability and message.
Author: Brian Bell
"""

load("images/icon_check.png", CHECK_ASSET = "file")
load("images/icon_clock.png", CLOCK_ASSET = "file")
load("images/icon_do_not_enter.png", BUSY_ASSET = "file")
load("images/icon_heart.png", HEART_ASSET = "file")
load("images/icon_house.png", HOUSE_ASSET = "file")
load("images/icon_music.png", MUSIC_ASSET = "file")
load("images/icon_plane.png", PLANE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICONS = {
    "check": CHECK_ASSET.readall(),
    "clock": CLOCK_ASSET.readall(),
    "do_not_enter": BUSY_ASSET.readall(),
    "heart": HEART_ASSET.readall(),
    "house": HOUSE_ASSET.readall(),
    "music": MUSIC_ASSET.readall(),
    "plane": PLANE_ASSET.readall(),
}

def main(config):
    name = config.str("name", "Jane Smith")[:40]
    status = config.str("custom_status", "Focusing")[:40]
    message = config.str("custom_status_message", "Until later")[:80]
    color = config.str("custom_status_color", "#ffff00")
    icon = ICONS.get(config.str("custom_status_icon", "check"), ICONS["check"])
    return render.Root(
        child = render.Row(
            children = [
                render.Box(color = color, width = 10, child = render.Image(src = icon, width = 10)),
                render.Padding(
                    pad = (1, 2, 0, 1),
                    child = render.Column(
                        children = [
                            line(name + " is", "tom-thumb"),
                            line(status.upper(), "6x13"),
                            line(message, "tom-thumb"),
                        ],
                        expanded = True,
                        main_align = "space_between",
                    ),
                ),
            ],
        ),
    )

def line(content, font):
    return render.Marquee(
        child = render.Text(content = content, font = font),
        width = 53,
        offset_start = 0,
        offset_end = 0,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "name", name = "Name", desc = "Name shown on the display.", icon = "user", default = "Jane Smith"),
            schema.Text(id = "custom_status", name = "Status", desc = "Availability, such as Free, Busy, or Remote.", icon = "message", default = "Focusing"),
            schema.Text(id = "custom_status_message", name = "Message", desc = "Short detail shown below the status.", icon = "comment", default = "Until later"),
            schema.Color(id = "custom_status_color", name = "Color", desc = "Status accent color.", icon = "palette", default = "#ffff00"),
            schema.Dropdown(
                id = "custom_status_icon",
                name = "Icon",
                desc = "Status icon.",
                icon = "icons",
                default = "check",
                options = [
                    schema.Option(display = label, value = value)
                    for label, value in [
                        ("Available", "check"),
                        ("Busy", "do_not_enter"),
                        ("Clock", "clock"),
                        ("Remote", "house"),
                        ("Away", "plane"),
                        ("Music", "music"),
                        ("Heart", "heart"),
                    ]
                ],
            ),
        ],
    )
