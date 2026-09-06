"""
Applet: HaikuboxLinker
Summary: Displays haikubox bird data
Description: Displays the daily count of different bird species recorded and identified by the Haikubox.
Author: jachansky
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_RESPONSE_BYTES = 1024 * 1024
MAX_SPECIES = 200

# Use API request to gather data on birds spotted today
def fetchBirdData(serial_code, date):
    # API Request
    url = "https://api.haikubox.com/haikubox/" + serial_code + "/daily-count?date=" + date
    response = http.get(url)
    body = response.body()

    # If request successful
    if response.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES:
        bird_data = json.decode(body, [])
        if type(bird_data) != "list":
            return ["Invalid bird data"]

        # Create a list with each bird count as a string formatted like "<bird species>: <number of detections>"
        species_counts = []
        for bird_info in bird_data[:MAX_SPECIES]:
            if type(bird_info) != "dict":
                continue
            bird = bird_info.get("bird")
            count = bird_info.get("count")
            if type(bird) != "string" or not bird or type(count) not in ["int", "float"]:
                continue
            bird = bird[:100]
            line = bird + ": " + str(count)
            species_counts.append(line)
        return species_counts or ["No birds detected today"]
        #if not successful

    else:
        return ["No data found"]

def main(config):
    speed_value = config.str("speed", "300") or "300"
    speed = int(speed_value) if speed_value in ["100", "300"] else 300
    serial_code = config.str("serial_code", "") or ""
    if not valid_serial(serial_code):
        species_counts = ["Configure your Haikubox serial code"]
    else:
        now = time.now()
        date = now.format("2006-01-02")
        species_counts = fetchBirdData(serial_code, str(date))

    spaced_counts = []
    for species in species_counts:
        spaced_counts.append(species)
        spaced_counts.append(" ")

    # Extra space appended after each species to create two newlines
    formatted_counts = "\n".join(spaced_counts)

    # Return the render output
    return render.Root(
        delay = speed,
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            child = render.WrappedText(
                content = formatted_counts,
                width = 64,
                font = "tom-thumb",
            ),
            scroll_direction = "vertical",
            offset_start = 8,
            offset_end = 32,
            # offset_end was giving me issues and removing it fixed it,
            # offset_end = len(species_counts) * 18,
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "fast",
            value = "100",
        ),
        schema.Option(
            display = "slow",
            value = "300",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serial_code",
                name = "Device Serial Code",
                desc = "Enter the serial code of your device (ex: 1000000066e59043)",
                icon = "crow",
                default = "",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "The speed at which the text vertically pans",
                icon = "gauge",
                default = options[1].value,
                options = [
                    schema.Option(
                        display = "fast",
                        value = "100",
                    ),
                    schema.Option(
                        display = "slow",
                        value = "300",
                    ),
                ],
            ),
        ],
    )

def valid_serial(value):
    return type(value) == "string" and len(value) >= 8 and len(value) <= 64 and all([char.isalnum() or char in "-_" for char in value.elems()])
