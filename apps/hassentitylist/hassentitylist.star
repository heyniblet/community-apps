"""
Applet: HASS Entity List
Summary: Displays multiple HomeAssistant entities
Description: Displays multiple HomeAssistant entities (e.g. step counts)
Author: James Woglom
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    children = add_children(config, "entity_1", "entity_2", "entity_3", "entity_4")

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def add_children(config, *childs):
    items = {}
    counts = []
    for child in childs:
        n, entity = render_entity(child, config)
        if entity:
            items[child] = entity
            counts.append([n, child])
        else:
            items[child] = None

    children = []
    if config.bool("sort_entities"):
        for i in sorted(counts)[::-1]:
            children.append(items[i[1]])
    else:
        for child in childs:
            if items[child]:
                children.append(items[child])

    return children

def render_entity(entity_id, config):
    name = config.get(entity_id + "_name")
    fetch = fetch_entity(entity_id, config)
    if not fetch:
        return 0, None
    if not name:
        name = fetch.get("attributes", {}).get("friendly_name") or config.get(entity_id)
    name = str(name)[:32]

    state = fetch["state"]
    parsed = parse_number(state)
    isnum = parsed != None
    count = parsed if isnum else 0
    display = humanize.comma(math.round(count * 10) / 10) if isnum else state

    unit = ""
    if config.bool("show_units") and "attributes" in fetch and "unit_of_measurement" in fetch["attributes"]:
        unit = str(fetch["attributes"]["unit_of_measurement"])[:12] + " "

    return count, render.Row(
        main_align = "space_between",
        expanded = True,
        children = [
            render.Text(
                content = " " + name,
                font = "tb-8",
                color = "#f1f1f1",
            ),
            render.Text(
                content = "{} {}".format(display, unit),
                font = "tb-8",
                color = get_color(count, config) if isnum else "#fff",
            ),
        ],
    )

def get_color(count, config):
    max_target = parse_number(config.get("target_value"))
    if max_target == None or max_target <= 0:
        return "#fff"

    range = ["#AD1A1A", "#ad3a1a", "#ad721a", "#ada11a", "#92ad1a", "#37ad1a"]
    if count >= max_target:
        return range[-1]

    i = int(((len(range) - 1) * count) / max_target)
    return range[i]

def parse_number(value):
    if value == None:
        return None
    value = str(value).strip()
    unsigned = value[1:] if value.startswith("-") else value
    parts = unsigned.split(".")
    if not unsigned or len(parts) not in [1, 2] or not all([part.isdigit() for part in parts]):
        return None
    return float(value)

def fetch_entity(entity_id, config):
    entity = config.get(entity_id)
    base_url = config.get("ha_url") or ""
    token = config.get("ha_token") or ""
    if entity and token and base_url.startswith("https://"):
        parts = entity.split(".")
        if len(parts) != 2 or not all([part.replace("_", "").replace("-", "").isalnum() for part in parts]):
            return None
        rep = http.get(base_url.rstrip("/") + "/api/states/" + entity, headers = {
            "Authorization": "Bearer " + token,
        })
        if rep.status_code != 200:
            return None
        data = rep.json()
        if type(data) != "dict" or data.get("state") == None:
            return None
        attributes = data.get("attributes") if type(data.get("attributes")) == "dict" else {}
        return {"state": str(data["state"])[:64], "attributes": attributes}
    return None

def get_schema():
    entity_schema = []
    for i in ["1", "2", "3", "4"]:
        entity_schema += [
            schema.Text(
                id = "entity_" + i,
                name = "Entity ID " + i,
                desc = "Entity ID " + i + " (e.g. sensor.steps)",
                icon = "1",
            ),
            schema.Text(
                id = "entity_" + i + "_name",
                name = "Entity Name " + i,
                desc = "Entity Name " + i + " (e.g. My Steps)",
                icon = "1",
            ),
        ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "HomeAssistant URL",
                desc = "Public HTTPS URL of the Home Assistant instance (port 443).",
                icon = "book",
            ),
            schema.Text(
                id = "ha_token",
                name = "HomeAssistant Token",
                desc = "HomeAssistant Token. Find in User Settings > Long-lived access tokens.",
                icon = "book",
                secret = True,
            ),
            schema.Toggle(
                id = "sort_entities",
                name = "Sort entities",
                desc = "Sort entities by value (biggest value first). If not set, then entities will be shown in the order specified.",
                icon = "compress",
                default = False,
            ),
            schema.Text(
                id = "target_value",
                name = "Target value",
                desc = "Target value number. If set, then a red-to-green range will be used for values, with this number at the top of the range.",
                icon = "compress",
                default = "",
            ),
            schema.Toggle(
                id = "show_units",
                name = "Show units",
                desc = "Show units for entities which have them.",
                icon = "eye",
                default = True,
            ),
        ] + entity_schema,
    )
