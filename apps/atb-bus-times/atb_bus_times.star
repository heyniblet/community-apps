load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

# Entur API endpoint for real-time departures
ENTUR_API_URL = "https://api.entur.io/journey-planner/v3/graphql"
MAX_RESPONSE_BYTES = 256 * 1024
MAX_TEXT_LENGTH = 80

def valid_entur_id(value, prefix):
    if type(value) != "string" or len(value) > 80 or not value.startswith(prefix):
        return False
    return value[len(prefix):].isdigit()

def main(config):
    # Get the stop ID from config, default to Valøyvegen if not set
    stop_id = config.get("stop_id", "NSR:StopPlace:42052")
    quay_id = config.get("quay_id", "NSR:Quay:71981")
    stop_name = config.get("stop_name", "Valøyvegen")
    if not valid_entur_id(stop_id, "NSR:StopPlace:"):
        stop_id = "NSR:StopPlace:42052"
    if not valid_entur_id(quay_id, "NSR:Quay:"):
        quay_id = "NSR:Quay:71981"
    if type(stop_name) != "string":
        stop_name = "Valøyvegen"
    stop_name = stop_name[:MAX_TEXT_LENGTH]

    # Create the header box
    header = render.Box(
        width = 64,
        height = 8,
        color = "#333333",
        child = render.Text(
            content = stop_name[:16],
            font = "5x8",
        ),
    )

    # GraphQL query for departures
    query = """{
      stopPlace(id: "%s") {
        name
        quays {
          id
          publicCode
          estimatedCalls(timeRange: 72000, numberOfDepartures: 3) {
            expectedDepartureTime
            destinationDisplay {
              frontText
            }
            serviceJourney {
              line {
                publicCode
              }
            }
          }
        }
      }
    }""" % stop_id

    # Set up headers
    headers = {
        "ET-Client-Name": "heyniblet-atb-bus-times",
        "Content-Type": "application/json",
    }

    # Make the request to Entur API
    rep = http.post(
        ENTUR_API_URL,
        json_body = {"query": query},
        headers = headers,
    )

    if rep.status_code != 200:
        return render.Root(
            child = render.Column(
                children = [
                    header,
                    render.Text("Error fetching data"),
                ],
            ),
        )

    # Parse the JSON response
    body = rep.body()
    if len(body) > MAX_RESPONSE_BYTES:
        return render.Root(child = render.Column(children = [header, render.Text("Response too large")]))
    response_data = json.decode(body)
    departures = []

    # Extract departure information
    data = response_data.get("data") if type(response_data) == "dict" else None
    stop_place = data.get("stopPlace") if type(data) == "dict" else None
    quays = stop_place.get("quays") if type(stop_place) == "dict" else None
    if type(quays) == "list":
        for quay in quays[:100]:
            calls = quay.get("estimatedCalls") if type(quay) == "dict" and quay.get("id") == quay_id else None
            if type(calls) != "list":
                continue
            for call in calls[:3]:
                journey = call.get("serviceJourney") if type(call) == "dict" else None
                line_data = journey.get("line") if type(journey) == "dict" else None
                line = line_data.get("publicCode") if type(line_data) == "dict" else None
                departure_time = call.get("expectedDepartureTime") if type(call) == "dict" else None
                if type(line) not in ["string", "int"] or type(departure_time) != "string" or len(departure_time) < 16 or len(departure_time) > 40:
                    continue
                departure = time.parse_time(departure_time)
                time_str = "Nå" if abs(departure.unix - time.now().unix) < 60 else departure_time[11:16]
                departures.append(
                    render.Box(
                        width = 64,
                        height = 8,
                        child = render.Row(
                            children = [
                                render.Box(
                                    width = 16,
                                    child = render.Text(content = str(line)[:8], font = "5x8", color = "#C44536"),
                                ),
                                render.Box(
                                    width = 32,
                                    child = render.Text(content = time_str, font = "5x8", color = "#197278"),
                                ),
                            ],
                        ),
                    ),
                )

    if not departures:
        departures.append(render.Text("No departures"))

    return render.Root(
        child = render.Column(
            children = [header] + departures,
        ),
    )
