"""
Applet: Hass Entity
Summary: Display Hass entity state
Description: Display an externally accessible Home Assistant entity state or attribute.
Author: InTheDaylight14
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATIC_ENDPOINT = "/api/states/"
DEFAULT_COLOR = "#aaaaaa"

def main(config):
    entity_name = config.get("entity_name", None)
    attribute = config.get("attribute", None)

    if is_string_blank(entity_name):
        states = SAMPLE_DATA
    else:
        states = get_entity_states(config)
        if type(states) != "dict":
            return render.Root(child = render.WrappedText("Home Assistant request failed", width = 64, align = "center"))

    attributes = states.get("attributes")
    attributes = attributes if type(attributes) == "dict" else {}

    friendly_name = config.get("friendly_name", None)
    if is_string_blank(friendly_name):
        friendly_name = str(attributes.get("friendly_name") or entity_name or "Home Assistant")[:100]

    if is_string_blank(attribute):
        state = str(states.get("state") or "Unknown")[:200]
    else:
        state = str(attributes.get(attribute) or "Unknown")[:200]

    if attributes.get("unit_of_measurement"):
        state = state + str(attributes.get("unit_of_measurement"))[:20]

    header_color = config.get("header_color", DEFAULT_COLOR)
    separator_color = config.get("separator_color", DEFAULT_COLOR)
    value_color = config.get("value_color", DEFAULT_COLOR)

    return render.Root(
        delay = 6000,
        child = render.Column(
            children = [
                render.WrappedText(
                    content = friendly_name,
                    color = header_color,
                    linespacing = 0,
                    width = 64,
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = separator_color,
                ),
                render.Marquee(
                    height = 23,  # 32 - 8 (author line) - 1 (divider line)
                    offset_start = 10,
                    offset_end = 10,
                    child = render.WrappedText(
                        content = state,
                        width = 64,
                        color = value_color,
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Public HTTPS URL for your Home Assistant instance.",
                icon = "link",
            ),
            schema.Text(
                id = "nabu_casa_url_key",
                name = "Legacy Nabu Casa URL Key",
                desc = "Retained for saved configuration compatibility; new Cloud installs use the public HTTPS URL above.",
                icon = "link",
                secret = True,
            ),
            schema.Text(
                id = "token",
                name = "Long-Lived Token",
                desc = "Home Assistant Long-Lived Access Token. Profile -> Long-Lived Access Tokens -> Create Token",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "entity_name",
                name = "Entity Name",
                desc = "Entity name ex. 'sensor.front_door'",
                icon = "textHeight",
            ),
            schema.Text(
                id = "attribute",
                name = "Attribute",
                desc = "Optionaly show the value of an attribute for the entity",
                icon = "textHeight",
            ),
            schema.Text(
                id = "friendly_name",
                name = "Name Override",
                desc = "Optionaly override the entity friendly name",
                icon = "textHeight",
            ),
            schema.Color(
                id = "header_color",
                name = "Header Color",
                desc = "Provide a hex code for the header color Ex. #ff00ff",
                icon = "palette",
                default = DEFAULT_COLOR,
                palette = [
                    DEFAULT_COLOR,
                ],
            ),
            schema.Color(
                id = "separator_color",
                name = "Separator Color",
                desc = "Provide a hex code for the separator color Ex. #ff00ff",
                icon = "palette",
                default = DEFAULT_COLOR,
                palette = [
                    DEFAULT_COLOR,
                ],
            ),
            schema.Color(
                id = "value_color",
                name = "Value Color",
                desc = "Provide a hex code for the value color Ex. #ff00ff",
                icon = "palette",
                default = DEFAULT_COLOR,
                palette = [
                    DEFAULT_COLOR,
                ],
            ),
        ],
    )

def is_string_blank(string):
    return string == None or len(string) == 0

# Retrieve entity state from Home Assistant, return json response
def get_entity_states(config):
    ha_url = config.get("ha_url", None)
    token = config.get("token", None)
    entity_name = config.get("entity_name", None)

    if is_string_blank(token) or is_string_blank(entity_name) or len(token) > 4096 or len(entity_name) > 128 or not all([char.isalnum() or char in "._-" for char in entity_name.elems()]):
        return None

    if type(ha_url) == "string" and ha_url.startswith("https://") and len(ha_url) <= 512 and not any([char in ha_url for char in ["?", "#", "@"]]):
        origin = ha_url.rstrip("/")
    else:
        return None

    full_token = "Bearer " + token
    full_url = origin + STATIC_ENDPOINT + entity_name
    headers = {
        "Authorization": full_token,
        "content-type": "application/json",
    }

    res = http.get(
        url = full_url,
        headers = headers,
    )

    if res.status_code != 200:
        return None

    states = res.json()

    return states if type(states) == "dict" else None

SAMPLE_DATA = {
    "entity_id": "switch.front_door",
    "state": "off",
    "attributes": {
        "friendly_name": "Front Door",
    },
    "last_changed": "2020-12-30T04:00:00.000000+00:00",
    "last_updated": "2020-12-30T04:00:00.000000+00:00",
    "context": {
        "id": "ABCDEFG",
    },
}
