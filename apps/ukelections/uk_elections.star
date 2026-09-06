"""Show upcoming UK elections for a postcode or address slug."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://api.electoralcommission.org.uk/api/v1"
FONT = "tom-thumb"
PURPLE = "#373151"

def allowed(value, extra):
    return all([value[i].isalnum() or value[i] in extra for i in range(len(value))])

def fetch(kind, value, api_key):
    response = http.get(
        "%s/%s/%s/" % (API_URL, kind, value),
        params = {"token": api_key},
        headers = {"Accept": "application/json"},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 1048576:
        return None
    data = json.decode(body, None)
    return data if type(data) == "dict" else None

def header():
    return render.Box(color = PURPLE, height = 7, child = render.Padding(
        pad = (0, 1, 0, 0),
        child = render.WrappedText("Vote soon", width = 64, font = FONT, color = "#ffffff", align = "center"),
    ))

def error(message):
    return render.Root(child = render.Column(children = [
        header(),
        render.Padding(pad = (1, 3, 0, 0), child = render.WrappedText(message, width = 62, align = "center", font = FONT)),
    ]))

def date_text(date):
    text = date.format("Mon 2 Jan 2006")
    color = "#ffffff"
    today = time.now().in_location("Europe/London")
    if today.year == date.year and today.month == date.month and today.day == date.day:
        text, color = "TODAY", "#00ff00"
    elif (date - today) < 24 * time.hour:
        text, color = "TOMORROW", "#ff8000"
    elif (date - today) < 6 * 24 * time.hour:
        text, color = "On " + date.format("Monday"), "#ffff00"
    return render.WrappedText(text, width = 64, height = 7, align = "center", font = FONT, color = color)

def ballot(date, title):
    return render.Column(cross_align = "center", children = [
        render.Padding(pad = (0, 2, 0, 0), child = date_text(date)),
        render.Box(width = 32, height = 1, color = "#ffffff"),
        render.Padding(pad = (0, 2, 0, 0), child = render.WrappedText(title[:160], width = 64, align = "center", font = FONT)),
    ])

def valid_date(value):
    return type(value) == "string" and len(value) == 10 and value[4] == "-" and value[7] == "-" and (value[:4] + value[5:7] + value[8:]).isdigit()

def main(config):
    api_key = config.str("api_key", "")
    postcode = config.str("postcode", "SW1A 1AA").upper().replace(" ", "")
    address = config.str("address", "").strip()
    if not api_key or len(api_key) > 512:
        return error("Configure an Electoral Commission API key")
    if address:
        if len(address) > 160 or not allowed(address, ["-", "_"]):
            return error("Configure a valid address slug")
        data = fetch("address", address, api_key)
    else:
        if len(postcode) < 5 or len(postcode) > 8 or not allowed(postcode, []):
            return error("Configure a valid postcode")
        data = fetch("postcode", postcode, api_key)
    if data == None or data.get("error"):
        return error("Election data unavailable")

    dates = data.get("dates")
    if type(dates) != "list":
        return error("Invalid election data")
    elections = []
    for item in dates[:20]:
        if type(item) != "dict" or not valid_date(item.get("date")):
            continue
        ballots = item.get("ballots")
        if type(ballots) != "list":
            continue
        date = time.parse_time(item["date"], "2006-01-02", "Europe/London")
        for item_ballot in ballots[:20]:
            title = item_ballot.get("ballot_title") if type(item_ballot) == "dict" else None
            if type(title) == "string" and title:
                elections.append(ballot(date, title))
    if not elections:
        if config.bool("hide_empty", True):
            return []
        elections = [render.Padding(pad = (0, 3, 0, 0), child = render.WrappedText("No upcoming elections in your area", width = 64, align = "center", font = FONT))]
    return render.Root(delay = 2000, child = render.Column(children = [header(), render.Animation(children = elections[:40])]))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "api_key", name = "Electoral Commission API Key", desc = "API key from api.electoralcommission.org.uk.", icon = "key", secret = True),
        schema.Toggle(id = "hide_empty", name = "Hide when empty?", desc = "Only show this app when an election is upcoming.", icon = "eyeSlash", default = True),
        schema.Text(id = "postcode", name = "Postcode", desc = "UK postcode, with or without its space.", icon = "house", default = "SW1A 1AA"),
        schema.Text(id = "address", name = "Address slug (optional)", desc = "For split postcodes, paste the address slug returned by the provider.", icon = "houseFlag"),
    ])
