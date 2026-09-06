"""
Applet: Web 3 Counter
Summary: Expose web3 as a scam
Descrtion: Displays the total dollar value of lost assets due to crypto scams and crashes.
Author: Nick Kuzmik (github.com/kuzmik)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

W3IGG_API = "https://web3isgoinggreat.com/api/griftTotal"

def main():
    total = get_total()

    return render.Root(
        child = render.Box(
            render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText("Money lost to crypto so far", color = "#336699", align = "center"),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 50, height = 8),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            # this will overflow when we hit 1 trillion... so like next week?
                            render.Text("$%s" % total, color = "#FF0000", font = "tom-thumb"),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_total():
    resp = http.get(W3IGG_API, ttl_seconds = 900)
    body = resp.body()
    data = json.decode(body, {}) if resp.status_code == 200 and body and len(body) <= 4096 else {}
    total_lost = data.get("total") if type(data) == "dict" else None
    if type(total_lost) not in ["int", "float"] or total_lost < 0:
        return "unavailable"

    return humanize.comma(float(total_lost))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
