"""
Applet: Ethstaker
Summary: Ethereum validator status
Description: Shows the recent status of provided validators on the Ethereum beacon chain.
Author: ColinCampbell
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/checkmark.png", CHECKMARK_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

CHECKMARK = CHECKMARK_ASSET.readall()

API_VALIDATOR_LIMIT = 10
MAX_VALIDATORS = 50
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_ATTESTATIONS = 5000
FULL_ROW_LIMIT = 30
FULL_COLUMN_LIMIT = 11

def main(config):
    statuses = validator_statuses(config)

    if statuses != None:
        status_rows = chunk_list(statuses, FULL_ROW_LIMIT)

        return render.Root(
            child = render.Padding(
                child = render.Column(
                    children = [
                        render.Padding(
                            child = render.Row(
                                expanded = True,
                                main_align = "space_between",
                                children = [
                                    render.Text("ethstaker", font = "CG-pixel-4x5-mono"),
                                    header_status(statuses),
                                ],
                            ),
                            pad = (0, 0, 0, 1),
                        ),
                        render.Column(
                            children = map(
                                status_rows,
                                lambda status_row: render.Row(
                                    children = map(status_row, lambda status: status_circle(status)),
                                ),
                            ),
                        ),
                    ],
                ),
                pad = 2,
            ),
        )
    else:
        return render.Root(
            child = render.Padding(
                child = render.Column(
                    children = [
                        render.Padding(
                            child = render.Text("ethstaker", font = "CG-pixel-4x5-mono"),
                            pad = (0, 0, 0, 1),
                        ),
                        render.WrappedText("Missing settings"),
                    ],
                ),
                pad = 2,
            ),
        )

def header_status(statuses):
    status_counts = count_list_by(statuses, lambda statuses: statuses)
    sorted_status_keys = sorted(status_counts.keys(), reverse = True, key = status_score)
    status = sorted_status_keys[0]

    if status == "missed_attestation":
        return render.Text(
            str(status_counts.get("missed_attestation")),
            font = "CG-pixel-4x5-mono",
            color = "#f00",
        )
    elif status == "attested" or status == "unknown":
        return render.Image(src = CHECKMARK)
    else:
        return render.Text("?", font = "CG-pixel-4x5-mono")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Beaconcha.in API Key",
                desc = "The API key from your Beaconcha.in account used to load your validator data",
                icon = "server",
                secret = True,
            ),
            schema.Text(
                id = "validators",
                name = "Validators",
                desc = "The indices of the validators you'd like status updates for",
                icon = "checkToSlot",
            ),
        ],
    )

def validator_statuses(config):
    api_key = str(config.str("api_key") or "").strip()
    raw_validator_indices = str(config.str("validators") or "")
    if not api_key or len(api_key) > 4096 or "\r" in api_key or "\n" in api_key:
        return None
    validator_indices = []
    for value in raw_validator_indices.split(",")[:MAX_VALIDATORS]:
        value = value.strip()
        if value and len(value) <= 20 and value.isdigit() and value not in validator_indices:
            validator_indices.append(value)
    if not validator_indices:
        return None
    slot_statuses = combined_validator_statuses(api_key, validator_indices)
    if slot_statuses == None:
        return None
    status_limit = FULL_ROW_LIMIT * FULL_COLUMN_LIMIT
    slot_statuses = slot_statuses[-status_limit:]
    empty_status_length = status_limit - len(slot_statuses)
    return ["empty" for _ in range(empty_status_length)] + [slot_status[1] for slot_status in slot_statuses]

def combined_validator_statuses(api_key, validator_indices):
    validator_chunks = chunk_list(validator_indices, API_VALIDATOR_LIMIT)
    slot_statuses = []
    for chunk in validator_chunks:
        loaded = load_validator_slot_statuses(api_key, chunk)
        if loaded == None:
            return None
        slot_statuses.extend(loaded)
    merged = {}
    for slot, status in slot_statuses:
        merged[slot] = choose_status(status, merged.get(slot))
    return sorted(merged.items(), key = lambda item: item[0])

def load_validator_slot_statuses(api_key, validator_indices):
    indices_part = ",".join(validator_indices)
    url = "https://beaconcha.in/api/v1/validator/{}/attestations".format(indices_part)
    payload = api_response(url, api_key)
    data = payload.get("data") if type(payload) == "dict" and payload.get("status") == "OK" else None
    if type(data) != "list":
        return None

    slot_attestations = []
    most_recent_slot_attestations_by_validator_index = {}

    for attestion_data in data[:MAX_ATTESTATIONS]:
        if type(attestion_data) != "dict":
            continue
        validator_index = safe_integer(attestion_data.get("validatorindex"))
        attestation_slot = safe_integer(attestion_data.get("attesterslot"))
        raw_status = safe_integer(attestion_data.get("status"))
        if validator_index == None or attestation_slot == None or raw_status not in [0, 1]:
            continue
        validator_index = str(validator_index)

        most_recent_slot_attestation = most_recent_slot_attestations_by_validator_index.get(validator_index)
        if most_recent_slot_attestation == None or most_recent_slot_attestation["attestation_slot"] < attestation_slot:
            most_recent_slot_attestations_by_validator_index[validator_index] = {
                "attestation_slot": attestation_slot,
                "raw_status": raw_status,
            }

        slot_attestations.append({
            "validator_index": validator_index,
            "attestation_slot": attestation_slot,
            "raw_status": raw_status,
        })

    return map(
        slot_attestations,
        lambda slot_attestation: (
            slot_attestation["attestation_slot"],
            attestion_status(slot_attestation, most_recent_slot_attestations_by_validator_index.get(slot_attestation["validator_index"])),
        ),
    )

def attestion_status(slot_attestation, most_recent_slot_attestation):
    raw_status = slot_attestation["raw_status"]

    if raw_status == 1:
        return "attested"
    elif raw_status == 0 and most_recent_slot_attestation != None and slot_attestation["attestation_slot"] == most_recent_slot_attestation["attestation_slot"]:
        return "unknown"
    else:
        return "missed_attestation"

def choose_status(status, existing_status):
    if existing_status != None and status_score(status) < status_score(existing_status):
        return existing_status
    else:
        return status

def status_score(status):
    if status == "empty":
        return 0
    elif status == "attested":
        return 1
    elif status == "unknown":
        return 2
    else:
        return 3

def api_response(url, api_key):
    response = http.get(url, headers = {
        "accept": "application/json",
        "apikey": api_key,
    })
    body = response.body()
    return json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None

def safe_integer(value):
    if type(value) in ["int", "float"]:
        return int(value) if value >= 0 else None
    value = str(value or "")
    return int(value) if value and len(value) <= 20 and value.isdigit() else None

def status_circle(status):
    return render.Padding(
        child = render.Box(
            color = status_color(status),
            width = 1,
            height = 1,
        ),
        pad = (0, 1, 1, 0),
    )

def status_color(status):
    if status == "attested":
        return "#0f0"
    elif status == "unknown":
        return "#bbb"
    elif status == "empty":
        return "#555"
    else:
        return "#f00"

# Generic Utils

def chunk_list(items, max_items_per_chunk):
    return [items[i:i + max_items_per_chunk] for i in range(0, len(items), max_items_per_chunk)]

def count_list_by(l, f):
    result = {}
    for item in l:
        key = f(item)
        if result.get(key) == None:
            result[key] = 0
        result[key] += 1
    return result

def map(l, f):
    return [f(i) for i in l]
