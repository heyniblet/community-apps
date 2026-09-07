"""
Dexcom G7 Display for Tidbyt
Based on pydexcom implementation patterns
Shows real-time glucose readings from Dexcom G7 CGM
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Regional configuration - Based on pydexcom
DEXCOM_BASE_URLS = {
    "us": "https://share2.dexcom.com/ShareWebServices/Services/",
    "ous": "https://shareous1.dexcom.com/ShareWebServices/Services/",  # Outside US
    "jp": "https://share.dexcom.jp/ShareWebServices/Services/",  # Japan
}

# Application IDs by region - From pydexcom
DEXCOM_APPLICATION_IDS = {
    "us": "d89443d2-327c-4a6f-89e5-496bbb0317db",
    "ous": "d89443d2-327c-4a6f-89e5-496bbb0317db",  # Same as US
    "jp": "d8665ade-9673-4e27-9ff6-92db4ce13d13",
}

# API Endpoints - From pydexcom
DEXCOM_AUTHENTICATE_ENDPOINT = "General/AuthenticatePublisherAccount"
DEXCOM_LOGIN_ID_ENDPOINT = "General/LoginPublisherAccountById"
DEXCOM_GLUCOSE_VALUES_ENDPOINT = "Publisher/ReadPublisherLatestGlucoseValues"

# Request headers
HEADERS = {
    "Accept-Encoding": "application/json",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/1220.1 Darwin/20.3.0",
}

MAX_RESPONSE_BYTES = 512 * 1024

# Glucose thresholds (mg/dL)
LOW_THRESHOLD = 70
HIGH_THRESHOLD = 180
URGENT_LOW = 55
URGENT_HIGH = 250

# Glucose range limits - From pydexcom
MAX_MINUTES = 1440  # 24 hours
MAX_COUNT = 288

# Colors for display
COLORS = {
    "normal": "#00FF00",  # Green
    "low": "#FF0000",  # Red
    "high": "#FFA500",  # Orange
    "urgent": "#FF0000",  # Red
    "stale": "#808080",  # Gray
}

# Trend data - From pydexcom
TREND_DESCRIPTIONS = {
    0: "",  # None
    1: "rising quickly",  # DoubleUp
    2: "rising",  # SingleUp
    3: "rising slightly",  # FortyFiveUp
    4: "steady",  # Flat
    5: "falling slightly",  # FortyFiveDown
    6: "falling",  # SingleDown
    7: "falling quickly",  # DoubleDown
    8: "?",  # NotComputable
    9: "rate unavailable",  # RateOutOfRange
}

TREND_ARROWS = {
    "": "",
    "DoubleUp": "↑↑",  # DoubleUp
    "SingleUp": "↑",  # SingleUp
    "FortyFiveUp": "↗",  # FortyFiveUp
    "Flat": "→",  # Flat
    "FortyFiveDown": "↘",  # FortyFiveDown
    "SingleDown": "↓",  # SingleDown
    "DoubleDown": "↓↓",  # DoubleDown
    "NotComputable": "?",  # NotComputable
    "RateOutOfRange": "-",  # RateOutOfRange
}

# Unit conversion - From pydexcom
MMOL_L_CONVERSION_FACTOR = 0.0555

def valid_credential(value, maximum):
    return type(value) == "string" and len(value) >= 1 and len(value) <= maximum and "\r" not in value and "\n" not in value

def response_json(response):
    body = response.body()
    return json.decode(body, None) if response.status_code == 200 and len(body) <= MAX_RESPONSE_BYTES else None

def valid_uuid(value):
    return type(value) == "string" and len(value) == 36 and all([char.isalnum() or char == "-" for char in value.codepoints()]) and value != "00000000-0000-0000-0000-000000000000"

def sanitize_reading(value):
    if type(value) != "dict":
        return None
    glucose = value.get("Value")
    trend = value.get("Trend", "")
    timestamp = value.get("DT", "")
    if type(glucose) not in ["int", "float"] or glucose < 20 or glucose > 600:
        return None
    if type(trend) != "string" or trend not in TREND_ARROWS:
        trend = "NotComputable"
    if type(timestamp) != "string" or len(timestamp) > 64:
        timestamp = ""
    return {"Value": glucose, "Trend": trend, "DT": timestamp}

def format_mmol(value):
    """Format mmol/L value with one decimal place"""

    # Multiply by 10, round, then divide by 10 to get 1 decimal place
    value_times_10 = int(value * 10 + 0.5)  # Adding 0.5 for rounding
    integer_part = value_times_10 // 10
    decimal_part = value_times_10 % 10
    return str(integer_part) + "." + str(decimal_part)

def main(config):
    """Main function called by Tidbyt"""

    # Get configuration
    username = config.get("username", "")
    password = config.get("password", "")
    region = config.get("region", "us").lower()
    units = config.get("units", "mg/dL")

    # Validate credentials
    if not valid_credential(username, 256) or not valid_credential(password, 512):
        return render_no_config()

    # Validate region
    if region not in DEXCOM_BASE_URLS:
        return render_error("Invalid region")

    # Create Dexcom client
    client = DexcomClient(username, password, region)

    # Get glucose reading
    glucose_reading = get_current_glucose_reading(client)

    if not glucose_reading:
        return render_error("No data available")

    # Process glucose value
    glucose_value = glucose_reading.get("Value", 0)
    trend = glucose_reading.get("Trend", 0)
    timestamp = glucose_reading.get("DT", "")

    # Convert units if needed
    if units == "mmol/L":
        glucose_value = glucose_value * MMOL_L_CONVERSION_FACTOR
        display_value = format_mmol(glucose_value)
    else:
        display_value = str(int(glucose_value))

    # Get color based on value
    color = get_glucose_color(glucose_value, units)

    # Calculate data age
    age_text = ""
    if timestamp:
        data_age = get_data_age_minutes(timestamp)
        if data_age > 10:
            color = COLORS["stale"]
            age_text = "%d min ago" % data_age
        elif data_age >= 0:
            age_text = "%d min" % data_age

    # Get trend display
    trend_arrow = TREND_ARROWS.get(trend, "?")

    # Build display
    return render_glucose_display(
        value = display_value,
        arrow = trend_arrow,
        units = units,
        age = age_text,
        color = color,
    )

def DexcomClient(username, password, region):
    """Create a Dexcom client object (dict in Starlark)"""
    return {
        "username": username,
        "password": password,
        "region": region,
        "base_url": DEXCOM_BASE_URLS[region],
        "app_id": DEXCOM_APPLICATION_IDS[region],
    }

def get_current_glucose_reading(client):
    """Get the current glucose reading following pydexcom pattern"""

    # Get session ID (handles authentication chain)
    session_id = get_session_id(client)
    if not session_id:
        return None

    # Fetch glucose values - request last 10 minutes to avoid stale data
    # Requesting smaller time windows helps get fresher data
    url = client["base_url"] + DEXCOM_GLUCOSE_VALUES_ENDPOINT
    params = {
        "sessionId": session_id,
        "minutes": "10",  # Only request last 10 minutes instead of 1440
        "maxCount": "3",  # Get last 3 readings to ensure we have data
    }

    response = http.get(
        url = url,
        params = params,
        headers = HEADERS,
    )
    data = response_json(response)

    # If no data in last 10 minutes, try a longer window (30 minutes)
    if (not data or len(data) == 0) and params["minutes"] == "10":
        params["minutes"] = "30"
        params["maxCount"] = "6"  # Get more readings
        response = http.get(url = url, params = params, headers = HEADERS)
        data = response_json(response)

    if type(data) != "list" or not data or len(data) > 288:
        return None
    return sanitize_reading(data[0])

def get_session_id(client):
    """Get session ID following pydexcom authentication pattern"""

    # Get account ID first
    account_id = get_account_id(client)
    if not account_id:
        return None

    # Login with account ID to get session
    url = client["base_url"] + DEXCOM_LOGIN_ID_ENDPOINT

    body = json.encode({
        "accountId": account_id,
        "password": client["password"],
        "applicationId": client["app_id"],
    })

    response = http.post(
        url = url,
        headers = HEADERS,
        body = body,
        ttl_seconds = 0,  # Don't cache auth requests
    )

    body = response.body()
    if response.status_code != 200 or len(body) > 128:
        return None

    # Parse session ID (comes with quotes)
    session_id = body.strip('"')
    return session_id if valid_uuid(session_id) else None

def get_account_id(client):
    """Get account ID following pydexcom pattern"""

    # Authenticate to get account ID
    url = client["base_url"] + DEXCOM_AUTHENTICATE_ENDPOINT

    body = json.encode({
        "accountName": client["username"],
        "password": client["password"],
        "applicationId": client["app_id"],
    })

    response = http.post(
        url = url,
        headers = HEADERS,
        body = body,
        ttl_seconds = 0,  # Don't cache auth requests
    )

    body = response.body()
    if response.status_code != 200 or len(body) > 128:
        return None

    # Parse account ID (comes with quotes)
    account_id = body.strip('"')
    return account_id if valid_uuid(account_id) else None

def get_glucose_color(value, units):
    """Determine color based on glucose value"""

    # Convert thresholds if using mmol/L
    if units == "mmol/L":
        low = LOW_THRESHOLD * MMOL_L_CONVERSION_FACTOR
        high = HIGH_THRESHOLD * MMOL_L_CONVERSION_FACTOR
        urgent_low = URGENT_LOW * MMOL_L_CONVERSION_FACTOR
        urgent_high = URGENT_HIGH * MMOL_L_CONVERSION_FACTOR
    else:
        low = LOW_THRESHOLD
        high = HIGH_THRESHOLD
        urgent_low = URGENT_LOW
        urgent_high = URGENT_HIGH

    if value <= urgent_low or value >= urgent_high:
        return COLORS["urgent"]
    elif value < low:
        return COLORS["low"]
    elif value > high:
        return COLORS["high"]
    else:
        return COLORS["normal"]

def get_data_age_minutes(timestamp_str):
    """Calculate age of data in minutes from Dexcom timestamp"""

    if not timestamp_str:
        return 999

    # Extract milliseconds from "/Date(1234567890000)/" format
    start = timestamp_str.find("(")
    end = timestamp_str.find(")")

    if start == -1 or end == -1:
        return 999

    raw = timestamp_str[start + 1:end]
    digits = ""
    for char in raw.codepoints():
        if not char.isdigit():
            break
        digits += char
    if len(digits) < 10 or len(digits) > 16:
        return 999
    ms = int(digits)

    # Calculate difference from now
    now = time.now()
    now_ms = now.unix * 1000
    diff_minutes = (now_ms - ms) / 60000

    return max(0, int(diff_minutes))

def render_glucose_display(value, arrow, units, age, color):
    """Render the glucose display"""

    children = [
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = value,
                    font = "10x20",  # Much larger, bolder font for glucose value
                    color = color,
                ),
                render.Text(
                    content = " " + arrow,
                    font = "10x20",  # Larger font for arrow to match
                    color = color,
                ),
            ],
        ),
        render.Text(
            content = units,
            font = "CG-pixel-3x5-mono",
            color = "#FFFFFF",
        ),
    ]

    if age:
        children.append(render.Box(height = 2))  # Add space before time
        children.append(
            render.Text(
                content = age,
                font = "CG-pixel-3x5-mono",
                color = "#808080",
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = children,
        ),
    )

def render_no_config():
    """Render when no configuration is provided"""
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "Dexcom G7",
                    font = "5x8",
                ),
                render.Text(
                    content = "Setup required",
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
    )

def render_error(message):
    """Render error message"""
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "Error",
                    font = "5x8",
                    color = "#FF0000",
                ),
                render.Text(
                    content = message,
                    font = "CG-pixel-3x5-mono",
                    color = "#FFFFFF",
                ),
            ],
        ),
    )

def get_schema():
    """Configuration schema for the app"""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Dexcom Username",
                desc = "Your Dexcom Share username",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "password",
                name = "Dexcom Password",
                desc = "Your Dexcom Share password",
                icon = "lock",
                secret = True,
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Your Dexcom server region",
                icon = "globe",
                default = "us",
                options = [
                    schema.Option(
                        display = "United States",
                        value = "us",
                    ),
                    schema.Option(
                        display = "Outside US",
                        value = "ous",
                    ),
                    schema.Option(
                        display = "Japan",
                        value = "jp",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "units",
                name = "Glucose Units",
                desc = "Display units for glucose values",
                icon = "chartLine",
                default = "mg/dL",
                options = [
                    schema.Option(
                        display = "mg/dL",
                        value = "mg/dL",
                    ),
                    schema.Option(
                        display = "mmol/L",
                        value = "mmol/L",
                    ),
                ],
            ),
            schema.Toggle(
                id = "debug",
                name = "Debug Mode",
                desc = "Retained for saved-config compatibility; sensitive logs stay disabled",
                icon = "bug",
                default = False,
            ),
        ],
    )
