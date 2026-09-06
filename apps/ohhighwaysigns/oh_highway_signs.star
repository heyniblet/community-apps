"""
Applet: OH Highway Signs
Summary: Displays OH highway messages
Description: Displays messages from overhead signs on Ohio highways.
Author: noahcolvin
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# get all data for entire state
URL = "https://publicapi.ohgo.com/api/v1/digital-signs?sign-type=dms"
MAX_RESPONSE_BYTES = 512 * 1024

def main(config):
    api_key = config.str("api_key", "")
    sign_id = parse_sign_id(config.str("sign_id", "101"))

    favor_times = config.bool("favor_times") or False

    text = get_sign_text(api_key, sign_id, favor_times)
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                marquee_with_text(text[0]),
                marquee_with_text(text[1]),
                marquee_with_text(text[2]),
                render.Box(width = 64, height = 1, color = "#000"),  # hack to fill width
            ],
        ),
    )

def marquee_with_text(text):
    length = len(text) * 5
    if length > 64:
        length = 64

    return render.Marquee(
        width = length,
        child = render.Text(
            color = "#fa0",
            content = text,
            font = "5x8",
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "OHGO API Key",
                desc = "Your OHGO API key. See https://publicapi.ohgo.com/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "sign_id",
                name = "Sign ID",
                desc = "OHGO digital sign ID. Existing nearby-sign selections continue to work.",
                icon = "rectangleList",
                default = "101",
            ),
            schema.Toggle(
                id = "favor_times",
                name = "Favor Times",
                desc = "Attempt to display travel times over message if available.",
                icon = "clock",
                default = False,
            ),
        ],
    )

def parse_sign_id(value):
    value = value.strip()
    if value.startswith("{"):
        legacy_values = re.findall('"value"\\s*:\\s*"([^"\\\\]+)"', value)
        value = legacy_values[0] if legacy_values else ""
    return value if value and len(value) <= 64 else "101"

def get_sign_text(api_key, sign_id, favor_times):
    if not api_key:
        return ["Add OHGO", "API key", "to begin"]
    signs = load_signs(api_key)
    sign = find_sign(signs, sign_id)

    if sign == None:
        return ["No", "Messages", "Available"]

    messages = sign.get("messages", [])
    message = select_message(messages, favor_times)

    if sign_is_mile_min(message):
        format_mile_min(message)
        return message

    if sign_is_time_via(message):
        format_time_via(message)
        return message

    format_message(message)
    return message

def select_message(messages, favor_times):
    if type(messages) != "list" or len(messages) == 0:
        return ["No", "Messages", "Available"]

    message0Split = message_lines(messages[0])

    if len(messages) == 1:
        return message0Split

    message1Split = message_lines(messages[1])

    if favor_times:
        if sign_is_mile_min(message0Split) or sign_is_time_via(message0Split):
            return message0Split
        return message1Split
    else:
        if not (sign_is_mile_min(message0Split) or sign_is_time_via(message0Split)):
            return message0Split
        return message1Split

def message_lines(message):
    lines = str(message).split("\r\n")[:3]
    return (lines + [""] * (3 - len(lines)))[:3]

def sign_is_mile_min(message):
    line = message[0]
    return line.endswith("MIN")

def sign_is_time_via(message):
    line = message[0]
    return line.find("VIA") > -1

def format_time_via(message):
    message[0] = message[0].strip()
    message[1] = format_time_via_line(message[1])
    message[2] = format_time_via_line(message[2])

    return message

def format_time_via_line(line):
    leftLastIdx = 0
    for x in range(len(line) - 1):
        if line[x:x + 2] == "  ":
            leftLastIdx = x
            break

    leftSide = line[0:leftLastIdx]

    rightLastIdx = 0
    for x in range(len(line) - 1, 0, -1):
        if line[x:x - 2:-1] == "  ":
            rightLastIdx = x + 1
            break

    rightSide = line[rightLastIdx:]

    return format_line_spacing(leftSide, rightSide)

def format_mile_min(message):
    message[0] = message[0].replace("  ", " ")[-12:]
    message[1] = format_mile_min_line(message[1])
    message[2] = format_mile_min_line(message[2])

    return message

def format_mile_min_line(line):
    leftLastIdx = 0
    spaceCount = 0
    for x in range(len(line) - 1):
        if line[x] == " ":
            spaceCount = spaceCount + 1
        else:
            spaceCount = 0

        if spaceCount > 1:
            spaceCount = 0
            leftLastIdx = x - 1
            break

    leftSide = line[0:leftLastIdx]

    rightLastIdx = 0
    numFound = False
    numFound2 = False
    spaceFound = False
    for x in range(len(line) - 1, 0, -1):
        if not numFound and line[x].isdigit():
            numFound = True
        if not numFound2 and spaceFound and line[x].isdigit():
            numFound2 = True
        if line[x].isspace() and numFound2:
            rightLastIdx = x + 1
            break
        if line[x].isspace():
            spaceFound = True

    rightSide = line[rightLastIdx:]
    currentSpaces = rightSide.count(" ")
    rightSide = rightSide.replace("".join([" " for x in range(currentSpaces)]), "".join([" " for x in range(currentSpaces - 1)]))

    return format_line_spacing(leftSide, rightSide)

def format_line_spacing(leftSide, rightSide):
    if len(leftSide) + len(rightSide) >= 12:
        return "{} {}".format(leftSide, rightSide)

    spacesNeeded = 12 - (len(leftSide) + len(rightSide))
    spaces = "".join([" " for x in range(spacesNeeded)])
    return "{}{}{}".format(leftSide, spaces, rightSide)

def format_message(message):
    message[0] = message[0].strip()
    message[1] = message[1].strip()
    message[2] = message[2].strip()

def headers(api_key):
    return {"Authorization": "APIKEY {}".format(api_key)}

def load_signs(api_key):
    resp = http.get(URL, headers = headers(api_key), ttl_seconds = 300)

    if resp.status_code != 200:
        return None
    body = resp.body()
    if not body or len(body) > MAX_RESPONSE_BYTES:
        return None
    data = resp.json()
    return data.get("results") if type(data) == "dict" and type(data.get("results")) == "list" else None

def find_sign(results, sign_id):
    if results == None:
        return None

    for result in results:
        if sign_id == None:
            return result
        if type(result) == "dict" and str(result.get("id", "")) == sign_id:
            return result

    return None
