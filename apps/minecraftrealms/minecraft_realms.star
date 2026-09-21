# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Minecraft Realms
Summary: Minecraft Realms Status
Description: Displays Minecraft Realms information from a user-owned HTTPS relay.
Author: Michael Maxwell
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    url = config.str("endpoint_url")
    token = config.str("relay_token")
    if not valid_url(url) or not token:
        return render_message("Add Realms relay URL")
    response = http.get(url, headers = {"Authorization": "Bearer " + token})
    if response.status_code != 200 or len(response.body()) > 256 * 1024:
        return render_message("Realms relay unavailable")
    data = json.decode(response.body(), {})
    servers = data.get("servers") if type(data) == "dict" else None
    if type(servers) != "list":
        return render_message("Invalid Realms response")
    servers = [server for server in servers[:64] if valid_server(server)]
    if not servers:
        return render_message("No Realms Found")
    server = sample(servers)
    return render_realms(
        server["name"][:100],
        min(max(int(server["slot"]), 0), 2),
        min(max(int(server["players"]), 0), 100000),
        min(max(int(server["maxPlayers"]), 1), 100000),
        server["motd"][:300],
    )

def valid_url(value):
    return type(value) == "string" and value.startswith("https://") and len(value) <= 4096 and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def valid_server(server):
    return (
        type(server) == "dict" and
        type(server.get("name")) == "string" and
        type(server.get("motd")) == "string" and
        type(server.get("slot")) in ["int", "float"] and
        type(server.get("players")) in ["int", "float"] and
        type(server.get("maxPlayers")) in ["int", "float"]
    )

def sample(servers):
    return servers[0 if len(servers) <= 1 else random.number(0, len(servers) - 1)]

def render_message(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

def render_realms(name, slot, players, max_players, motd):
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(child = render.Circle(color = ["#0ff", "#f0f", "#ff0"][slot], diameter = 6), pad = (1, 1, 2, 1)),
                        render.Text(name),
                    ],
                    expanded = True,
                ),
                render.Row(children = [render.Text("Online: %d/%d" % (players, max_players))], main_align = "center", expanded = True),
                render.Marquee(width = 64, child = render.Text(motd), offset_start = 5, offset_end = 32),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                name = "Realms relay URL",
                desc = "A user-owned HTTPS endpoint returning a servers array with name, slot, players, maxPlayers, and motd.",
                icon = "link",
            ),
            schema.Text(
                id = "relay_token",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                icon = "key",
                secret = True,
            ),
        ],
    )
