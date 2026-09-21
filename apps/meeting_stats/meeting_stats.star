# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Meeting Stats
Summary: Weekly Meeting Insights
Description: Summarizes meetings from a private Outlook iCalendar link.
Author: Matt-Pesce
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_URL = "https://ics.calendarlabs.com/76/8d23255e/US_Holidays.ics"
ALLOWED_HOSTS = ["calendar.google.com", "ics.calendarlabs.com", "outlook.live.com", "outlook.office.com", "outlook.office365.com"]
DAY = 24 * 60 * 60

def main(config):
    location = json.decode(config.str("location") or "{}", {})
    timezone = location.get("timezone", time.tz()) if type(location) == "dict" else time.tz()
    url = config.str("calendar_url", DEFAULT_URL)
    if not valid_url(url):
        return problem("Use an Outlook HTTPS calendar link")

    response = http.get(url, ttl_seconds = 300)
    if response.status_code != 200 or len(response.body()) > 1024 * 1024:
        return problem("Calendar unavailable")

    now = time.now().in_location(timezone)
    week_start = now.unix - ((weekday(now) * DAY) + now.hour * 3600 + now.minute * 60 + now.second)
    week_end = week_start + 7 * DAY
    count = 0
    seconds = 0
    large_seconds = 0
    for event in parse_events(response.body(), timezone):
        if event["start"] == None or event["end"] == None or event["cancelled"]:
            continue
        duration = event["end"].unix - event["start"].unix
        if event["start"].unix < week_start or event["start"].unix >= week_end or duration <= 0 or duration >= DAY or event["attendees"] < 1:
            continue
        count += 1
        seconds += duration
        if event["attendees"] >= 12:
            large_seconds += duration
    return render_stats(seconds / 3600.0, count, large_seconds / 3600.0)

def valid_url(value):
    parts = value.split("/", 3) if type(value) == "string" and value.startswith("https://") and len(value) <= 4096 else []
    return len(parts) == 4 and parts[2].lower() in ALLOWED_HOSTS and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def weekday(value):
    return {
        "Monday": 0,
        "Tuesday": 1,
        "Wednesday": 2,
        "Thursday": 3,
        "Friday": 4,
        "Saturday": 5,
        "Sunday": 6,
    }[value.format("Monday")]

def parse_events(body, timezone):
    events = []
    current = None
    for line in unfold(body)[:20000]:
        if line == "BEGIN:VEVENT":
            current = {"start": None, "end": None, "attendees": 0, "cancelled": False}
        elif line == "END:VEVENT" and current != None:
            if len(events) < 512:
                events.append(current)
            current = None
        elif current != None:
            if line.startswith("DTSTART"):
                current["start"] = parse_datetime(line, timezone)
            elif line.startswith("DTEND"):
                current["end"] = parse_datetime(line, timezone)
            elif line.startswith("ATTENDEE"):
                current["attendees"] += 1
            elif line == "STATUS:CANCELLED":
                current["cancelled"] = True
    return events

def unfold(body):
    lines = []
    for raw in body.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if (raw.startswith(" ") or raw.startswith("\t")) and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines

def parse_datetime(line, fallback_timezone):
    parts = line.split(":", 1)
    if len(parts) != 2:
        return None
    attributes = parts[0].split(";")
    value = parts[1].strip()
    timezone = fallback_timezone
    for attribute in attributes[1:]:
        if attribute.startswith("TZID=") and time.is_valid_timezone(attribute[5:].strip('"')):
            timezone = attribute[5:].strip('"')
    if len(value) == 8 and value.isdigit():
        return time.time(year = int(value[:4]), month = int(value[4:6]), day = int(value[6:8]), location = fallback_timezone)
    utc = value.endswith("Z")
    value = value[:-1] if utc else value
    if len(value) not in [13, 15] or value[8] != "T" or not value[:8].isdigit() or not value[9:].isdigit():
        return None
    return time.time(
        year = int(value[:4]),
        month = int(value[4:6]),
        day = int(value[6:8]),
        hour = int(value[9:11]),
        minute = int(value[11:13]),
        second = int(value[13:15]) if len(value) == 15 else 0,
        location = "UTC" if utc else timezone,
    ).in_location(fallback_timezone)

def render_stats(hours, count, large_hours):
    duration_color = "#0f0" if hours < 21 else "#ff0" if hours < 26 else "#f00"
    count_color = "#0f0" if count < 21 else "#ff0" if count < 26 else "#f00"
    large_color = "#0f0" if large_hours < 6 else "#ff0" if large_hours < 11 else "#f00"
    return render.Root(
        child = render.Column(
            children = [
                render.Text("Meeting Stats"),
                render.Row(
                    children = [
                        render.Column(children = [render.Text("Count:", font = "tom-thumb"), render.Text("Time:", font = "tom-thumb"), render.Text("Large:", font = "tom-thumb")]),
                        render.Column(
                            cross_align = "end",
                            children = [
                                render.Text(" %d" % count, font = "tom-thumb", color = count_color),
                                render.Text(" %sH" % humanize.float("###.##", hours), font = "tom-thumb", color = duration_color),
                                render.Text(" %sH" % humanize.float("###.##", large_hours), font = "tom-thumb", color = large_color),
                            ],
                        ),
                    ],
                ),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def problem(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "calendar_url", name = "Outlook iCalendar URL", desc = "A private HTTPS calendar publishing link from Outlook.", icon = "calendar", default = DEFAULT_URL, secret = True),
            schema.Location(id = "location", name = "Location", desc = "Used for meeting dates and timezone.", icon = "locationDot"),
        ],
    )
