"""
Applet: Next Event
Summary: Displays the next calendar event
Description: Displays the next calendar event from a private Google or Outlook iCalendar feed.
Author: mattcaruso <Matt Caruso>
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_ICS_URL = "https://ics.calendarlabs.com/76/8d23255e/US_Holidays.ics"
DEFAULT_TITLE = "Next event"
ALLOWED_HOSTS = ["calendar.google.com", "ics.calendarlabs.com", "outlook.live.com", "outlook.office.com", "outlook.office365.com"]
MAX_CALENDAR_BYTES = 1024 * 1024
MAX_EVENTS = 512
MAX_LINES = 20000
DAY_SECONDS = 24 * 60 * 60

def main(config):
    location_value = config.str("loc")
    location = json.decode(location_value, None) if location_value else None
    timezone = location.get("timezone", time.tz()) if type(location) == "dict" else time.tz()
    url = config.str("url", DEFAULT_ICS_URL)
    if not valid_calendar_url(url):
        return render_error("Use a Google or Outlook HTTPS calendar URL")

    response = http.get(url, ttl_seconds = 300)
    if response.status_code != 200 or len(response.body()) > MAX_CALENDAR_BYTES:
        return render_error("Calendar unavailable")
    lines = unfold_lines(response.body())
    if len(lines) > MAX_LINES:
        return render_error("Calendar is too large")

    now = time.now().in_location(timezone)
    events = parse_events(lines, timezone, now)
    future = sorted([event for event in events if event["end"] > now], key = lambda event: event["start"])
    next_event = future[0] if future else None
    return render.Root(
        child = render.Column(
            cross_align = "center",
            main_align = "space_around",
            children = render_top(config) + render_bottom(next_event, now, timezone),
        ),
    )

def valid_calendar_url(value):
    if type(value) != "string" or len(value) > 4096 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n"]]):
        return False
    parts = value.split("/", 3)
    return len(parts) == 4 and parts[2].lower() in ALLOWED_HOSTS

def unfold_lines(body):
    lines = []
    for raw in body.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if (raw.startswith(" ") or raw.startswith("\t")) and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines

def parse_events(lines, timezone, now):
    events = []
    event = None
    for line in lines:
        if line == "BEGIN:VEVENT":
            if len(events) >= MAX_EVENTS:
                break
            event = {"title": "", "start": None, "end": None, "all_day": False, "rrule": "", "cancelled": False}
        elif line == "END:VEVENT" and event != None:
            event = normalize_event(event, timezone, now)
            if event != None:
                events.append(event)
            event = None
        elif event != None:
            if line.startswith("SUMMARY") and ":" in line:
                event["title"] = unescape_text(line.split(":", 1)[1])[:500]
            elif line.startswith("DTSTART"):
                parsed = parse_datetime(line, timezone)
                if parsed != None:
                    event["start"] = parsed["time"]
                    event["all_day"] = parsed["all_day"]
            elif line.startswith("DTEND"):
                parsed = parse_datetime(line, timezone)
                if parsed != None:
                    event["end"] = parsed["time"]
            elif line.startswith("RRULE:"):
                event["rrule"] = line[6:]
            elif line == "STATUS:CANCELLED":
                event["cancelled"] = True
    return events

def parse_datetime(line, fallback_timezone):
    parts = line.split(":", 1)
    if len(parts) != 2:
        return None
    attributes = parts[0].split(";")
    value = parts[1].strip()
    all_day = "VALUE=DATE" in attributes or len(value) == 8
    location = fallback_timezone
    for attribute in attributes[1:]:
        if attribute.startswith("TZID="):
            candidate = attribute[5:].strip('"')
            if time.is_valid_timezone(candidate):
                location = candidate

    if all_day:
        if not valid_date(value):
            return None
        parsed = time.time(year = int(value[0:4]), month = int(value[4:6]), day = int(value[6:8]), location = fallback_timezone)
        return {"time": parsed, "all_day": True}

    utc = value.endswith("Z")
    raw = value[:-1] if utc else value
    if len(raw) not in [13, 15] or raw[8] != "T" or not valid_date(raw[:8]) or not raw[9:].isdigit():
        return None
    hour = int(raw[9:11])
    minute = int(raw[11:13])
    second = int(raw[13:15]) if len(raw) == 15 else 0
    if hour > 23 or minute > 59 or second > 59:
        return None
    parsed = time.time(
        year = int(raw[0:4]),
        month = int(raw[4:6]),
        day = int(raw[6:8]),
        hour = hour,
        minute = minute,
        second = second,
        location = "UTC" if utc else location,
    )
    return {"time": parsed.in_location(fallback_timezone), "all_day": False}

def valid_date(value):
    if len(value) != 8 or not value.isdigit():
        return False
    year = int(value[0:4])
    month = int(value[4:6])
    day = int(value[6:8])
    if year < 1970 or year > 2200 or month < 1 or month > 12:
        return False
    days = [31, 29 if year % 400 == 0 or (year % 4 == 0 and year % 100 != 0) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 1 <= day and day <= days[month - 1]

def normalize_event(event, timezone, now):
    if event["cancelled"] or not event["title"] or event["start"] == None:
        return None
    if event["end"] == None:
        event["end"] = time.from_timestamp(event["start"].unix + (DAY_SECONDS if event["all_day"] else 60 * 60)).in_location(timezone)
    if event["end"] <= event["start"]:
        return None

    rule = parse_rule(event["rrule"])
    frequency = rule.get("FREQ", "")
    if frequency in ["DAILY", "WEEKLY"] and event["end"] <= now:
        interval_text = rule.get("INTERVAL", "1")
        interval = int(interval_text) if interval_text.isdigit() else 1
        interval = min(max(interval, 1), 365)
        period = interval * DAY_SECONDS * (7 if frequency == "WEEKLY" else 1)
        repetitions = max(0, (now.unix - event["end"].unix) // period + 1)
        event["start"] = time.from_timestamp(event["start"].unix + repetitions * period).in_location(timezone)
        event["end"] = time.from_timestamp(event["end"].unix + repetitions * period).in_location(timezone)
        until = parse_rule_until(rule.get("UNTIL", ""), timezone)
        count_text = rule.get("COUNT", "")
        count = int(count_text) if count_text.isdigit() else 0
        if (until != None and until < event["start"]) or (count > 0 and repetitions >= count):
            return None
    return event

def parse_rule(value):
    rule = {}
    for item in value.split(";"):
        parts = item.split("=", 1)
        if len(parts) == 2:
            rule[parts[0].upper()] = parts[1]
    return rule

def parse_rule_until(value, timezone):
    parsed = parse_datetime("DTEND:" + value, timezone) if value else None
    return parsed["time"] if parsed != None else None

def unescape_text(value):
    return value.replace("\\n", " ").replace("\\N", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\").strip()

def render_top(config):
    return [
        render.Marquee(child = render.Text(config.str("title", DEFAULT_TITLE), color = "#ffea00"), width = 64, align = "center"),
        render.Box(color = "#ffea00", height = 1),
    ]

def render_bottom(event, now, timezone):
    if event == None:
        return [render.Box(height = 3), render.Text("No upcoming"), render.Text("events")]
    if event["start"].year == now.year and event["start"].month == now.month and event["start"].day == now.day:
        date = "Today"
    else:
        tomorrow = time.from_timestamp(now.unix + DAY_SECONDS).in_location(timezone)
        date = "Tomorrow" if event["start"].year == tomorrow.year and event["start"].month == tomorrow.month and event["start"].day == tomorrow.day else event["start"].format("Jan 2")
    return [
        render.Box(height = 3),
        render.Marquee(child = render.Text(event["title"]), width = 64, align = "center"),
        render.Box(height = 1),
        render.Text(date),
    ]

def render_error(message):
    return render.Root(child = render.WrappedText(message, font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(id = "loc", name = "Location", desc = "Location for timezone awareness", icon = "locationDot"),
            schema.Text(id = "url", name = "iCalendar URL", desc = "A private Google or Outlook HTTPS iCalendar URL.", icon = "calendar", default = DEFAULT_ICS_URL, secret = True),
            schema.Text(id = "title", name = "Title", desc = "The heading displayed above the next event.", icon = "calendar", default = DEFAULT_TITLE),
        ],
    )
