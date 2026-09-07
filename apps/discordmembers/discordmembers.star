"""
Applet: Discord Members
Summary: Discord Members Count
Description: Display the approximate member count for a given Discord server (via Invite ID).
Author: Dennis Zoma (https://zoma.dev)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/twitter_icon.png", TWITTER_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TWITTER_ICON = TWITTER_ICON_ASSET.readall()

DISCORD_API_URL = "https://discord.com/api/v10/invites/%s?with_counts=true"
DEFAULT_INVITE_ID = "r45MXG4kZc"
MAX_RESPONSE_BYTES = 256 * 1024

def safe_invite_id(value):
    value = str(value or "").strip()
    if not value or len(value) > 64:
        return ""
    for char in value.elems():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_":
            return ""
    return value

def main(config):
    invite_id = safe_invite_id(config.get("invite_id", DEFAULT_INVITE_ID))
    body = None

    if invite_id:
        response = http.get(DISCORD_API_URL % invite_id, ttl_seconds = 300)
        response_body = response.body()
        if response.status_code == 200 and response_body and len(response_body) <= MAX_RESPONSE_BYTES:
            body = json.decode(response_body, None)

    guild = body.get("guild") if type(body) == "dict" else None
    member_count = body.get("approximate_member_count") if type(body) == "dict" else None
    if type(guild) != "dict" or type(member_count) not in ["int", "float"] or member_count < 0:
        formatted_members_count = "Not Found"
        server_name = "Check your invite ID"
    else:
        formatted_members_count = "%s members" % humanize.comma(min(int(member_count), 1000000000))
        server_name = str(guild.get("name") or "Discord server")[:120]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(TWITTER_ICON),
                            render.WrappedText(formatted_members_count),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        offset_start = 10,
                        child = render.Text(
                            color = "#3c3c3c",
                            content = server_name,
                        ),
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
                id = "invite_id",
                name = "Invite ID",
                icon = "userPlus",
                desc = "Valid Discord Server Invite ID (Important: Set expiration to infinite)",
            ),
        ],
    )
