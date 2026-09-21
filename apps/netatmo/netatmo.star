# Niblet downstream modifications; maintained by @edwin-page.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: Netatmo
Summary: Weather from your Netatmo
Description: Get your current weather from your Netatmo weather station.
Author: danmcclain
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/down_deg.png", DOWN_DEG_ASSET = "file")
load("images/down_press.png", DOWN_PRESS_ASSET = "file")
load("images/up_deg.png", UP_DEG_ASSET = "file")
load("images/up_press.png", UP_PRESS_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DOWN_DEG = DOWN_DEG_ASSET.readall()
DOWN_PRESS = DOWN_PRESS_ASSET.readall()
UP_DEG = UP_DEG_ASSET.readall()
UP_PRESS = UP_PRESS_ASSET.readall()

def main(config):
    fahrenheit = config.bool("fahrenheit")
    url = config.str("endpoint_url")
    token = config.str("relay_token")
    if valid_url(url) and token:
        response = http.get(url, headers = {"Authorization": "Bearer " + token})
        if response.status_code != 200 or len(response.body()) > 512 * 1024:
            return problem("Relay unavailable")
        body = json.decode(response.body(), {})
    else:
        body = json.decode(EXAMPLE_DATA)
    devices = ((body.get("body") or {}).get("devices") or []) if type(body) == "dict" else []
    if not devices or not valid_module(devices[0], True):
        return problem("Invalid station data")
    indoor_module = devices[0]
    outdoor_module = select_outdoor_module(indoor_module.get("modules") or [])

    rows = [render.Box(height = 3)]
    rows.append(temp_and_humid_row(indoor_module, "In  ", fahrenheit))
    if outdoor_module != None:
        rows.append(temp_and_humid_row(outdoor_module, "Out ", fahrenheit))

    rows.append(render.Box(height = 3))
    pressure = indoor_module["dashboard_data"]["Pressure"]
    press_trend = render.Text("", font = "tom-thumb")
    if "pressure_trend" in indoor_module["dashboard_data"]:
        pressure_trend = indoor_module["dashboard_data"]["pressure_trend"]
        if pressure_trend == "up":
            press_trend = render.Image(src = UP_PRESS)
        if pressure_trend == "down":
            press_trend = render.Image(src = DOWN_PRESS)

    rows.append(render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text("%d.1mbar" % (pressure), font = "tom-thumb", color = "#930"),
                press_trend,
            ],
        ),
    ))

    co2 = indoor_module["dashboard_data"]["CO2"]
    noise = indoor_module["dashboard_data"]["Noise"]
    rows.append(render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text("%dppm  " % (co2), font = "tom-thumb", color = "#ffc107"),
                render.Text("%ddB" % (noise), font = "tom-thumb"),
            ],
        ),
    ))
    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

def valid_url(value):
    return type(value) == "string" and value.startswith("https://") and len(value) <= 4096 and not any([char in value for char in [" ", "\r", "\n", "\t"]])

def valid_module(module, indoor = False):
    if type(module) != "dict" or type(module.get("dashboard_data")) != "dict":
        return False
    dash = module["dashboard_data"]
    required = ["Temperature", "Humidity"] + (["Pressure", "CO2", "Noise"] if indoor else [])
    return all([type(dash.get(key)) in ["int", "float"] for key in required])

def problem(content):
    return render.Root(child = render.WrappedText(content, font = "tom-thumb", width = 62, align = "center", color = "#ffea00"))

def select_outdoor_module(modules):
    for m in modules[:32]:
        if valid_module(m) and m.get("data_type") == ["Temperature", "Humidity"] and m.get("type") == "NAModule1":
            return m
    return None

def temp_and_humid_row(module, name, fahrenheit):
    dash = module["dashboard_data"]
    temp = dash["Temperature"]

    if fahrenheit:
        temp = temp * 1.8 + 32

    humid = dash["Humidity"]

    temp_trend = render.Text("  ", font = "tom-thumb")

    if "temp_trend" in dash:
        trend = dash["temp_trend"]
        if trend == "up":
            temp_trend = render.Image(src = UP_DEG)
        if trend == "down":
            temp_trend = render.Image(src = DOWN_DEG)

    return render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text(name, font = "tom-thumb"),
                render.Text("%d°" % (temp), font = "tom-thumb", color = "#093"),
                temp_trend,
                render.Text("%d%%" % humid, font = "tom-thumb", color = "#039"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "endpoint_url",
                icon = "link",
                name = "Netatmo relay URL",
                desc = "A user-owned HTTPS endpoint returning the Netatmo getstationsdata JSON response.",
            ),
            schema.Text(
                id = "relay_token",
                icon = "key",
                name = "Relay token",
                desc = "The bearer token required by your relay.",
                secret = True,
            ),
            schema.Toggle(
                id = "fahrenheit",
                icon = "temperatureHigh",
                name = "Fahrenheit",
                desc = "Display temperatures in fahrenheit",
            ),
        ],
    )

EXAMPLE_DATA = """{
  "body": {
    "devices": [
      {
        "_id": "70:ee:50:22:aa:00",
        "date_setup": 1435834348,
        "last_setup": 1435834348,
        "type": "NAMain",
        "last_status_store": 1555677748,
        "module_name": "Indoor",
        "firmware": 137,
        "last_upgrade": 1512405614,
        "wifi_status": 55,
        "reachable": true,
        "co2_calibrating": false,
        "station_name": "Casa",
        "data_type": [
          "string"
        ],
        "place": {
          "timezone": "Africa/Lagos",
          "country": "EG",
          "altitude": 144,
          "location": [
            "30.89600807058707, 29.94281464724796"
          ]
        },
        "read_only": true,
        "home_id": "594xxxxxxxxxdb",
        "home_name": "Home",
        "dashboard_data": {
          "time_utc": 1555677739,
          "Temperature": 23.7,
          "CO2": 967,
          "Humidity": 41,
          "Noise": 42,
          "Pressure": 997.6,
          "AbsolutePressure": 1017.4,
          "min_temp": 21.2,
          "max_temp": 27.4,
          "date_min_temp": 1555631374,
          "date_max_temp": 1555662436,
          "temp_trend": "up",
          "pressure_trend": "up"
        },
        "modules": [
          {
            "oneOf": [
              {
                "_id": "06:00:00:02:47:00",
                "type": "NAModule4",
                "module_name": "Indoor Module",
                "data_type": [
                  "Temperature, Humidity, CO2"
                ],
                "last_setup": 1435834348,
                "reachable": true,
                "dashboard_data": {
                  "time_utc": 1555677739,
                  "Temperature": 23.7,
                  "CO2": 967,
                  "Humidity": 41,
                  "Pressure": 997.6,
                  "AbsolutePressure": 1017.4,
                  "min_temp": 21.2,
                  "max_temp": 27.4,
                  "date_min_temp": 1555631374,
                  "date_max_temp": 1555662436,
                  "temp_trend": "up"
                },
                "firmware": 19,
                "last_message": 1555677746,
                "last_seen": 1555677746,
                "rf_status": 31,
                "battery_vp": 5148,
                "battery_percent": 58
              }
            ]
          }
        ]
      }
    ],
    "user": {
      "mail": "name@mail.com",
      "administrative": {
        "reg_locale": "fr-FR",
        "lang": "fr-FR",
        "country": "FR",
        "unit": 0,
        "windunit": 0,
        "pressureunit": 0,
        "feel_like_algo": 0
      }
    }
  },
  "status": "ok",
  "time_exec": "0.060059070587158",
  "time_server": "1553777827"
}"""
