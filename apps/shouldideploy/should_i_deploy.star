"""
Applet: Should I Deploy
Summary: Display shouldideploy.today
Description: Display shouldideploy.today answer.
Author: humbertogontijo
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

SHOULD_I_DEPLOY_URL = "https://shouldideploy.today/api"
DEFAULT_TIMEZONE = "UTC"

def main(config):
    tz = config.get("tz", DEFAULT_TIMEZONE)
    if type(tz) != "string" or len(tz) > 64 or not re.match(r"^[A-Za-z0-9_+./-]+$", tz):
        tz = DEFAULT_TIMEZONE
    resp = http.get(SHOULD_I_DEPLOY_URL, params = {"tz": tz}, ttl_seconds = 120)
    body = resp.body()
    data = json.decode(body, {}) if resp.status_code == 200 and body and len(body) <= 16 * 1024 else {}
    msg_txt = data.get("message") if type(data) == "dict" else None
    if type(msg_txt) != "string" or not msg_txt:
        msg_txt = "Answer unavailable"
    msg_txt = msg_txt[:300]

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Should I Deploy Today?",
                            color = "#D2691E",
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 60,
                            child = render.Text(
                                content = msg_txt,
                            ),
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
                id = "tz",
                name = "Timezone",
                desc = "Timezone to send with the request for shouldideploy.today.",
                icon = "businessTime",
                default = DEFAULT_TIMEZONE,
            ),
        ],
    )
