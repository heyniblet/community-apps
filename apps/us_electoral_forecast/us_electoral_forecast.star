# Modified for the Niblet community fork.
# Original author and license notices are retained below.
# See README.md for maintenance and compatibility notes.

"""
Applet: 2024 US Presidential Results
Summary: Official 2024 result
Description: Shows the certified 2024 US presidential result compiled by the FEC and National Archives.
Author: jwoglom
"""

load("render.star", "render")
load("schema.star", "schema")

RESULTS = {
    "ec": ("312 EV", "226 EV"),
    "pv": ("49.8%", "48.3%"),
    "winprob": ("WINNER", "RUNNER-UP"),
}

def main(config):
    trump, harris = RESULTS.get(config.str("type", "ec"), RESULTS["ec"])
    return render.Root(
        child = render.Column(
            children = [
                render.Text("2024 FINAL", font = "tom-thumb", color = "#aaaaaa"),
                result_row("TRUMP", trump, "#eb4034"),
                result_row("HARRIS", harris, "#4b6de3"),
            ],
            expanded = True,
            main_align = "space_evenly",
        ),
    )

def result_row(name, value, color):
    return render.Row(
        children = [
            render.Text(name, font = "tom-thumb", color = color),
            render.Text(value, font = "tom-thumb", color = color),
        ],
        expanded = True,
        main_align = "space_between",
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "Result",
                desc = "Choose the certified result to display.",
                icon = "checkToSlot",
                default = "ec",
                options = [
                    schema.Option(display = "Electoral College", value = "ec"),
                    schema.Option(display = "Popular Vote", value = "pv"),
                    schema.Option(display = "Winner", value = "winprob"),
                ],
            ),
        ],
    )
