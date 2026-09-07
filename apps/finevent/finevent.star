"""
Applet: Finevent
Summary: Upcoming financial events
Description: Displays the daily economic or earnings calendar.
Author: Rob Kimball
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/importance_high.png", IMPORTANCE_HIGH_ASSET = "file")
load("images/importance_low.png", IMPORTANCE_LOW_ASSET = "file")
load("images/importance_medium.png", IMPORTANCE_MEDIUM_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://api.tradingeconomics.com"
DATEFMT = "2006-01-02T15:04:05"
MAX_RELEASE_SECONDS = 60 * 90  # we only show releases occurring the last/next N minutes
DEFAULT_HIDDEN = False
REGIONS = {
    "Global": [],
    "US-only": ["United States"],
    # "North America": ["United States", "Canada"],
    # "EAFE": [
    #     "Austria",
    #     "Belgium",
    #     "Denmark",
    #     "Finland",
    #     "France",
    #     "Germany",
    #     "Ireland",
    #     "Israel",
    #     "Italy",
    #     "Netherlands",
    #     "Norway",
    #     "Portugal",
    #     "Spain",
    #     "Sweden",
    #     "Switzerland",
    #     "United Kingdom",
    #     "Australia",
    #     "New Zealand",
    #     "Hong Kong",
    #     "Singapore",
    #     "Japan",
    # ],
    # "EM": [
    #     "Brazil",
    #     "Chile",
    #     "China",
    #     "Colombia",
    #     "Czech Republic",
    #     "Egypt",
    #     "Greece",
    #     "Hungary",
    #     "India",
    #     "Indonesia",
    #     "Korea",
    #     "Kuwait",
    #     "Malaysia",
    #     "Mexico",
    #     "Peru",
    #     "Philippines",
    #     "Poland",
    #     "Qatar",
    #     "Russia",
    #     "Saudi Arabia",
    #     "South Africa",
    #     "Taiwan",
    #     "Thailand",
    #     "Turkey",
    #     "United Arab Emirates",
    # ],
    # "G7": ["United States", "Canada", "France", "Germany", "Italy", "Japan", "United Kingdom"],
}

ISO3166 = {
    "Afghanistan": "af",
    "Åland Islands": "ax",
    "Albania": "al",
    "Algeria": "dz",
    "American Samoa": "as",
    "Andorra": "ad",
    "Angola": "ao",
    "Anguilla": "ai",
    "Antarctica": "aq",
    "Antigua and Barbuda": "ag",
    "Argentina": "ar",
    "Armenia": "am",
    "Aruba": "aw",
    "Australia": "au",
    "Austria": "at",
    "Azerbaijan": "az",
    "Bahamas": "bs",
    "Bahrain": "bh",
    "Bangladesh": "bd",
    "Barbados": "bb",
    "Belarus": "by",
    "Belgium": "be",
    "Belize": "bz",
    "Benin": "bj",
    "Bermuda": "bm",
    "Bhutan": "bt",
    "Bolivia": "bo",
    "Bolivia, Plurinational State of": "bo",
    "Bosnia and Herzegovina": "ba",
    "Botswana": "bw",
    "Bouvet Island": "bv",
    "Brazil": "br",
    "British Indian Ocean Territory": "io",
    "Brunei Darussalam": "bn",
    "Brunei": "bn",
    "Bulgaria": "bg",
    "Burkina Faso": "bf",
    "Burundi": "bi",
    "Cambodia": "kh",
    "Cameroon": "cm",
    "Canada": "ca",
    "Cape Verde": "cv",
    "Cayman Islands": "ky",
    "Central African Republic": "cf",
    "Chad": "td",
    "Chile": "cl",
    "China": "cn",
    "Christmas Island": "cx",
    "Cocos (Keeling) Islands": "cc",
    "Colombia": "co",
    "Comoros": "km",
    "Congo": "cg",
    "Congo, the Democratic Republic of the": "cd",
    "Democratic Republic of the Congo": "cd",
    "Cook Islands": "ck",
    "Costa Rica": "cr",
    "Côte d'Ivoire": "ci",
    "Ivory Coast": "ci",
    "Croatia": "hr",
    "Cuba": "cu",
    "Cyprus": "cy",
    "Czech Republic": "cz",
    "Denmark": "dk",
    "Djibouti": "dj",
    "Dominica": "dm",
    "Dominican Republic": "do",
    "Ecuador": "ec",
    "Egypt": "eg",
    "El Salvador": "sv",
    "Equatorial Guinea": "gq",
    "Eritrea": "er",
    "Estonia": "ee",
    "Ethiopia": "et",
    "Euro Area": "eu",
    "European Union": "eu",
    "Falkland Islands (Malvinas)": "fk",
    "Faroe Islands": "fo",
    "Fiji": "fj",
    "Finland": "fi",
    "France": "fr",
    "French Guiana": "gf",
    "French Polynesia": "pf",
    "French Southern Territories": "tf",
    "Gabon": "ga",
    "Gambia": "gm",
    "Georgia": "ge",
    "Germany": "de",
    "Ghana": "gh",
    "Gibraltar": "gi",
    "Greece": "gr",
    "Greenland": "gl",
    "Grenada": "gd",
    "Guadeloupe": "gp",
    "Guam": "gu",
    "Guatemala": "gt",
    "Guernsey": "gg",
    "Guinea": "gn",
    "Guinea-Bissau": "gw",
    "Guyana": "gy",
    "Haiti": "ht",
    "Heard Island and McDonald Islands": "hm",
    "Holy See (Vatican City State)": "va",
    "Honduras": "hn",
    "Hong Kong": "hk",
    "Hungary": "hu",
    "Iceland": "is",
    "India": "in",
    "Indonesia": "id",
    "Iran": "ir",
    "Iran, Islamic Republic of": "ir",
    "Iraq": "iq",
    "Ireland": "ie",
    "Isle of Man": "im",
    "Israel": "il",
    "Italy": "it",
    "Jamaica": "jm",
    "Japan": "jp",
    "Jersey": "je",
    "Jordan": "jo",
    "Kazakhstan": "kz",
    "Kenya": "ke",
    "Kiribati": "ki",
    "Korea, Democratic People's Republic of": "kp",
    "Korea, Republic of": "kr",
    "Republic of Korea": "kr",
    "Kuwait": "kw",
    "Kyrgyzstan": "kg",
    "Lao People's Democratic Republic": "la",
    "Latvia": "lv",
    "Lebanon": "lb",
    "Lesotho": "ls",
    "Liberia": "lr",
    "Libyan Arab Jamahiriya": "ly",
    "Liechtenstein": "li",
    "Lithuania": "lt",
    "Luxembourg": "lu",
    "Macao": "mo",
    "Macedonia": "mk",
    "Macedonia, the former Yugoslav Republic of": "mk",
    "Madagascar": "mg",
    "Malawi": "mw",
    "Malaysia": "my",
    "Maldives": "mv",
    "Mali": "ml",
    "Malta": "mt",
    "Marshall Islands": "mh",
    "Martinique": "mq",
    "Mauritania": "mr",
    "Mauritius": "mu",
    "Mayotte": "yt",
    "Mexico": "mx",
    "Micronesia": "fm",
    "Micronesia, Federated States of": "fm",
    "Federated States of Micronesia": "fm",
    "Moldova": "md",
    "Moldova, Republic of": "md",
    "Republic of Moldova": "md",
    "Monaco": "mc",
    "Mongolia": "mn",
    "Montenegro": "me",
    "Montserrat": "ms",
    "Morocco": "ma",
    "Mozambique": "mz",
    "Myanmar": "mm",
    "Namibia": "na",
    "Nauru": "nr",
    "Nepal": "np",
    "Netherlands": "nl",
    "Netherlands Antilles": "an",
    "New Caledonia": "nc",
    "New Zealand": "nz",
    "Nicaragua": "ni",
    "Niger": "ne",
    "Nigeria": "ng",
    "Niue": "nu",
    "Norfolk Island": "nf",
    "Northern Mariana Islands": "mp",
    "Norway": "no",
    "Oman": "om",
    "Pakistan": "pk",
    "Palau": "pw",
    "Palestine": "ps",
    "Palestinian Territory, Occupied": "ps",
    "Panama": "pa",
    "Papua New Guinea": "pg",
    "Paraguay": "py",
    "Peru": "pe",
    "Philippines": "ph",
    "Pitcairn": "pn",
    "Poland": "pl",
    "Portugal": "pt",
    "Puerto Rico": "pr",
    "Qatar": "qa",
    "Réunion": "re",
    "Romania": "ro",
    "Russian Federation": "ru",
    "Rwanda": "rw",
    "Saint Barthélemy": "bl",
    "Saint Helena": "sh",
    "Saint Helena, Ascension and Tristan da Cunha": "sh",
    "Saint Kitts and Nevis": "kn",
    "Saint Lucia": "lc",
    "Saint Martin (French part)": "mf",
    "Saint Martin": "mf",
    "Saint Pierre and Miquelon": "pm",
    "Saint Vincent and the Grenadines": "vc",
    "Samoa": "ws",
    "San Marino": "sm",
    "Sao Tome and Principe": "st",
    "Saudi Arabia": "sa",
    "Senegal": "sn",
    "Serbia": "rs",
    "Seychelles": "sc",
    "Sierra Leone": "sl",
    "Singapore": "sg",
    "Slovakia": "sk",
    "Slovenia": "si",
    "Solomon Islands": "sb",
    "Somalia": "so",
    "South Africa": "za",
    "South Korea": "kr",
    "South Georgia": "gs",
    "South Georgia and the South Sandwich Islands": "gs",
    "Spain": "es",
    "Sri Lanka": "lk",
    "Sudan": "sd",
    "Suriname": "sr",
    "Svalbard and Jan Mayen": "sj",
    "Swaziland": "sz",
    "Sweden": "se",
    "Switzerland": "ch",
    "Syrian Arab Republic": "sy",
    "Taiwan, Province of China": "tw",
    "Taiwan": "tw",
    "Tajikistan": "tj",
    "Tanzania, United Republic of": "tz",
    "Tanzania": "tz",
    "Thailand": "th",
    "Timor-Leste": "tl",
    "Togo": "tg",
    "Tokelau": "tk",
    "Tonga": "to",
    "Trinidad and Tobago": "tt",
    "Tunisia": "tn",
    "Turkey": "tr",
    "Turkmenistan": "tm",
    "Turks and Caicos Islands": "tc",
    "Tuvalu": "tv",
    "Uganda": "ug",
    "Ukraine": "ua",
    "United Arab Emirates": "ae",
    "United Kingdom": "gb",
    "United States": "us",
    "United States Minor Outlying Islands": "um",
    "Uruguay": "uy",
    "Uzbekistan": "uz",
    "Vanuatu": "vu",
    "Venezuela, Bolivarian Republic of": "ve",
    "Venezuela": "ve",
    "Viet Nam": "vn",
    "Vietnam": "vn",
    "Virgin Islands, British": "vg",
    "British Virgin Islands": "vg",
    "Virgin Islands, U.S.": "vi",
    "U.S. Virgin Islands": "vi",
    "Wallis and Futuna": "wf",
    "Western Sahara": "eh",
    "Yemen": "ye",
    "Zambia": "zm",
    "Zimbabwe": "zw",
}

IMPORTANCE_ICONS = {
    1: IMPORTANCE_LOW_ASSET.readall(),
    2: IMPORTANCE_MEDIUM_ASSET.readall(),
    3: IMPORTANCE_HIGH_ASSET.readall(),
}

def flag_api(country_name):
    code = ISO3166.get(country_name)
    if not code:
        return None
    flag_resp = http.get("https://flagcdn.com/w20/%s.png" % code, ttl_seconds = 60 * 60 * 24 * 30)
    body = flag_resp.body()
    return body if flag_resp.status_code == 200 and body and len(body) <= 64 * 1024 else None

def event_value(value, limit):
    return str(value)[:limit] if type(value) in ["string", "int", "float"] else ""

def clean_event(event, countries):
    if type(event) != "dict":
        return None
    date = event.get("Date")
    country = event.get("Country")
    name = event.get("Event")
    importance = event.get("Importance")
    if type(date) != "string" or re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$", date) == None:
        return None
    if type(country) != "string" or not country or len(country) > 100 or countries and country not in countries:
        return None
    if type(name) != "string" or not name or len(name) > 300:
        return None
    if type(importance) not in ["int", "float"] or int(importance) not in [1, 2, 3]:
        return None
    return {
        "Date": date,
        "Country": country,
        "Event": name,
        "Importance": int(importance),
        "Previous": event_value(event.get("Previous"), 40),
        "Forecast": event_value(event.get("Forecast"), 40),
        "TEForecast": event_value(event.get("TEForecast"), 40),
        "Actual": event_value(event.get("Actual"), 40),
    }

def make_error(message):
    return render.Root(child = render.WrappedText(message, color = "#ff5555"))

def random(max):
    """Borrowed from nipterink's nft.star"""
    return (time.now().nanosecond // 1000) % max

def main(config):
    api_key = config.get("api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 512:
        return make_error("Trading Economics key required")
    timezone = time.tz()
    region = config.get("region", "US-only")
    region = region if region in REGIONS else "US-only"
    countries = REGIONS[region]
    future_events = config.bool("future", True)
    self_hide = config.bool("self-hide", DEFAULT_HIDDEN)
    importance_value = str(config.get("importance", "3"))
    importance = int(importance_value) if importance_value in ["1", "2", "3"] else 3
    title_font = "CG-pixel-3x5-mono"
    NULL = "--"

    now = time.now()

    filtered_events = []
    url_countries = "all" if not countries else ",".join([country.lower().replace(" ", "%20") for country in countries])
    encoded_key = humanize.url_encode(api_key)
    for imp in range(importance, 4):
        request_url = "%s/calendar/country/%s?c=%s&f=json&importance=%s" % (BASE_URL, url_countries, encoded_key, imp)
        response = http.get(request_url)
        body = response.body()
        events = json.decode(body, None) if response.status_code == 200 and body and len(body) <= 2 * 1024 * 1024 else None
        if type(events) != "list":
            continue
        for candidate in events[:500]:
            event = clean_event(candidate, countries)
            if event:
                filtered_events.append(event)

    for event in filtered_events:
        event["ReleaseTime"] = time.parse_time(event.get("Date", ""), format = DATEFMT).in_location(timezone)
        event["TimeFromNow"] = int(abs((now - event["ReleaseTime"]).seconds))

    if self_hide:
        filtered_events = [e for e in filtered_events if e["TimeFromNow"] < MAX_RELEASE_SECONDS]

    sorted_events = sorted(filtered_events, key = lambda x: x["TimeFromNow"], reverse = False)

    if not future_events:
        _events = []
        for e in sorted_events:
            if e.get("ReleaseTime") <= now:
                _events.append(e)
        sorted_events = _events

    if not len(sorted_events):
        return []

    choice = random(len(sorted_events))
    right_title = "Prior"
    right_color = "#fb8b1e"

    # If there are multiple events at this importance level, display a random one each time the app rotates
    event = sorted_events[choice]
    importance = event.get("Importance", 1)
    name = event.get("Event")

    # Localize UTC time
    release_time_format = "3:04 PM" if event.get("TimeFromNow") < (60 * 60 * 24 - 1) else "1/2 PM"
    display_time = event.get("ReleaseTime", NULL).format(release_time_format)

    survey = str(event.get("Forecast", NULL) or event.get("TEForecast", NULL))
    if survey == "":
        survey = NULL

    right = str(event.get("Previous", "--"))
    if right == "":
        right = NULL
    if event.get("ReleaseTime", now) <= now and event.get("Actual", "") != "":
        right_title = "Actual"
        right_color = "#fff"
        right = str(event.get("Actual", "--"))
        if right == "":
            right = NULL

    country = event.get("Country", None)

    flag = flag_api(country)
    country_code = (ISO3166.get(country) or "??").upper()

    defaults = {
        "main_align": "space_between",
        "expanded": True,
        "cross_align": "start",
    }

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_around",
                    children = [
                        render.Image(IMPORTANCE_ICONS[importance], width = 10, height = 10),
                        render.Image(flag, width = 15, height = 10) if flag else render.Text(country_code, font = title_font),
                        render.Row(expanded = True, main_align = "center", children = [render.Text(display_time)]),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(name),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = [
                        render.Column(
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Text("Survey", color = "#fb8b1e", font = title_font),
                                render.Text(survey, color = "#fb8b1e"),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Text(right_title, color = right_color, font = title_font),
                                render.Text(right, color = right_color),
                            ],
                        ),
                    ],
                ),
            ],
            **defaults
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Trading Economics API Key",
                desc = "Your Trading Economics API key or client:secret credential.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "region",
                name = "Event Region",
                desc = "Filter economic events by countries within the region of interest.",
                icon = "earthEurope",
                options = [schema.Option(value = k, display = k) for k in REGIONS.keys()],
                default = "US-only",
            ),
            schema.Dropdown(
                id = "importance",
                name = "Minimum importance",
                desc = "Only show events rated over a certain level of importance.",
                icon = "bell",
                options = [schema.Option(value = v, display = d) for d, v in [
                    ("Low", "1"),
                    ("Medium", "2"),
                    ("High", "3"),
                ]],
                default = "3",
            ),
            schema.Toggle(
                id = "future",
                name = "Include unreleased?",
                desc = "If turned off, we will hide any upcoming releases and only show events after data is available.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "self-hide",
                name = "Nearby events only?",
                desc = "If turned on, the app will show a blank screen unless there is an event within 90 minutes.",
                icon = "gear",
                default = DEFAULT_HIDDEN,
            ),
        ],
    )
