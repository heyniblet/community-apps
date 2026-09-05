"""
Applet: OPM Status
Summary: Displays current OPM status
Description: Displays the current Office of Personnel Management status, which is used by federal employees to know if the normal working conditions have been changed by inclement weather, health hazards, or other alerts. Updates every 5 minutes.
Author: AdamMoses-GitHub
Reference: https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/current-status/
"""

# -------------------------

load("http.star", "http")

# load some modules
load("render.star", "render")

# -------------------------

# URL to the OPM operating status JSON feed
OPM_JSON_URL = "https://www.opm.gov/json/operatingstatus.json"

# how often to refresh the feed, in seconds
EXPIRE_URL_DATA = 300
MAX_RESPONSE_BYTES = 64 * 1024
USER_AGENT = "Niblet/1.0 (heyniblet.com)"

DARK_YELLOW = "#AB9144"
DARK_RED = "#8B0000"
DARK_GREEN = "#006400"
DARK_BLUE = "#00008B"

# -------------------------

# takes the data from the URL get of the json and formats for display
def format_opm_url_data(opm_status_summary, opm_applies_to_date):
    # add period to end of status, if needed
    if not opm_status_summary.endswith("."):
        opm_status_summary += "."

    # split date into parts
    opm_date_split = opm_applies_to_date.split(" ")

    # extract the month name, day of month, and the year
    if len(opm_date_split) < 3:
        return opm_status_summary, opm_applies_to_date
    month_name = opm_date_split[0]
    day_value = opm_date_split[1].rstrip(",")
    year_value = opm_date_split[-1]

    # if month is more than 4 characters, reduce to 3 and add period
    if (len(month_name) > 4):
        month_name = month_name[0:3] + "."

    # combine elements for final date value
    opm_applies_to_date = "" + month_name + " " + day_value + " " + year_value

    return opm_status_summary, opm_applies_to_date

# -------------------------

def main():
    # query the JSON url to get the opm status data
    url_response = http.get(
        OPM_JSON_URL,
        headers = {"User-Agent": USER_AGENT},
        ttl_seconds = EXPIRE_URL_DATA,
    )

    body = url_response.body()
    if url_response.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return render.Root(child = render.WrappedText(content = "OPM status unavailable", color = DARK_YELLOW))

    # grab relevant parts from the JSON dict
    data = url_response.json()
    if type(data) != "dict":
        return render.Root(child = render.WrappedText(content = "OPM status unavailable", color = DARK_YELLOW))
    statussummary_val = data.get("StatusSummary")
    appliesto_val = data.get("AppliesTo")
    statustype_val = data.get("Icon")
    if type(statussummary_val) != "string" or type(appliesto_val) != "string":
        return render.Root(child = render.WrappedText(content = "OPM status unavailable", color = DARK_YELLOW))

    # format the parts using function
    opm_status_summary, opm_applies_to_date = format_opm_url_data(statussummary_val, appliesto_val)
    opm_status_type = statustype_val

    # assume color is green for "Open", otherwise set color accordingly
    status_color = DARK_GREEN
    if (opm_status_type == "Alert"):
        status_color = DARK_YELLOW
    elif (opm_status_type == "Closed"):
        status_color = DARK_RED

    # build the relevant text widgets
    status_title_text = render.Text("OPM Status:")
    status_text = render.Marquee(
        width = 64,
        child = render.Text(opm_status_summary, color = status_color),
        offset_start = 64,
    )
    for_date_text = render.Text("For Date:")
    applies_to_text = render.Text(
        content = opm_applies_to_date,
        color = DARK_BLUE,
    )

    # build widget from all rows of above text
    all_rows = render.Column(children = [
        status_title_text,
        status_text,
        for_date_text,
        applies_to_text,
    ])

    # return the rendered rows widget
    return render.Root(
        child = all_rows,
    )

# -------------------------

# --- THE END ---
