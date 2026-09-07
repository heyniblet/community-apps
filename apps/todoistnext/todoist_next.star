"""
Applet: Todoist Next
Summary: Todoist next due/overdue
Description: Displays the next due or overdue task from todoist.
Author: alisdair(https://discuss.tidbyt.com/t/todoist-integration/502/5), Updated by: akeslo and oleksii-ivanov
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/zen_icon.png", ZEN_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ZEN_ICON = ZEN_ICON_ASSET.readall()

TODOIST_API_TASKS_URL = "https://api.todoist.com/api/v1/tasks/filter"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_TOKEN_BYTES = 4096

MODEL_KEY_TEXT = "text"
MODEL_KEY_DUE = "due"
MODEL_KEY_ZEN = False

def render_date(date_string):
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    month = int(date_string[5:7])
    return "%s-%s" % (months[month - 1], date_string[8:10])

def valid_date(date_string):
    return type(date_string) == "string" and len(date_string) == 10 and date_string[4] == "-" and date_string[7] == "-" and date_string[0:4].isdigit() and date_string[5:7].isdigit() and date_string[8:10].isdigit() and int(date_string[5:7]) >= 1 and int(date_string[5:7]) <= 12 and int(date_string[8:10]) >= 1 and int(date_string[8:10]) <= 31

def main(config):
    # Download tasks

    token = config.get("TodoistAPIToken", "")
    token = token.strip() if type(token) == "string" else ""
    if not token or len(token) > MAX_TOKEN_BYTES or "\r" in token or "\n" in token:
        return render.Root(child = render.WrappedText(content = "Add your Todoist API token"))

    resp = http.get(TODOIST_API_TASKS_URL, headers = {"Authorization": "Bearer " + token}, params = {"query": "overdue | today"})
    body = resp.body()

    if resp.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES:
        data = json.decode(body, {})
        parsed = data.get("results", []) if type(data) == "dict" else []
        if type(parsed) != "list":
            parsed = []

        # Compute model to display
        model = None
        for task in parsed[:100]:
            if type(task) != "dict" or type(task.get("due")) != "dict":
                continue
            due = task["due"].get("date")
            content = task.get("content")
            if not valid_date(due) or type(content) != "string" or not content:
                continue
            thisModel = {MODEL_KEY_TEXT: content[:500]}
            if due < time.now().format("2006-01-02"):
                thisModel.update([(MODEL_KEY_DUE, due)])
            if model == None:
                model = thisModel
                continue
            if model.get(MODEL_KEY_DUE) == None:
                if thisModel.get(MODEL_KEY_DUE) != None:
                    model = thisModel
                    continue
            elif due < model[MODEL_KEY_DUE]:
                model = thisModel
                continue
        if model == None:
            model = {
                MODEL_KEY_TEXT: "Todoist Zero!",
                MODEL_KEY_ZEN: True,
            }

        # Render model
        HEADER = "#f00"
        CLR = "#fa0"
        if model.get(MODEL_KEY_ZEN) == True:
            CLR = "#fff"

        children = [
            render.WrappedText(
                content = model[MODEL_KEY_TEXT],
                color = CLR,
            ),
        ]

        if model.get(MODEL_KEY_DUE) != None:
            children.append(
                render.Text(
                    content = "Late: " + render_date(model.get(MODEL_KEY_DUE)),
                    color = "#f00",
                    font = "CG-pixel-4x5-mono",
                ),
            )

        if model.get(MODEL_KEY_ZEN) == True:
            children.append(
                render.Image(src = ZEN_ICON),
            )
        else:
            children.insert(
                0,
                render.WrappedText(
                    content = "Todoist",
                    color = HEADER,
                ),
            )
    else:
        children = [
            render.WrappedText(
                content = "Config Error",
            ),
        ]

    return render.Root(
        render.Row(
            children = [render.Column(
                children = children,
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
            )],
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
        ),
        max_age = 600,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "TodoistAPIToken",
                name = "Todoist API Token",
                desc = "Enter Token",
                icon = "key",
                secret = True,
            ),
        ],
    )
