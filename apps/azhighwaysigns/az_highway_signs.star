"""
Applet: AZ Highway Signs
Summary: Mirrors AZ highway signs
Description: Uses the AZ 511 API to show the current message from any highway sign.
Author: CJ Sturgess
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

AZ_511_API_URL = "https://az511.com/api/v2/get/messagesigns"
DEFAULT_SIGN = """{"value": "AZ--858d88ac-89d8-4760-97cc-642bfe3ca07c"}"""
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_SIGNS = 2000

def get_all_signs(api_key):
    if type(api_key) != "string" or not api_key or len(api_key) > 2048 or "\r" in api_key or "\n" in api_key:
        return []

    # Returns a list of all AZ Highway signs from the 511 API.
    rep = http.get(AZ_511_API_URL, params = {"key": api_key})
    if rep.status_code != 200:
        return []

    body = rep.body()
    signs = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None
    return [sign for sign in signs[:MAX_SIGNS] if valid_sign(sign)] if type(signs) == "list" else []

def valid_sign(sign):
    return type(sign) == "dict" and type(sign.get("Id")) == "string" and len(sign.get("Id")) <= 128 and type(sign.get("Name")) == "string" and len(sign.get("Name")) <= 240 and type(sign.get("Messages", [])) == "list"

def get_sign(api_key, id):
    # Returns a single sign from the AZ 511 API for a given ID.

    all_signs = get_all_signs(api_key)
    for sign in all_signs:
        if sign["Id"] == id:
            return sign
    return None

def get_message_lines(sign):
    if sign == None:
        return []

    messages = [message for message in sign.get("Messages", [])[:10] if type(message) == "string" and len(message) <= 1000]
    if not messages:
        return ["NO_MESSAGE"]
    message_idx = 0

    if len(messages) > 1:
        message_idx = random.number(0, len(messages) - 1)

    message = messages[message_idx]
    message_lines = message.split("\r\n")

    return message_lines

def render_message_default(lines):
    message_rows = []

    for line in lines:
        message_rows.append(
            render.Marquee(
                width = 64,
                align = "center",
                child = render.Text(line),
            ),
        )

    return message_rows

def render_message_minutesto(lines):
    message_rows = []

    # Render the first line as normal
    lines[0] = lines[0].replace("PHOENIX", "PHX")
    message_rows.append(
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(lines[0]),
        ),
    )

    # Render the subsequent lines
    # Location name is left-adjusted, distance is right-adjusted
    for line in lines[1:]:
        msg_dist_to = line[:-3].strip()
        msg_dist = line[-3:].strip()

        message_rows.append(
            render.Row(
                children = [
                    render.Marquee(
                        width = 48,
                        delay = 16,
                        child = render.Text(msg_dist_to),
                    ),
                    render.Marquee(
                        width = 16,
                        align = "end",
                        child = render.Text(
                            content = msg_dist,
                            color = "#ff6",
                        ),
                    ),
                ],
            ),
        )

    return message_rows

def render_message_nomessage(sign):
    message_rows = []

    for idx, line in enumerate(sign["Name"].split("@")):
        if idx == 1:
            line = "@" + line

        message_rows.append(
            render.Marquee(
                width = 64,
                align = "center",
                child = render.Text(line.strip()),
            ),
        )

    message_rows.append(
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                content = "NO MESSAGE",
                color = "#f00",
            ),
        ),
    )

    return message_rows

def render_message_apierror():
    return [
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                content = "API Key Missing",
                color = "#f00",
            ),
        ),
    ]

def render_message(sign):
    if sign == None:
        return render_message_apierror()

    lines = get_message_lines(sign)

    # If this is a "minutes-to" message, render appropriately
    if lines and "MIN" in lines[0]:
        return render_message_minutesto(lines)

    # If this message is "NO_MESSAGE", make it cleaner
    if lines and lines[0] == "NO_MESSAGE":
        return render_message_nomessage(sign)

    # Otherwise, render using default method
    return render_message_default(lines)

def main(config):
    api_key = config.get("api_key")
    sign_id = parse_sign_id(config.get("sign", DEFAULT_SIGN))

    sign = get_sign(api_key, sign_id)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = render_message(sign),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "AZ 511 API Key",
                desc = "Your AZ 511 API key. See https://www.az511.com/help/api for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "sign",
                name = "Message Sign ID",
                desc = "AZ 511 message-board ID. Existing nearby-sign selections continue to work.",
                icon = "car",
            ),
        ],
    )

def parse_sign_id(value):
    value = str(value or "").strip()
    if value.startswith("{"):
        legacy = re.findall(r'"value"\s*:\s*"([^"\\]+)"', value)
        value = legacy[0] if legacy else ""
    return value if value and len(value) <= 128 and "\r" not in value and "\n" not in value else "AZ--858d88ac-89d8-4760-97cc-642bfe3ca07c"
