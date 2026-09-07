"""
Applet: Octopus Agile
Summary: Octopus Energy Agile Rates
Description: Gets the latest Agile Rates for Octopus Energy and shows the current price.
Author: sandeepb1
"""

load("http.star", "http")
load("images/img.png", IMG_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

IMG = IMG_ASSET.readall()

DEFAULT_PROD_CODE = "AGILE-24-04-03"
DEFAULT_TARIFF_CODE = "E-1R-AGILE-24-04-03-A"

def main(config):
    now = time.now().in_location("Etc/UTC")
    nowISO = now.format("2006-01-02T15:04:05Z")
    #2024-04-15T13:19:00Z

    product_code = config.str("PROD_CODE", DEFAULT_PROD_CODE)
    tariff_code = config.str("TARIFF_CODE", DEFAULT_TARIFF_CODE)
    if not valid_code(product_code) or not valid_code(tariff_code):
        product_code = DEFAULT_PROD_CODE
        tariff_code = DEFAULT_TARIFF_CODE
    OCTOPUS_AGILE_URL = "https://api.octopus.energy/v1/products/" + product_code + "/electricity-tariffs/" + tariff_code + "/standard-unit-rates/?period_from=" + nowISO

    octo = http.get(OCTOPUS_AGILE_URL, ttl_seconds = 1800)

    if octo.status_code != 200:
        fail("Octopus Energy request failed with status %d" % octo.status_code)

    body = octo.body()
    if not body or len(body) > 1048576:
        fail("Octopus Energy returned an invalid response")
    data = octo.json()
    results = data.get("results", []) if type(data) == "dict" else []
    if type(results) != "list" or not results or type(results[-1]) != "dict" or type(results[-1].get("value_inc_vat")) not in ["int", "float"]:
        fail("Octopus Energy returned no current rate")
    nextRate = results[-1]["value_inc_vat"]

    plunge = threshold(config.str("PLUNGE_NUMBER", "1"), 1)
    good = threshold(config.str("GOOD_NUMBER", "4"), 4)
    bad = threshold(config.str("BAD_NUMBER", "17"), 17)

    color = "#FFF"

    if nextRate < plunge:
        color = config.str("PLUNGE_COLOUR", "#A3BE8C")
    elif nextRate < good:
        color = config.str("GOOD_COLOUR", "#81A1C1")
    elif nextRate > bad:
        color = config.str("BAD_COLOUR", "#BF616A")

    return render.Root(
        delay = 60000,
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = IMG,
                        width = 16,
                        height = 16,
                    ),
                    render.Text(
                        content = str((math.round(nextRate * 100) / 100)) + "p",
                        font = "tb-8",
                        color = color,
                    ),
                ],
            ),
        ),
    )

def valid_code(value):
    return value and len(value) <= 80 and all([char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for char in value.codepoints()])

def threshold(value, fallback):
    value = value.strip()
    unsigned = value[1:] if value.startswith("-") else value
    return int(value) if unsigned and len(value) <= 8 and unsigned.isdigit() else fallback

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "PROD_CODE",
                name = "Product Code",
                desc = "The code of the product to be retrieved, for example VAR-17-01-11.",
                icon = "user",
                default = "AGILE-24-04-03",
            ),
            schema.Text(
                id = "TARIFF_CODE",
                name = "Tariff Code",
                desc = "The code of the tariff to be retrieved, for example E-1R-VAR-17-01-11-A.",
                icon = "user",
                default = "E-1R-AGILE-24-04-03-A",
            ),
            schema.Text(
                id = "PLUNGE_NUMBER",
                name = "Plunge Threshold",
                desc = "The rate to determine extremely low rates. Check to see if the rate is below the defined number.",
                icon = "0",
                default = "1",
            ),
            schema.Text(
                id = "GOOD_NUMBER",
                name = "Good Rate Threshold",
                desc = "The rate to determine rates at a good level. Check to see if the rate is below the defined number.",
                icon = "0",
                default = "4",
            ),
            schema.Text(
                id = "BAD_NUMBER",
                name = "Bad Rate Threshold",
                desc = "The rate to determine rates that are at a high level. Check to see if the rate is above the defined number.",
                icon = "0",
                default = "17",
            ),
            schema.Color(
                id = "PLUNGE_COLOUR",
                name = "Plunge Colour",
                desc = "The colour used when plunge pricing or extremely low rates are in effect",
                icon = "brush",
                default = "#A3BE8C",
            ),
            schema.Color(
                id = "GOOD_COLOUR",
                name = "Good Rate Colour",
                desc = "The colour used when rates are at a good level",
                icon = "brush",
                default = "#81A1C1",
            ),
            schema.Color(
                id = "BAD_COLOUR",
                name = "Bad Rate Colour",
                desc = "The colour used when rates are at a high level",
                icon = "brush",
                default = "#BF616A",
            ),
        ],
    )
