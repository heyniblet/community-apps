"""
Applet: WorldCapitals
Summary: Displays a world capital
Description: Displays a world capital each day for a specific country.
Author: Jake Manske
"""

load("flags/DEFAULT.png", DEFAULT_FLAG = "file")
load("flags.star", "FLAGS")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

COUNTRIES_API_BASE = "https://api.restcountries.com/countries/v5"
COUNTRIES_API_FIELDS = "names,codes,capitals,flag"
COUNTRIES_API_PAGE_SIZE = 100

# start on Jan 1 2023
REFERENCE_DATE = time.parse_time("2023-01-01T00:00:00Z")

# other config
HTTP_OK = 200

def main(config):
    """ gets the country based on the current configuration

    Args:
        config (dict): configuration for the app
    Returns:
        widget to display
    """

    scale = 2 if canvas.is2x() else 1
    font = "terminus-12" if scale == 2 else "tom-thumb"

    # get current country index
    # it will be the number of hours since the reference date
    frequency_config = config.get("frequency", "24")
    frequency = int(frequency_config) if frequency_config in ["0", "1", "24"] else 24
    country_index = int((time.now() - REFERENCE_DATE).hours // frequency) if frequency != 0 else -1

    # get the region selected
    region = config.get("region") or "all"
    region = region if region in ["all", "africa", "americas", "asia", "europe", "oceania"] else "all"

    # get the API key
    api_key = config.get("api_key") or "rc_live_demo"
    if type(api_key) != "string" or not api_key or len(api_key) > 256:
        return render.Root(child = render.WrappedText("Configure a REST Countries API key", width = 64, align = "center"))

    # get the country for the current config
    country = get_country(region, country_index, api_key)

    # parse country information
    capitals = country.get("capitals") if type(country) == "dict" else None
    if type(capitals) == "list" and len(capitals) > 0 and type(capitals[0]) == "dict":
        capital_city = str(capitals[0].get("name") or "No Capital City")[:100]
    else:
        capital_city = "No Capital City"

    # get the common name
    names = country.get("names") if type(country) == "dict" else None
    names = names if type(names) == "dict" else {"common": "Country unavailable"}
    lang = config.get("language") or "eng"
    lang = lang if lang in ["eng", "native", "deu", "fra", "ita", "jpn", "spa"] else "eng"
    if lang == "eng":
        country_name = names
    elif lang == "native":
        native = names.get("native")
        if type(native) == "dict" and native:
            country_name = native.values()[0]
        else:
            country_name = None
    else:
        translations = names.get("translations")
        if translations:
            country_name = translations.get(lang)
        else:
            country_name = None
    if not country_name:
        country_name = names
    country_name = str(country_name.get("common") or "Country unavailable")[:100] if type(country_name) == "dict" else "Country unavailable"

    # look up the flag
    flag = get_flag(country)

    # render the widget
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Marquee(
                    align = "center",
                    child = render.Text(
                        content = country_name,
                        font = font,
                    ),
                    width = canvas.width(),
                ),
                render.Image(
                    src = flag,
                    height = 19 * scale,
                ),
                render.Box(
                    height = 1 * scale,
                ),
                render.Marquee(
                    align = "center",
                    child = render.Text(
                        content = capital_city,
                        font = font,
                    ),
                    width = canvas.width(),
                ),
            ],
        ),
    )

def get_country(region, country_index, api_key):
    """ gets the country based on the current configuration

    Args:
        region (string): the region we are limited to
        country_index (int): the index of the country we are processing
        api_key (string): the REST Countries v5 API key
    Returns:
        a dict "country" object
    """

    headers = {"Authorization": "Bearer " + api_key}

    # paginate to collect all countries (max 5 pages = 500 countries)
    all_countries = []
    for _ in range(5):
        params = {
            "response_fields": COUNTRIES_API_FIELDS,
            "limit": str(COUNTRIES_API_PAGE_SIZE),
            "offset": str(len(all_countries)),
        }
        if region != "all":
            params["region"] = region
        response = http.get(COUNTRIES_API_BASE, headers = headers, params = params)

        if response.status_code != HTTP_OK:
            return {
                "names": {
                    "common": "HTTP ERROR",
                },
                "codes": {
                    "alpha_3": "N/A",
                },
                "capitals": [{"name": "ERROR CODE: " + str(response.status_code)}],
            }

        data = response.json()
        page = data.get("data") if type(data) == "dict" else None
        objects = page.get("objects") if type(page) == "dict" else None
        if type(objects) != "list":
            break
        for country in objects[:COUNTRIES_API_PAGE_SIZE]:
            if type(country) == "dict" and get_cca3(country):
                all_countries.append(country)

        meta = page.get("meta") if type(page) == "dict" else None
        if type(meta) != "dict" or not meta.get("more"):
            break

    # sort by country code for consistent ordering
    sorted_countries = sorted(all_countries, get_cca3)

    # count how many results we have
    num_countries = len(sorted_countries)
    if num_countries == 0:
        return {
            "names": {"common": "No countries found"},
            "codes": {"alpha_3": ""},
            "capitals": [{"name": "Check API configuration"}],
        }

    # get the country based on index modulo how many countries there are for this region
    if country_index < 0:
        country_index = random.number(0, num_countries - 1)
    else:
        country_index = country_index % num_countries
    country = sorted_countries[country_index]

    return country

def get_schema():
    region_options = [
        schema.Option(
            display = "All",
            value = "all",
        ),
        schema.Option(
            display = "Africa",
            value = "africa",
        ),
        schema.Option(
            display = "Americas",
            value = "americas",
        ),
        schema.Option(
            display = "Asia",
            value = "asia",
        ),
        schema.Option(
            display = "Europe",
            value = "europe",
        ),
        schema.Option(
            display = "Oceania",
            value = "oceania",
        ),
    ]

    languages = [
        schema.Option(
            display = "English",
            value = "eng",
        ),
        schema.Option(
            display = "Native",
            value = "native",
        ),
        schema.Option(
            display = "German",
            value = "deu",
        ),
        schema.Option(
            display = "French",
            value = "fra",
        ),
        schema.Option(
            display = "Italian",
            value = "ita",
        ),
        schema.Option(
            display = "Japanese",
            value = "jpn",
        ),
        schema.Option(
            display = "Spanish",
            value = "spa",
        ),
    ]

    frequency = [
        schema.Option(
            display = "Daily",
            value = "24",
        ),
        schema.Option(
            display = "Hourly",
            value = "1",
        ),
        schema.Option(
            display = "Everytime",
            value = "0",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Limit world capitals to this region.",
                icon = "globe",
                default = "all",
                options = region_options,
            ),
            schema.Dropdown(
                id = "language",
                name = "Language",
                desc = "The language to use for the country name.",
                icon = "language",
                default = "eng",
                options = languages,
            ),
            schema.Dropdown(
                id = "frequency",
                name = "Frequency",
                desc = "How often to display a different country.",
                icon = "repeat",
                default = "24",
                options = frequency,
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "REST Countries v5 API key. Sign up for free at restcountries.com.",
                icon = "key",
                default = "rc_live_demo",
                secret = True,
            ),
        ],
    )

def get_cca3(country):
    codes = country.get("codes") if type(country) == "dict" else None
    code = codes.get("alpha_3") if type(codes) == "dict" else None
    return code if type(code) == "string" and len(code) == 3 else ""

def get_flag(country):
    """ gets the flag based on the country

    Args:
        country (string): the country whose flag we need
    Returns:
        a flag image as bytes
    """

    # Bundled flags avoid following an API-controlled URL.
    country_code = get_cca3(country)
    flag = FLAGS.get(country_code) or DEFAULT_FLAG
    return flag.readall()
