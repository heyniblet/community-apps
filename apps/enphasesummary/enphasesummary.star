"""
Applet: Enphase summary
Summary: Enphase daily, monthly, annual and lifetime summary
Description: Daily, monthly, annual and lifetime energy production and consumption for your Enphase solar system (via proxy)
Author: Converted from SolarEdge version by ckyr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/plug_sum.gif", PLUG_SUM_ASSET = "file")
load("images/sun_sum.png", SUN_SUM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PLUG_SUM = PLUG_SUM_ASSET.readall()
SUN_SUM = SUN_SUM_ASSET.readall()

# Cache for 1 minute only - let Tronbyt control refresh timing
# Proxy has 2-hour cache, so API calls are minimized regardless of render frequency
MAX_RESPONSE_BYTES = 256 * 1024

# Colors
GRAY = "#777777"
RED = "#AA0000"
GREEN = "#00FF00"
WHITE = "#FFFFFF"

# Icons (same as original)

def format_energy(wh):
    """Format energy value with appropriate unit (kWh, MWh, or GWh)."""
    wh = safe_energy(wh)
    if wh >= 1000000000:  # >= 1 GWh
        return humanize.float("#,###.##", wh / 1000000000) + " GWh"
    elif wh >= 1000000:  # >= 1 MWh
        return humanize.float("#,###.##", wh / 1000000) + " MWh"
    else:  # kWh
        return humanize.float("#,###.##", wh / 1000) + " kWh"

def create_summary_frame(title, production, consumption):
    """Create a summary frame with title and energy values."""
    return render.Stack(
        children = [
            render.Column(
                main_align = "space_evenly",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(title),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.Image(src = SUN_SUM),
                                    render.Image(src = PLUG_SUM),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = " " + format_energy(production),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = " " + format_energy(consumption),
                                        font = "5x8",
                                        color = RED,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def main(config):
    proxy_url = safe_proxy_url(config.str("proxy_url", ""))
    api_key = safe_api_key(config.str("api_key", ""))

    frames = []

    # Get energy data from proxy
    if proxy_url and api_key:
        # Build the full URL
        full_url = proxy_url + "/api/solar"

        # Call the proxy service
        rep = http.get(
            full_url,
            headers = {"X-API-Key": api_key},
        )

        if rep.status_code != 200:
            return render.Root(render.Box(render.WrappedText("Proxy Error: " + str(rep.status_code), color = RED)))

        body = rep.body()
        data = json.decode(body, None) if body and len(body) <= MAX_RESPONSE_BYTES else None

        if type(data) != "dict" or "error" in data:
            return render.Root(render.Box(render.WrappedText("Invalid proxy response", color = RED)))

        periods = data.get("periods")
        if type(periods) != "dict":
            periods = {}

        # Day
        day_data = safe_period(periods.get("day"))
        frames.append(create_summary_frame(
            "Energy Today",
            day_data.get("production_wh", 0),
            day_data.get("consumption_wh", 0),
        ))

        # Week
        week_data = safe_period(periods.get("week"))
        frames.append(create_summary_frame(
            "Energy Week",
            week_data.get("production_wh", 0),
            week_data.get("consumption_wh", 0),
        ))

        # Month
        month_data = safe_period(periods.get("month"))
        frames.append(create_summary_frame(
            "Energy Month",
            month_data.get("production_wh", 0),
            month_data.get("consumption_wh", 0),
        ))

        # Year
        year_data = safe_period(periods.get("year"))
        frames.append(create_summary_frame(
            "Energy Year",
            year_data.get("production_wh", 0),
            year_data.get("consumption_wh", 0),
        ))

        # Lifetime
        lifetime_data = safe_period(periods.get("lifetime"))
        frames.append(create_summary_frame(
            "Energy Life",
            lifetime_data.get("production_wh", 0),
            lifetime_data.get("consumption_wh", 0),
        ))
    else:
        # Demo data if no credentials
        frames.append(create_summary_frame("Energy Today", 6282, 3141))
        frames.append(create_summary_frame("Energy Week", 43974, 21987))
        frames.append(create_summary_frame("Energy Month", 188460, 94230))
        frames.append(create_summary_frame("Energy Year", 2261520, 1130760))
        frames.append(create_summary_frame("Energy Life", 11307600, 0))

    # Return animation with frames
    return render.Root(
        delay = 3000,  # 3 seconds per frame
        child = render.Animation(children = frames),
    )

def safe_proxy_url(value):
    value = str(value or "").strip().rstrip("/")
    if len(value) > 512 or not value.startswith("https://"):
        return ""
    host = value[len("https://"):]
    if not host or any([char in host for char in ["/", "@", ":", "?", "#", "\\", " ", "\t", "\r", "\n"]]):
        return ""
    return value

def safe_api_key(value):
    value = str(value or "").strip()
    return value if value and len(value) <= 512 and "\r" not in value and "\n" not in value else ""

def safe_energy(value):
    return min(1000000000000000, max(0, value)) if type(value) in ["int", "float"] else 0

def safe_period(value):
    return value if type(value) == "dict" else {}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "proxy_url",
                name = "Proxy URL",
                desc = "HTTPS origin of your Enphase proxy service (for example, your-app.onrender.com)",
                icon = "globe",
            ),
            schema.Text(
                id = "api_key",
                name = "Proxy API Key",
                desc = "API key for authenticating with your proxy service",
                icon = "key",
                secret = True,
            ),
        ],
    )
