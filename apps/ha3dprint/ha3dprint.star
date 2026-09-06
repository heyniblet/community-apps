"""
Applet: ha3dprint
Summary: View HA 3D printer status
Description: Display the current job name, progress and remaining time for a selected 3D printer via Home Assistant.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

C_DEFAULT_END_TIME = "1970-01-01 00:00:00"
C_MAX_PRINT_AGE_SECONDS = 4 * 3600

C_DISPLAY_WIDTH = 64
C_BACKGROUND = [0, 0, 0]
C_TEXT_COLOR = [255, 255, 255]

C_MIN_WIDTH = 1
C_HEIGHT = 8

# colors
RED = "#FF0000"
WHITE = "#FFFFFF"
GREEN = "#00FF00"

# Statuses considered as actively printing (used for hide logic)
C_ACTIVE_STATUSES = [
    "printing",
    "running",
    "finishing",
    "heating",
    "calibrating",
    "busy",
    "pausing",
    "paused",
    "cancelling",
]
MAX_RESPONSE_BYTES = 1024 * 1024

def fetch_ha_data(ha_url, ha_token, name_entity, progress_entity, remaining_time_entity, end_time_entity, status_entity):
    """Fetch printer data from Home Assistant REST API using template endpoint for efficiency"""
    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }

    # Clean up URL - remove trailing slash
    base_url = ha_url.rstrip("/")

    # Default values in case of errors
    defaults = {
        "name": "Printer",
        "progress": "0",
        "remaining_time": "0",
        "end_time": "0",
        "status": "Unknown",
    }

    # Create a template that fetches all entities in a single request
    template = """
{
    "name": "{{ states('%(name)s') | default('Printer') }}",
    "progress": "{{ states('%(progress)s') | default('0') }}",
    "remaining_time": "{{ states('%(remaining_time)s') | default('0') }}",
    "end_time": "{{ as_timestamp(states('%(end_time)s'), 0) }}",
    "status": "{{ states('%(status)s') | default('Unknown') }}",
    "last_changed": "{{ as_timestamp(states['%(status)s'].last_changed | default(0)) if '%(status)s' != '' else 0 }}"
}
""" % {
        "name": name_entity,
        "progress": progress_entity,
        "remaining_time": remaining_time_entity,
        "end_time": end_time_entity,
        "status": status_entity,
    }

    # Only make API request if ha_token is not the default value
    if ha_token != "APIKEY":
        # Make single request to template endpoint
        template_url = base_url + "/api/template"
        payload = {"template": template}

        resp = http.post(template_url, headers = headers, json_body = payload)

        # Correctly return printer entity fields
        if resp.status_code == 200:
            # Parse the JSON response from the template
            response_body = resp.body()
            if response_body and len(response_body) <= MAX_RESPONSE_BYTES:
                data = json.decode(response_body, {})
                if type(data) != "dict" or any([key not in data for key in ["name", "progress", "remaining_time", "end_time", "status"]]):
                    return None
                return (
                    safe_scalar(data.get("name"), defaults["name"]),
                    safe_scalar(data.get("progress"), defaults["progress"]),
                    safe_scalar(data.get("remaining_time"), defaults["remaining_time"]),
                    safe_scalar(data.get("end_time"), defaults["end_time"]),
                    safe_scalar(data.get("status"), defaults["status"]),
                    safe_number(data.get("last_changed")),
                )
    return None

# convert color specification from JSON to hex string
def to_rgb(color, combine = None, combine_level = 0.5):
    # default to white color in case of error when parsing color
    (r, g, b) = (255, 255, 255)

    if str(type(color)) == "string":
        # parse various formats of colors as string
        if len(color) == 7:
            # color is in form of #RRGGBB
            r = int(color[1:3], 16)
            g = int(color[3:5], 16)
            b = int(color[5:7], 16)
        elif len(color) == 6:
            # color is in form of RRGGBB
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
        elif len(color) == 4 and color[0:1] == "#":
            # color is in form of #RGB
            r = int(color[1:2], 16) * 0x11
            g = int(color[2:3], 16) * 0x11
            b = int(color[3:4], 16) * 0x11
        elif len(color) == 3 and color[0:1] != "#":
            # color is in form of RGB
            r = int(color[0:1], 16) * 0x11
            g = int(color[1:2], 16) * 0x11
            b = int(color[2:3], 16) * 0x11
    elif str(type(color)) == "list" and len(color) == 3:
        # otherwise assume color is an array of R, G, B tuple
        r = color[0]
        g = color[1]
        b = color[2]

    if combine != None:
        combine_color = lambda v0, v1, level: min(max(int(math.round(v0 + float(v1 - v0) * float(level))), 0), 255)
        r = combine_color(r, combine[0], combine_level)
        g = combine_color(g, combine[1], combine_level)
        b = combine_color(b, combine[2], combine_level)

    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# render a single item's progress
def renderProgress(label, progress_value, padding, bar_color):
    stack_children = [
        render.Box(width = C_DISPLAY_WIDTH, height = C_HEIGHT + padding, color = to_rgb(C_BACKGROUND)),
    ]

    color = bar_color or "#64BFE5"

    if progress_value != None:
        if progress_value > 100:
            progress_value = 100
        elif progress_value < 0:
            progress_value = 0

        progress = progress_value / 100.0
        progress_percent = int(math.round(progress_value))
        if label != "":
            label += ": "
        label += str(progress_percent) + "%"

        progress_width = C_MIN_WIDTH + int(math.round(float(C_DISPLAY_WIDTH - C_MIN_WIDTH) * progress))

        stack_children.append(
            render.Box(
                width = progress_width,
                padding = 1,
                color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.1),
                height = C_HEIGHT,
                child = render.Box(
                    color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.5),
                ),
            ),
        )

    # stack the progress bar with label
    stack_children.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = label,
                    color = to_rgb(color, combine = C_TEXT_COLOR, combine_level = 0.8),
                    height = C_HEIGHT,
                    offset = 1,
                    font = "tom-thumb",
                ),
            ],
        ),
    )

    # render the entire row
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(
                children = stack_children,
            ),
        ],
    )

def main(config):
    ha_url = normalized_url(config.str("haUrl", "") or "")
    ha_token = config.str("haApiKey", "") or ""
    max_print_age_hours_str = config.str("maxPrintAgeHours", "4") or "4"

    # Safe float parsing: allow only digits and one dot
    max_print_age_hours = 4.0
    s = max_print_age_hours_str.strip()
    dot_count = 0
    valid = len(s) > 0
    for i in range(len(s)):
        c = s[i]
        if c == ".":
            dot_count += 1
            if dot_count > 1:
                valid = False
                break
        elif c < "0" or c > "9":
            valid = False
            break
    if valid:
        max_print_age_hours = float(s)
    max_print_age_hours = min(max(max_print_age_hours, 0), 168)
    max_print_age_seconds = int(max_print_age_hours * 3600)
    name_entity = config.str("task_name", "task_name")
    progress_entity = config.str("progress", "test_progress")
    remaining_time_entity = config.str("remaining_time", "test_remaining_time")
    status_entity = config.str("status", "test_status")
    end_time_entity = config.str("end_time", "")
    required_entities = [name_entity, progress_entity, remaining_time_entity, status_entity]
    if not ha_url or not valid_token(ha_token) or not all([valid_entity(value) for value in required_entities]) or (end_time_entity and not valid_entity(end_time_entity)):
        return render.Root(child = render.WrappedText(content = "Configure public HTTPS Home Assistant, token, and entities", width = 64, color = RED))

    # Always fetch printer data for rendering
    result = fetch_ha_data(
        ha_url,
        ha_token,
        name_entity,
        progress_entity,
        remaining_time_entity,
        end_time_entity,
        status_entity,
    )
    if result == None or len(result) < 6:
        return render.Root(child = render.WrappedText(content = "Home Assistant unavailable", width = 64, color = RED))
    (name, progress, remaining_time, end_time, status, last_changed_ts) = result

    # Check if we should render anything
    skip_render = False

    # Normalized status
    st_norm = str(status).lower()

    # Check status
    if st_norm in ["offline", "unavailable", "off", "none", "unknown"]:
        skip_render = True

    # Check end_time using Starlark's time.parse_time and duration
    if not skip_render:
        end_dt = None
        end_time_str = str(end_time)

        # Try parsing end_time sensor first
        if end_time_str not in ("", "0", "0.0", C_DEFAULT_END_TIME):
            # Try parsing as timestamp first
            if end_time_str.replace(".", "", 1).isdigit():
                ts = int(float(end_time_str))
                if ts > 0:
                    end_dt = time.from_timestamp(ts)

        # Fallback to last_changed if print is not active
        is_active = st_norm in C_ACTIVE_STATUSES
        if not end_dt or end_dt.unix == 0:
            if not is_active:
                if last_changed_ts and float(last_changed_ts) > 0:
                    end_dt = time.from_timestamp(int(float(last_changed_ts)))

        if end_dt:
            now_dt = time.now()
            diff_seconds = end_dt.unix - now_dt.unix

            # Only skip if the print is NOT active and it finished too long ago
            if not is_active and diff_seconds < -max_print_age_seconds:
                skip_render = True

    if skip_render:
        return []

    # Format time left (handles float hours, minutes)
    time_left = ""
    seconds = 0
    if str(type(remaining_time)) == "string":
        did_parse = False
        if remaining_time.find(".") != -1:
            digits = "0123456789."
            valid = True
            for i in range(len(remaining_time)):
                c = remaining_time[i]
                if digits.find(c) == -1:
                    valid = False
                    break
            if valid:
                hours_float = float(remaining_time)
                seconds = int(hours_float * 3600)
                did_parse = True
        if not did_parse and remaining_time.isdigit():
            seconds = int(remaining_time)
    elif str(type(remaining_time)) == "int":
        seconds = remaining_time
    elif str(type(remaining_time)) == "float":
        seconds = int(remaining_time * 3600)
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    if seconds > 0:
        if hours > 0:
            min_str = str(minutes)
            if minutes < 10:
                min_str = "0" + min_str
            time_left = "%dh %sm left" % (hours, min_str)
        else:
            time_left = "%dm left" % minutes

    # Status color
    stateColor = WHITE
    status_upper = str(status).upper()
    if status_upper in ["FAILED", "ERROR", "CANCELLED"]:
        stateColor = RED
    elif status_upper in ["RUNNING", "SUCCESS", "PRINTING", "COMPLETE", "COMPLETED"]:
        stateColor = GREEN

    # Safely convert progress to int
    progress_val = 0
    p_str = str(progress).strip()
    p_dot_count = 0
    p_valid = len(p_str) > 0
    for i in range(len(p_str)):
        c = p_str[i]
        if c == ".":
            p_dot_count += 1
            if p_dot_count > 1:
                p_valid = False
                break
        elif c < "0" or c > "9":
            p_valid = False
            break
    if p_valid:
        progress_val = int(float(p_str))

    # Render UI
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Marquee(
                            child = render.Text(str(name), font = "tom-thumb"),
                            width = 64,
                            align = "start",
                            offset_start = 5,
                            offset_end = 8,
                        ) if len(str(name)) > 15 else render.Text(str(name), font = "tom-thumb"),
                        render.WrappedText(status_upper, color = stateColor),
                        render.Text(time_left),
                        renderProgress("Completion", progress_val, 1, "#64BFE5"),
                    ],
                ),
            ),
        ),
    )

def get_schema():
    fields = [
        schema.Text(id = "haUrl", name = "Home Assistant URL", desc = "Public HTTPS root URL, such as a Home Assistant Cloud remote URL.", icon = "server"),
        schema.Text(id = "haApiKey", name = "Home Assistant API Key", desc = "Long-Lived Access Token from Home Assistant user profile", icon = "key", secret = True),
        schema.Text(id = "task_name", name = "Task Name", desc = "Currently Printing Task", icon = "file"),
        schema.Text(id = "progress", name = "Print Progress", desc = "Entity ID for print progress (%)", icon = "percent"),
        schema.Text(id = "remaining_time", name = "Remaining Time", desc = "Entity ID for remaining time (decimal hours/minutes)", icon = "clock"),
        schema.Text(id = "end_time", name = "Print End Time", desc = "Entity ID for print end time (Y-M-D H:M:S)", icon = "calendar"),
        schema.Text(id = "status", name = "Print Status", desc = "Entity ID for print status", icon = "info"),
        schema.Text(id = "maxPrintAgeHours", name = "Max Print Age (hours)", desc = "Hide completed prints older than this many hours", icon = "clock", default = "4"),
    ]

    return schema.Schema(version = "1", fields = fields)

def normalized_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]]):
        return ""
    parts = value.split("/", 3)
    host = parts[2].lower() if len(parts) >= 3 else ""
    if not host or "@" in host or ":" in host:
        return ""
    return value.rstrip("/")

def valid_entity(value):
    return type(value) == "string" and len(value) >= 3 and len(value) <= 128 and "." in value and all([char.isalnum() or char in "._-" for char in value.elems()])

def valid_token(value):
    return type(value) == "string" and len(value) >= 1 and len(value) <= 4096 and not any([char in value for char in ["\r", "\n"]])

def safe_scalar(value, fallback):
    return str(value)[:200] if type(value) in ["string", "int", "float"] else fallback

def safe_number(value):
    if type(value) in ["int", "float"]:
        return value
    if type(value) == "string" and value.replace(".", "", 1).isdigit():
        return value
    return 0
