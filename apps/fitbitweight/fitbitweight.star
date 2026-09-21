# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See readme.md for maintenance and compatibility notes.

"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Fitbit Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#b9d9eb"
KILOGRAMS_TO_POUNDS_MULTIPLIER = 2.2
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

# Canvas
SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

def main(config):
    url = config.str("endpoint_url")
    token = config.str("relay_token")
    if not valid_url(url) or not token:
        return []
    period = config.get("period") or "0"
    system = config.get("system") or "imperial"
    secondary_display = config.get("second") or "none"
    response = http.get(url, headers = {"Authorization": "Bearer " + token})
    if response.status_code != 200 or len(response.body()) > 512 * 1024:
        return []
    data = json.decode(response.body(), {})
    if type(data) != "dict":
        return []
    weight_json = {"body-weight": series(data.get("weight"))}
    fat_json = {"body-fat": series(data.get("fat"))}
    bmi_json = {"body-bmi": series(data.get("bmi"))}

    # Default values
    current_weight = 0
    first_weight = 0
    current_fat = 0
    current_bmi = 0
    first_weight_date = None

    # Process data
    if weight_json != None and len(weight_json["body-weight"]) > 0:
        current_weight = float(weight_json["body-weight"][-1]["value"])
        first_weight = float(get_starting_value(weight_json, period, "value"))
        if first_weight < 0:
            first_weight = 0
        first_weight_date = get_starting_value(weight_json, period, "dateTime")

    if fat_json != None and len(fat_json["body-fat"]) > 0:
        current_fat = float(fat_json["body-fat"][-1]["value"])

    if bmi_json != None and len(bmi_json["body-bmi"]) > 0:
        current_bmi = float(bmi_json["body-bmi"][-1]["value"])

    # Convert to imperial if needed
    if system == "metric":
        display_units = "KGs"
    else:
        display_units = "LBs"
        current_weight *= KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight *= KILOGRAMS_TO_POUNDS_MULTIPLIER

    weight_change = current_weight - first_weight
    sign = "+" if weight_change > 0 else ""

    weight_plot = get_plot_from_data(weight_json, period)
    fat_plot = get_plot_from_data(fat_json, period)

    display_weight = "%s%s " % (humanize.comma(int(current_weight * 100) // 100.0), display_units)

    # Build numbers row
    if secondary_display == "bodyfat" and current_fat > 0:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "%s%% body fat" % (humanize.comma(int(current_fat * 100) // 100.0)),
                        color = FAT_COLOR,
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )
    elif secondary_display == "bmi" and current_bmi > 0:
        display_color = get_bmi_display(current_bmi)
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "BMI: %s %s" % (humanize.comma(int(current_bmi * 100) // 100.0), display_color[0]),
                        color = display_color[1],
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )
    else:
        first_weight_display = "" if first_weight_date == -1 else "since %s " % first_weight_date
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WHITE_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "%s%s %s %s" %
                        (
                            sign,
                            humanize.comma(int(weight_change * 100) // 100.0),
                            display_units,
                            first_weight_display,
                        ),
                        color = WEIGHT_COLOR,
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )

    # Build display rows
    rows = [numbers_row]
    rows.append(render.Box(height = 1))  # 1 pixel horizontal separator

    if secondary_display == "bmi":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, SCREEN_HEIGHT - 6))
    elif secondary_display == "bodyfat":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, int((SCREEN_HEIGHT - 6) / 2)))
        rows.append(get_plot_display_from_plot(fat_plot, FAT_COLOR, int((SCREEN_HEIGHT - 6) / 2)))
    else:
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, SCREEN_HEIGHT - 6))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

def valid_url(value):
    return type(value) == "string" and value.startswith("https://") and len(value) <= 4096 and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def series(value):
    result = []
    if type(value) != "list":
        return result
    for item in value[:2000]:
        if type(item) != "dict":
            continue
        date = item.get("dateTime")
        measurement = item.get("value")
        if type(date) == "string" and len(date) == 10 and date[4] == "-" and date[7] == "-" and date[:4].isdigit() and date[5:7].isdigit() and date[8:].isdigit() and type(measurement) in ["int", "float"]:
            result.append({"dateTime": date, "value": measurement})
    return result

def get_starting_value(json_data, period, itemName = "value"):
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            date_diff = time.now() - current_date
            days = math.floor(date_diff.hours // 24)
            number_of_days = int(period)
            if number_of_days == 0 or days < number_of_days:
                return item[itemName]
    return -1

def get_timestamp_from_date(date_string):
    date_parts = str(date_string).split("-")
    return time.time(year = int(date_parts[0]), month = int(date_parts[1]), day = int(date_parts[2]))

def get_days_between(day1, day2):
    date_diff = day1 - day2
    days = math.floor(date_diff.hours // 24)
    return days

def get_plot_from_data(json_data, period):
    if not json_data:
        return [(0, 0)]

    points_in_period = []
    number_of_days = int(period)

    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            days = get_days_between(time.now(), current_date)
            if number_of_days == 0 or days < number_of_days:
                points_in_period.append({
                    "date": current_date,
                    "value": float(item["value"]),
                })

    if not points_in_period:
        return [(0, 0)]

    # Find oldest date
    oldest_date = points_in_period[0]["date"]
    for p in points_in_period[1:]:
        if p["date"] < oldest_date:
            oldest_date = p["date"]

    # Build plot
    plot = []
    for p in points_in_period:
        x_val = get_days_between(p["date"], oldest_date)
        plot.append((x_val, p["value"]))

    return plot

def get_plot_display_from_plot(plot, color = WHITE_COLOR, height = 13):
    return render.Plot(
        data = plot,
        width = SCREEN_WIDTH,
        height = height,
        color = color,
        fill = True,
    )

def get_bmi_display(bmi):
    if bmi < 19:
        return ("Underweight", "#01b0f1")
    elif bmi < 25:
        return ("Healthy", "#5fa910")
    elif bmi < 30:
        return ("Overweight", "#ff0")
    elif bmi < 40:
        return ("Obese", "#e77a22")
    else:
        return ("Extremely Obese", "#f00")

#------------------------
# Schema
#------------------------
def get_schema():
    period_options = [
        schema.Option(value = "7", display = "7 Days"),
        schema.Option(value = "30", display = "30 Days"),
        schema.Option(value = "60", display = "2 Months"),
        schema.Option(value = "90", display = "3 Months"),
        schema.Option(value = "180", display = "6 Months"),
        schema.Option(value = "360", display = "1 Year"),
        schema.Option(value = "720", display = "2 Years"),
        schema.Option(value = "1825", display = "5 Years"),
        schema.Option(value = "0", display = "Maximum Allowed"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

    secondary_options = [
        schema.Option(value = "none", display = "None - just display weight"),
        schema.Option(value = "bodyfat", display = "Body Fat Percentage"),
        schema.Option(value = "bmi", display = "BMI"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                name = "Weight data relay URL",
                desc = "A user-owned HTTPS endpoint returning weight, fat, and bmi measurement arrays as JSON.",
                icon = "link",
            ),
            schema.Text(
                id = "relay_token",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "The length of time to chart.",
                icon = "stopwatch",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "system",
                name = "Measurement",
                desc = "Choose Imperial or Metric",
                icon = "ruler",
                options = measurement_options,
                default = "metric",
            ),
            schema.Dropdown(
                id = "second",
                name = "Secondary Measurement",
                desc = "Choose the secondary item to plot",
                icon = "squarePollVertical",
                options = secondary_options,
                default = "none",
            ),
        ],
    )
