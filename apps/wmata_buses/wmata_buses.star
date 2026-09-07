"""
Applet: WMATA Buses
Summary: Buses in the WMATA system
Description: This app tells you the next buses to arrive at 1-2 bus stops in in Washington, DC.
Author: abrahamrowe
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    api_key = (config.str("api_key") or "").strip()
    defaultN = 1002491
    defaultS = 1002493
    oneStop = False

    northbound = config.str("busStopN", defaultN)
    southbound = config.str("busStopS", defaultS)

    if not api_key:
        return render.Root(child = render.WrappedText("Add a WMATA API key", align = "center"))

    # Trim whitespace to avoid 400 Bad Request
    if type(northbound) == "string":
        northbound = northbound.strip()
    if type(southbound) == "string":
        southbound = southbound.strip()
    if not re.match("^[0-9]{1,12}$", str(northbound)) or not re.match("^[0-9]{1,12}$", str(southbound)):
        return render.Root(child = render.WrappedText("Invalid bus stop", align = "center"))

    if northbound == southbound:
        oneStop = True

    wmata_urlN = str("https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=" + str(northbound))
    wmata_urlS = str("https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=" + str(southbound))

    headers = {"api_key": api_key, "Accept": "application/json"}
    WMATA_data1 = http.get(wmata_urlN, headers = headers, ttl_seconds = 60)  # cache for 1 minute
    WMATA_data2 = http.get(wmata_urlS, headers = headers, ttl_seconds = 60)  # cache for 1 minute

    if WMATA_data1.status_code != 200:
        return render.Root(
            child = render.WrappedText("Error N: {}".format(WMATA_data1.status_code)),
        )
    if WMATA_data2.status_code != 200:
        return render.Root(
            child = render.WrappedText("Error S: {}".format(WMATA_data2.status_code)),
        )

    body1 = WMATA_data1.body()
    body2 = WMATA_data2.body()
    data1 = json.decode(body1, {}) if body1 and len(body1) <= 256 * 1024 else {}
    data2 = json.decode(body2, {}) if body2 and len(body2) <= 256 * 1024 else {}
    predictions1 = data1.get("Predictions", []) if type(data1) == "dict" else []
    predictions2 = data2.get("Predictions", []) if type(data2) == "dict" else []
    if type(predictions1) != "list" or type(predictions2) != "list" or not predictions1 or (not oneStop and not predictions2) or (oneStop and len(predictions1) < 2):
        return render.Root(child = render.WrappedText("No upcoming buses", align = "center"))

    if oneStop == False:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                                height = 14,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                color = "#ffffff",
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 2,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions2[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions2[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions2[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                                height = 14,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                color = "#ffffff",
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 2,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[1]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[1]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[1]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "WMATA API key",
                desc = "Your key from developer.wmata.com.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "busStopN",
                name = "Northbound Bus Stop ID",
                desc = "Go to https://buseta.wmata.com, and click on the stop. But the numbers only after the Bus Stop #. For example: 1002362.",
                icon = "bus",
            ),
            schema.Text(
                id = "busStopS",
                name = "Southbound Bus Stop ID",
                desc = "Same as the northbound instructions for the southbound stop. If you'd like to display the next two buses for a single stop, enter the Northbound stop ID again.",
                icon = "bus",
            ),
        ],
    )
