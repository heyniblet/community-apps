"""
Applet: NPM Packages
Summary: View NPM package downloads
Description: Track the number of downloads of a NPM package on the last day, week or month.
Author: Daniel Sitnik
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/download_logo.png", DOWNLOAD_LOGO_ASSET = "file")
load("images/npm_logo.png", NPM_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DOWNLOAD_LOGO = DOWNLOAD_LOGO_ASSET.readall()
NPM_LOGO = NPM_LOGO_ASSET.readall()

DATA_URL = "https://api.npmjs.org/downloads/range/last-%s/%s"
DEFAULT_PACKAGE = json.encode({"display": "axios", "value": "axios"})
DEFAULT_DOWNLOAD_PERIOD = "week"
CACHE_TTL = 21600  # 6 hours

def main(config):
    """Main app function.

    Args:
        config (config): The app configuration options.

    Returns:
        render.Root: The root widget tree to render the app.
    """

    # get configs
    package_config = config.str("package", DEFAULT_PACKAGE).strip()
    package = (json.decode(package_config).get("value", "") if package_config.startswith("{") else package_config)
    download_period = config.str("download_period", DEFAULT_DOWNLOAD_PERIOD)
    if not valid_package(package):
        return render_error(400, "Invalid package")
    if download_period not in ["day", "week", "month"]:
        download_period = DEFAULT_DOWNLOAD_PERIOD

    # get package data
    package_name = package
    url = DATA_URL % (download_period, humanize.url_encode(package_name))
    res = http.get(url, ttl_seconds = CACHE_TTL)

    # handle api response
    if res.status_code != 200:
        return render_error(res.status_code, "NPM API unavailable")

    body = res.body()
    if not body or len(body) > 1048576:
        return render_error(502, "Invalid NPM response")
    data = json.decode(body)
    downloads = data.get("downloads", []) if type(data) == "dict" else []
    if type(downloads) != "list" or not downloads:
        return render_error(502, "No download data")

    # prepare chart data
    counter = 0
    total_downloads = 0
    chart_data = []

    for item in downloads[:31]:
        count = item.get("downloads", 0) if type(item) == "dict" else 0
        count = count if type(count) == "int" and count >= 0 else 0
        chart_data.append((float(counter), count))
        total_downloads += count
        counter += 1

    humanized_downloads = humanize.comma(total_downloads)

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = NPM_LOGO, height = 10),
                        ),
                        render.Marquee(
                            width = 52,
                            child = render.Text(content = package_name, color = "#f00"),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = DOWNLOAD_LOGO, height = 12),
                        ),
                        render.Text(humanized_downloads),
                    ],
                ),
                render.Plot(
                    data = chart_data,
                    width = 64,
                    height = 8,
                    color = "#8258f6",
                    color_inverted = "#d96d66",
                    fill = True,
                    fill_color = "#e6defd",
                    fill_color_inverted = "#3e1f1c",
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    download_options = [
        schema.Option(display = "Last day", value = "day"),
        schema.Option(display = "Last week", value = "week"),
        schema.Option(display = "Last month", value = "month"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "package",
                name = "Package name",
                desc = "Name of the NPM package.",
                icon = "cubes",
                default = "axios",
            ),
            schema.Dropdown(
                id = "download_period",
                name = "Downloads",
                desc = "Download count period.",
                icon = "cloudArrowDown",
                default = DEFAULT_DOWNLOAD_PERIOD,
                options = download_options,
            ),
        ],
    )

def valid_package(name):
    return type(name) == "string" and 0 < len(name) and len(name) <= 214 and all([char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@/_.-" for char in name.codepoints()])

def render_error(code, message):
    """Creates a widget tree to render an error message.

    Args:
        code (int): The error code.
        message (str): The error message.

    Returns:
        render.Root: The root widget tree to be rendered.
    """

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = NPM_LOGO, height = 10),
                        ),
                        render.Text(content = "Error :(", color = "#f00"),
                    ],
                ),
                render.Text(content = "code " + str(code), color = "#ff0"),
                render.Marquee(
                    width = 64,
                    child = render.Text(message),
                ),
            ],
        ),
    )
