"""
Applet: Dome Watch
Summary: US House Floor activity
Description: Show current US House floor activity in real-time, include live vote counts.
Author: Shaun Brown
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/adjourned_icon.png", ADJOURNED_ICON_ASSET = "file")
load("images/voting_icon.png", VOTING_ICON_ASSET = "file")
load("render.star", "render")

DOME_WATCH_API_URL = "https://api3.domewatch.us"
MAX_RESPONSE_BYTES = 256 * 1024

# Mock mode configuration
MOCK_MODE = False
MOCK_TIMER_VALUE = "0:00"  # Test values: "15:00", "2:30", "0:00", "-1:45", "-5:00"

def main():
    """
    Main entry point for the applet.
    """
    print("Running applet")
    floor = getFloorActivityFromAPI()
    return getRoot(floor)

def getRoot(floor):
    """
    Determines which screen to display based on the floor status.
    """

    # Use .get() for safety in case the API response is malformed
    if floor.get("now", {}).get("value") == "voting":
        return renderVotingRoot(floor)
    else:
        return renderNonVotingRoot(floor)

def renderVotingRoot(floor):
    """
    Renders the main screen for when a vote is active.
    This version includes a continuously scrolling marquee.
    """

    # --- NEW ---
    # Get the original question text.
    question_text = floor.get("roll_call", {}).get("question", "Loading...")[:180]

    scroll_text = question_text

    return render.Root(
        delay = 125,
        show_full_animation = False,
        child = render.Column(
            main_align = "space_around",
            cross_align = "space_around",
            children = [
                render.Marquee(
                    width = 64,
                    height = 20,
                    child = render.Text(
                        # Use the new, long, repeating text here
                        content = scroll_text,
                        font = "CG-pixel-4x5-mono",
                    ),
                ),
                # The rest of the voting grid and timer remains exactly the same...
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "space_around",
                            children = [
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "D", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "R", font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "Y", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "N", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "P", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "NV", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                    ],
                ),
                render.Box(
                    child = renderVotingTimer(floor),
                ),
            ],
        ),
    )

def renderVotingTimer(floor):
    """
    Timer function that formats overtime to include hours (H:MM:SS)
    after one hour has passed.
    """

    # First check if we have a valid "value" field
    timer_value = floor.get("timer", {}).get("value", "")

    if timer_value:
        is_negative = timer_value.startswith("-")
        clean_value = timer_value.lstrip("-")

        if ":" in clean_value:
            parts = clean_value.split(":")
            if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                minutes = int(parts[0])
                seconds = int(parts[1])
                total_seconds = minutes * 60 + seconds

                if is_negative:
                    # Already in overtime - generate count-up from this point
                    frames = []
                    for i in range(total_seconds, total_seconds + 61):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)
                else:
                    # Counting down - generate countdown to 0:00 then overtime
                    frames = []

                    # Countdown to 0:00
                    for i in range(total_seconds, max(-1, total_seconds - 61), -1):
                        min = i // 60
                        sec = i % 60
                        sec_str = str(sec)
                        if sec < 10:
                            sec_str = "0" + sec_str
                        content_str = str(min) + ":" + sec_str
                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FFFFFF"))

                    # Continue into overtime
                    for i in range(1, max(1, 61 - total_seconds)):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS (unlikely to be hit in this 5-min animation, but good practice)
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)

    return render.Text("ERR: NO TIME")

def renderNonVotingRoot(floor):
    """
    Renders the screen for when there is no active vote.
    """
    return render.Root(
        delay = 300,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = getNonVotingChildren(floor),
        ),
    )

def getNonVotingChildren(floor):
    """
    Builds the widgets for the non-voting screen.
    """
    children = [
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        # NOTE: You will need to add your getStatusIcon function back
                        render.Image(src = getStatusIcon(floor), height = 23),
                    ],
                ),
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            align = "center",
                            font = getFloorStatusFont(floor),
                            color = "#FFFFFF",
                            content = floor.get("now", {}).get("text", "No activity"),
                        ),
                    ],
                ),
            ],
        ),
    ]

    if "timeline" in floor and floor["timeline"]:
        children.append(getNonVotingMarquee(floor))
    return children

def getNonVotingMarquee(floor):
    """
    Builds the vertical marquee for the non-voting screen timeline.
    """
    marqueeText = []

    # THE CORRECTED LINE: Use type() to check if the value is a dictionary.
    if type(floor.get("timeline")) == "dict":
        for key in floor["timeline"]:
            marqueeText.append(floor["timeline"][key].get("text", ""))

    full_text = " • ".join(marqueeText)

    return render.Marquee(
        child = render.WrappedText(
            content = full_text,
            font = "tom-thumb",
            color = "#FFFFFF",
            align = "center",
            width = 64,
        ),
        align = "center",
        scroll_direction = "vertical",
        height = 5,
        width = 64,
        delay = 5,
    )

def getStatusIcon(floor):
    now = floor.get("now", {})
    if now.get("value") == "voting":
        return VOTING_ICON_ASSET.readall()

    elif now.get("value") != "adjourned":
        return VOTING_ICON_ASSET.readall()

    else:
        return ADJOURNED_ICON_ASSET.readall()

def getFloorStatusFont(floor):
    """
    Returns a smaller font for the "adjourned" status to ensure it fits.
    """
    if floor.get("now", {}).get("value") == "adjourned":
        return "tom-thumb"
    else:
        return "5x8"

def getFloorActivityFromAPI():
    """
    Fetches floor activity from the Dome Watch API, with caching.
    """

    # Return mock data if in mock mode
    if MOCK_MODE:
        print("Using mock data with timer: " + MOCK_TIMER_VALUE)
        return {
            "now": {"text": "Voting", "value": "voting"},
            "roll_call": {
                "bill": {"id": "566", "number": "566"},
                "number": "187",
                "question": "H RES 566 - MOCK TEST - On Ordering the Previous Question (Timer: " + MOCK_TIMER_VALUE + ")",
            },
            "timeline": {"next_votes": {"text": "Next votes: Later this afternoon"}},
            "timer": {
                "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                "timestamp": "2025-07-04T16:15:29.017Z",
                "value": MOCK_TIMER_VALUE,
            },
            "votes": {
                "counts": {
                    "blue": {"nays": "82", "not_voting": "130", "present": "", "yeas": ""},
                    "red": {"nays": "", "not_voting": "193", "present": "", "yeas": "27"},
                    "totals": {"nays": "82", "not_voting": "323", "present": "", "yeas": "27"},
                    "white": {"nays": "", "not_voting": "", "present": "", "yeas": ""},
                },
                "roll_call": {
                    "bill": {"id": "566", "number": "566"},
                    "number": "187",
                    "question": "H RES 566 - MOCK TEST - Timer: " + MOCK_TIMER_VALUE,
                },
                "timer": {
                    "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                    "timestamp": "2025-07-02T13:33:39.949Z",
                    "value": MOCK_TIMER_VALUE,
                },
            },
        }
    print("Getting floor activity from API")
    response = http.get(DOME_WATCH_API_URL + "/floor", ttl_seconds = 20)
    body = response.body()
    floor = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return normalize_floor(floor)

def normalize_floor(floor):
    if type(floor) != "dict":
        return {"now": {"text": "Floor data unavailable", "value": "unknown"}}

    now = floor.get("now") if type(floor.get("now")) == "dict" else {}
    roll_call = floor.get("roll_call") if type(floor.get("roll_call")) == "dict" else {}
    timer = floor.get("timer") if type(floor.get("timer")) == "dict" else {}
    votes = floor.get("votes") if type(floor.get("votes")) == "dict" else {}
    counts = votes.get("counts") if type(votes.get("counts")) == "dict" else {}
    blue = counts.get("blue") if type(counts.get("blue")) == "dict" else {}
    red = counts.get("red") if type(counts.get("red")) == "dict" else {}
    timeline = floor.get("timeline") if type(floor.get("timeline")) == "dict" else {}

    return {
        "now": {
            "text": safe_text(now.get("text"), "No activity", 120),
            "value": safe_text(now.get("value"), "unknown", 40),
        },
        "roll_call": {"question": safe_text(roll_call.get("question"), "Loading...", 180)},
        "timer": {
            "timestamp": safe_text(timer.get("timestamp"), "", 64),
            "value": safe_text(timer.get("value"), "", 16),
        },
        "votes": {"counts": {"blue": safe_counts(blue), "red": safe_counts(red)}},
        "timeline": {
            str(key)[:40]: {"text": safe_text(value.get("text"), "", 160)}
            for key, value in timeline.items()
            if type(value) == "dict"
        },
    }

def safe_counts(counts):
    return {
        key: safe_count(counts.get(key))
        for key in ["yeas", "nays", "present", "not_voting"]
    }

def safe_count(value):
    if type(value) in ["int", "float"] or (type(value) == "string" and value.isdigit()):
        return min(1000, max(0, int(value)))
    return 0

def safe_text(value, default, limit):
    return value[:limit] if type(value) == "string" and value else default
