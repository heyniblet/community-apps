"""
Applet: Any Calendar
Summary: Display any ICS calendar
Description: Show current or upcoming events from a Google or Outlook calendar with just an ICS link - no login necessary. Can choose to show time or only the event title - perfect for scheduling announcements.
Author: Vik Boyechko
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_CALENDAR_BYTES = 1024 * 1024
MAX_EVENTS = 256
MAX_LINES = 20000
MAX_TITLE_LENGTH = 500
DAY_SECONDS = 24 * 60 * 60

def main(config):
    calendar_link = config.str("calendar_link", "")
    timezone = config.str("timezone", "America/New_York")
    text_only = config.bool("text_only", False)
    time_bg_color = config.get("time_bg_color", "#1a73e8") or "#1a73e8"
    time_text_color = config.get("time_text_color", "#ffffff") or "#ffffff"
    event_bg_color = config.get("event_bg_color", "#000000") or "#000000"
    event_text_color = config.get("event_text_color", "#7FFF7F") or "#7FFF7F"

    if not calendar_link:
        return render_setup(time_bg_color, time_text_color, event_bg_color, event_text_color)
    if not valid_https_url(calendar_link):
        return render_error("Use an HTTPS calendar URL")
    if not time.is_valid_timezone(timezone):
        return render_error("Invalid timezone")

    response = http.get(calendar_link, ttl_seconds = 300)
    body = response.body()
    if response.status_code != 200:
        return render_error("Calendar unavailable ({})".format(response.status_code))
    if len(body) > MAX_CALENDAR_BYTES:
        return render_error("Calendar is too large")

    lines = unfold_lines(body)
    if len(lines) > MAX_LINES:
        return render_error("Calendar has too many lines")

    now = time.now().in_location(timezone)
    events = parse_events(lines, timezone, now)
    current = sorted([event for event in events if event["start"] <= now and now < event["end"]], key = lambda event: event["start"])
    upcoming = sorted([event for event in events if not event["all_day"] and now < event["start"] and event["start"].format("20060102") == now.format("20060102")], key = lambda event: event["start"])
    all_day = [event for event in events if event["all_day"] and event["start"].format("20060102") == now.format("20060102")]

    selected = current[0] if current else upcoming[0] if upcoming else all_day[0] if all_day else None
    if selected == None:
        return []
    return render_event(selected, text_only, time_bg_color, time_text_color, event_bg_color, event_text_color)

def valid_https_url(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n"]]):
        return False
    parts = value.split("/", 3)
    return len(parts) >= 3 and parts[2] and "@" not in parts[2]

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
                event["title"] = unescape_text(line.split(":", 1)[1])[:MAX_TITLE_LENGTH]
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
        start = time.from_timestamp(event["start"].unix + repetitions * period).in_location(timezone)
        end = time.from_timestamp(event["end"].unix + repetitions * period).in_location(timezone)
        until = parse_rule_until(rule.get("UNTIL", ""), timezone)
        count_text = rule.get("COUNT", "")
        count = int(count_text) if count_text.isdigit() else 0
        if (until != None and until < start) or (count > 0 and repetitions >= count):
            return None
        event["start"] = start
        event["end"] = end
    return event

def parse_rule(value):
    rule = {}
    for item in value.split(";"):
        parts = item.split("=", 1)
        if len(parts) == 2:
            rule[parts[0].upper()] = parts[1]
    return rule

def parse_rule_until(value, timezone):
    if not value:
        return None
    parsed = parse_datetime("DTEND:" + value, timezone)
    return parsed["time"] if parsed != None else None

def unescape_text(value):
    return value.replace("\\n", " ").replace("\\N", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\").strip()

def format_clock(value):
    hour = value.hour
    suffix = "PM" if hour >= 12 else "AM"
    display_hour = hour % 12
    display_hour = 12 if display_hour == 0 else display_hour
    minute = str(value.minute) if value.minute >= 10 else "0" + str(value.minute)
    return "{}{}".format(display_hour, suffix) if value.minute == 0 else "{}:{}{}".format(display_hour, minute, suffix)

def render_event(event, text_only, time_bg_color, time_text_color, event_bg_color, event_text_color):
    title = event["title"]
    title_height = 32 if text_only else 22
    title_content = render.WrappedText(content = title, color = event_text_color, font = "tom-thumb", width = 62, align = "center")
    title_display = render.Marquee(width = 64, height = title_height, scroll_direction = "vertical", child = title_content) if (len(title) // 10 + 1) * 6 > title_height - 2 else render.Column(expanded = True, main_align = "center", cross_align = "center", children = [title_content])
    title_box = render.Box(width = 64, height = 32 if text_only else 22, color = event_bg_color, child = title_display)
    if text_only:
        return render.Root(child = title_box)

    time_display = "ALL DAY" if event["all_day"] else "{}-{}".format(format_clock(event["start"]), format_clock(event["end"]))
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Box(
                    width = 64,
                    height = 10,
                    color = time_bg_color,
                    child = render.Padding(pad = (2, 2, 2, 2), child = render.Text(time_display, color = time_text_color, font = "tom-thumb")),
                ),
                title_box,
            ],
        ),
    )

def render_setup(time_bg_color, time_text_color, event_bg_color, event_text_color):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Box(width = 64, height = 10, color = time_bg_color, child = render.Padding(pad = (0, 2, 0, 0), child = render.Text("5-6PM", color = time_text_color, font = "tom-thumb"))),
                render.Box(
                    width = 64,
                    height = 22,
                    color = event_bg_color,
                    child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = [render.WrappedText("Enter Calendar Link to Get Started", color = event_text_color, font = "tom-thumb", width = 62, align = "center")]),
                ),
            ],
        ),
    )

def render_error(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("CALENDAR", color = "#DB4437", font = "tb-8"),
                render.WrappedText(message[:120], color = "#DB4437", font = "tom-thumb", width = 60, align = "center"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "calendar_link",
                name = "Calendar Link",
                desc = "Paste an HTTPS iCal URL from Google, Outlook, or another provider",
                icon = "calendar",
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Your timezone (e.g. America/New_York)",
                icon = "clock",
                default = "America/New_York",
            ),
            schema.Toggle(
                id = "text_only",
                name = "Text Only",
                desc = "Show only the event text without time",
                icon = "textHeight",
                default = False,
            ),
            schema.Color(id = "time_bg_color", name = "Time Background Color", desc = "Background color for the time display", icon = "brush", default = "#1a73e8"),
            schema.Color(id = "time_text_color", name = "Time Text Color", desc = "Text color for the time display", icon = "font", default = "#ffffff"),
            schema.Color(id = "event_bg_color", name = "Event Background Color", desc = "Background color for the event display", icon = "brush", default = "#000000"),
            schema.Color(id = "event_text_color", name = "Event Text Color", desc = "Text color for the event display", icon = "font", default = "#7FFF7F"),
        ],
    )
