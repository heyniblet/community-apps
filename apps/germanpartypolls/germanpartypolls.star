load("bsoup.star", "bsoup")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64
MAX_HTML_BYTES = 512 * 1024

PARTY_COLOR_DICT = {
    "CDU/CSU": "#ffffff",
    "SPD": "#EB0000",
    "GRÜNE": "#66B032",
    "FDP": "#FFED00",
    "DIE LINKE": "#FF00FF",
    "AfD": "#0000FF",
    "FW": "#888888",
    "BSW": "#FFA500",
    "Sonstige": "#888888",
}

SHORT_PARTY_NAME_DICT = {
    "CDU/CSU": "CDU",
    "SPD": "SPD",
    "GRÜNE": "Grüne",
    "FDP": "FDP",
    "DIE LINKE": "Linke",
    "AfD": "AfD",
    "FW": "FW",
    "BSW": "BSW",
    "Sonstige": "Sonstige",
}

def main(config):
    response = http.get("https://www.wahlrecht.de/umfragen/", ttl_seconds = 21600)
    html_text = response.body()
    if response.status_code != 200 or not html_text or len(html_text) > MAX_HTML_BYTES:
        return render.Root(child = render.WrappedText("Polls unavailable"))
    data = extract_data(html_text)
    showing_data = get_representative_data(data, config)
    if not showing_data or not showing_data["results"]:
        return render.Root(child = render.WrappedText("Polls unavailable"))
    data_for_pie = [party for party in showing_data["results"] if can_be_float(str(party["percentage"]))]

    return render.Root(
        render.Row(
            [
                render.Column(main_align = "center", expanded = True, children = [
                    render.Padding(
                        pad = (1, 0, 3, 0),
                        child = render.Column(
                            [
                                render.Padding(
                                    pad = (0, 0, 0, 3),
                                    child = render.PieChart(
                                        colors = [PARTY_COLOR_DICT.get(party["name"], "#888888") for party in data_for_pie],
                                        weights = [float(party["percentage"]) for party in data_for_pie],
                                        diameter = 16,
                                    ),
                                ),
                                render.Text(
                                    str(showing_data["date"]["day"]) + "." + str(showing_data["date"]["month"]),
                                    font = "tom-thumb",
                                    color = "#ffffff",
                                ),
                            ],
                        ),
                    ),
                ]),
                render.Marquee(
                    render.Column([
                        render.Text(get_display_line_for_party(party), font = "tom-thumb", color = PARTY_COLOR_DICT.get(party["name"], "#888888"))
                        for party in showing_data["results"]
                    ], main_align = "center"),
                    scroll_direction = "vertical",
                    height = 32,
                    delay = 50,
                ),
            ],
        ),
    )

def get_display_line_for_party(party):
    space = 11
    name = SHORT_PARTY_NAME_DICT.get(party["name"], party["name"][:10])
    percentage = str(party["percentage"]) + "%" if can_be_float(str(party["percentage"])) else "?"
    spaces = space - visible_string_length(name) - len(percentage)
    return name + " " + (" " * (spaces - 1)) + percentage

def visible_string_length(s):
    special_chars = ["ü", "ä", "ö"]
    length = len(s)
    for char in special_chars:
        count = s.count(char)
        length -= count
    return length

def get_representative_data(results, config):
    # gets the most recent poll
    usable = [result for result in results if type(result.get("date")) == "dict" and type(result.get("results")) == "list" and result.get("results")]
    if not usable:
        return None
    latest = usable[0]
    for result in usable:
        # compare year, month, day
        if result["date"]["year"] > latest["date"]["year"]:
            latest = result
        elif result["date"]["year"] == latest["date"]["year"] and result["date"]["month"] > latest["date"]["month"]:
            latest = result
        elif result["date"]["year"] == latest["date"]["year"] and result["date"]["month"] == latest["date"]["month"] and result["date"]["day"] > latest["date"]["day"]:
            latest = result

    # rendering value
    for result in latest["results"]:
        percentage = result["percentage"]
        if can_be_float(percentage):
            # if a percentage is X.0 then make it an integer
            if float(percentage) % 1 == 0:
                result["percentage"] = str(int(percentage))
        else:
            # replace non-float percentages with "?"
            result["percentage"] = "?"

    # remove below 5%
    if config.bool("hide_below_5_percent"):
        latest["results"] = [result for result in latest["results"] if can_be_float(result["percentage"]) and float(result["percentage"]) >= 5]

    # remove Sonstige
    if config.bool("hide_sonstige"):
        latest["results"] = [result for result in latest["results"] if result["name"] != "Sonstige"]

    # print(latest["results"])

    # sort parties by percentage
    latest["results"] = sorted(latest["results"], key = lambda x: float(x["percentage"]) if can_be_float(x["percentage"]) else 0, reverse = True)

    return latest

def parse_date(date_str):
    parts = date_str.strip().split(".")
    if len(parts) != 3 or not all([part.isdigit() for part in parts]):
        return None
    day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
    if day < 1 or day > 31 or month < 1 or month > 12 or year < 2000 or year > 2100:
        return None
    return {
        "day": day,
        "month": month,
        "year": year,
    }

# Main extraction function.
def extract_data(html_text):
    # Parse the HTML document.
    doc = bsoup.parseHtml(html_text)

    results = []

    # Try to find the table with the polling data

    # Let's try to find the header row with "Institut"
    headers = doc.find_all("tr")
    p = 0

    for head in headers:
        row = head.child("th")
        if not row:
            continue
        row_title = row.get_text()
        if row_title == "Erhebung":
            continue
        elif row_title == "Institut":
            cols = row.parent().find_all("th", {"class": "in"})
            for j in range(0, min(len(cols), 32)):
                link = cols[j].child("a")
                if link == None:
                    continue
                results.append({
                    "name": " ".join(link.get_text().split())[:80],
                })
        elif row_title == "Veröffentl.":
            cols = row.parent().find_all("span", {"class": "li"})
            i = 0
            for col in cols:
                if i >= len(results):
                    break
                date = col.get_text()
                date = parse_date(date)
                if date:
                    results[i]["date"] = date
                i += 1
        else:
            party_name = " ".join(row_title.split())[:40]
            if not party_name or not results:
                continue
            cols = row.parent().find_all("td")
            i = 0

            # Prepare the results array for the current party in all poll creators
            if p == 0:
                for j in range(0, len(results)):
                    results[j]["results"] = []

            # Add the distribution to the current party
            for col in cols:
                if col.attrs().get("class") == "w":
                    continue
                if i >= len(results):
                    break
                percentage_string = col.get_text()
                percentage_string = percentage_string.replace(",", ".").replace("%", "").replace(" ", "")
                if can_be_float(percentage_string) and len(results[i].get("results", [])) < 30:
                    results[i]["results"].append({"name": party_name, "percentage": percentage_string})
                i += 1
            p += 1

    return results

def can_be_float(s):
    return type(s) == "string" and s.replace(".", "", 1).isdigit()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "hide_below_5_percent",
                name = "Hide below 5%",
                desc = "Hide parties with less than 5%",
                default = False,
                icon = "5",
            ),
            schema.Toggle(
                id = "hide_sonstige",
                name = "Hide Sonstige",
                desc = "Hide the rest of the parties labelled as 'Sonstige'",
                default = True,
                icon = "chartPie",
            ),
        ],
    )
