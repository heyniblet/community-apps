"""
Applet: Todoist Tasks
Summary: Integrates with Todoist
Description: Shows up to 3 tasks on your To-Do list, sorted by priority. Use the filter option to further sort your tasks by using parameters such as 'today', tomorrow', 'overdue' etc.
Author: Based on zephyern's code, rewritten by ChatGTP4 with directions from Noste. I have no idea how code works.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_FILTER = "today | overdue"
DEFAULT_SHOW_IF_EMPTY = True

NO_TASKS_CONTENT = "No Tasks :)"

TODOIST_URL = "https://api.todoist.com/api/v1/tasks/filter"
MAX_RESPONSE_BYTES = 512 * 1024
MAX_TOKEN_BYTES = 4096

def main(config):
    token = config.get("auth") or config.get("dev_api_key")
    token = token.strip() if type(token) == "string" else ""

    if not token or len(token) > MAX_TOKEN_BYTES or "\r" in token or "\n" in token:
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Circle(
                        diameter = 6,
                        color = "#9b9b9b",
                        child = render.Circle(color = "#3cba54", diameter = 2),
                    ),
                    render.Box(
                        width = 46,
                        child = render.Marquee(
                            child = render.Text(content = "Please connect your Todoist account."),
                            width = 46,
                        ),
                    ),
                ],
            ),
        )

    filter = config.get("filter") or DEFAULT_FILTER
    filter = filter[:500] if type(filter) == "string" else DEFAULT_FILTER
    rep = http.get(TODOIST_URL, headers = {"Authorization": "Bearer %s" % token}, params = {"query": filter})
    body = rep.body()

    sorted_tasks = None
    if rep.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES:
        payload = json.decode(body, {})
        tasks = payload.get("results", []) if type(payload) == "dict" else []
        if type(tasks) == "list":
            valid_tasks = []
            for task in tasks[:200]:
                if type(task) != "dict" or type(task.get("content")) != "string":
                    continue
                priority = task.get("priority", 1)
                if type(priority) != "int" or priority < 1 or priority > 4:
                    priority = 1
                valid_tasks.append({"content": task["content"][:500], "priority": priority})
            sorted_tasks = sorted(valid_tasks, key = lambda task: task["priority"], reverse = True)

    if sorted_tasks == None:
        return render.Root(child = render.WrappedText("Error fetching tasks"))

    if not sorted_tasks:
        if not config.bool("show", DEFAULT_SHOW_IF_EMPTY):
            return []

        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Circle(
                        diameter = 6,
                        color = "#3cba54",  # Green color
                        child = render.Circle(color = "#332726", diameter = 2),
                    ),
                    render.Box(
                        width = 46,
                        child = render.Text(content = NO_TASKS_CONTENT),
                    ),
                ],
            ),
        )

    # We have tasks
    task_descriptions = [task["content"] for task in sorted_tasks[:3]]
    task_priority = [task["priority"] for task in sorted_tasks[:3]]

    content = []
    for desc in task_descriptions:
        if type(desc) == "list":  # Starlark type check
            desc = " ".join(desc)
        content.append(desc)

    colors = ["#9b9b9b", "#48a9e6", "#f8b43a", "#ed786c"]

    children = []
    for i, task_desc in enumerate(content):
        children.append(render.Marquee(
            child = render.Text(content = task_desc),
            offset_start = 2,
            width = 46,
        ))

    # Update circle colors based on the priority of the tasks
    circle_colors = [colors[int(priority) - 1] for priority in task_priority]

    # Generate circle children based on the number of tasks
    circle_children = []
    for i in range(len(content)):
        circle_children.append(render.Circle(
            diameter = 6,
            color = circle_colors[i],
            child = render.Circle(color = "#332726", diameter = 2),
        ))

    return render.Root(
        delay = 100,
        max_age = 600,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = circle_children,
                    ),
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = children,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "auth",
                name = "Todoist API Token",
                desc = "Personal token from Todoist Settings > Integrations > Developer.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "filter",
                name = "Filter",
                desc = "Filter to apply to tasks.",
                icon = "filter",
                default = DEFAULT_FILTER,
            ),
            schema.Toggle(
                id = "show",
                name = "Show When No Tasks",
                desc = "Show this app when there are no tasks.",
                icon = "eye",
                default = DEFAULT_SHOW_IF_EMPTY,
            ),
        ],
    )
