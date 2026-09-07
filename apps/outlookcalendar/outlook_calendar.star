"""
Applet: Outlook Calendar
Summary: Display next meeting
Description: Shows upcoming meetings from a private Outlook iCalendar link.
Author: Matt-Pesce
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/cal_icon.png", CAL_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CAL_ICON = CAL_ICON_ASSET.readall()
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
    upcoming = sorted([event for event in parse_events(response.body(), timezone, now) if event["end"] > now], key = lambda event: event["start"])
    if not upcoming:
        return problem("No upcoming meetings")
    if config.bool("full_day", False):
        today = [event for event in upcoming if same_day(event["start"], now)][:8]
        if today:
            return render.Root(child = render.Sequence(children = [meeting_card(event, timezone) for event in today]))
    return render.Root(child = meeting_card(upcoming[0], timezone))

def valid_url(value):
    parts = value.split("/", 3) if type(value) == "string" and value.startswith("https://") and len(value) <= 4096 else []
    return len(parts) == 4 and parts[2].lower() in ALLOWED_HOSTS and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def parse_events(body, timezone, now):
    events = []
    current = None
    for line in unfold(body)[:20000]:
        if line == "BEGIN:VEVENT":
            current = {"title": "", "start": None, "end": None, "rrule": "", "cancelled": False}
        elif line == "END:VEVENT" and current != None:
            event = normalize(current, timezone, now)
            if event != None and len(events) < 512:
                events.append(event)
            current = None
        elif current != None:
            if line.startswith("SUMMARY") and ":" in line:
                current["title"] = line.split(":", 1)[1].replace("\\,", ",").replace("\\n", " ")[:300]
            elif line.startswith("DTSTART"):
                current["start"] = parse_datetime(line, timezone)
            elif line.startswith("DTEND"):
                current["end"] = parse_datetime(line, timezone)
            elif line.startswith("RRULE:"):
                current["rrule"] = line[6:]
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

def normalize(event, timezone, now):
    if event["cancelled"] or not event["title"] or event["start"] == None:
        return None
    if event["end"] == None:
        event["end"] = time.from_timestamp(event["start"].unix + 60 * 60).in_location(timezone)
    frequency = ""
    interval = 1
    for rule in event["rrule"].split(";"):
        if rule.startswith("FREQ="):
            frequency = rule[5:]
        elif rule.startswith("INTERVAL=") and rule[9:].isdigit():
            interval = min(max(int(rule[9:]), 1), 365)
    if frequency in ["DAILY", "WEEKLY"] and event["end"] <= now:
        period = interval * DAY * (7 if frequency == "WEEKLY" else 1)
        repeats = (now.unix - event["end"].unix) // period + 1
        event["start"] = time.from_timestamp(event["start"].unix + repeats * period).in_location(timezone)
        event["end"] = time.from_timestamp(event["end"].unix + repeats * period).in_location(timezone)
    return event if event["end"] > event["start"] else None

def same_day(left, right):
    return left.year == right.year and left.month == right.month and left.day == right.day

def meeting_card(event, timezone):
    return render.Column(
        children = [
            render.Row(children = [render.Image(src = CAL_ICON, width = 12), render.Text(event["start"].in_location(timezone).format("Jan 2"), color = "#ffea00")], expanded = True, main_align = "space_evenly", cross_align = "center"),
            render.Marquee(child = render.Text(event["title"], font = "tb-8"), width = 64, align = "center"),
            render.Text(event["start"].in_location(timezone).format("3:04 PM"), font = "tom-thumb", color = "#aaaaaa"),
        ],
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
    )

def problem(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "calendar_url", name = "Outlook iCalendar URL", desc = "A private HTTPS calendar publishing link from Outlook.", icon = "calendar", default = DEFAULT_URL, secret = True),
            schema.Location(id = "location", name = "Location", desc = "Used for meeting times and timezone.", icon = "locationDot"),
            schema.Toggle(id = "full_day", name = "Show today's meetings", desc = "Rotate through all remaining meetings today.", icon = "calendarDay", default = False),
        ],
    )
