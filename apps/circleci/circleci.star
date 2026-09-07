"""
Applet: CircleCI
Summary: CircleCI Build Statuses
Description: Status of latest execution of pipeline in CircleCI.
Author: barbosa
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/circleci_logo_green.png", CIRCLECI_LOGO_GREEN_ASSET = "file")
load("images/circleci_logo_red.png", CIRCLECI_LOGO_RED_ASSET = "file")
load("images/circleci_logo_white.png", CIRCLECI_LOGO_WHITE_ASSET = "file")
load("images/circleci_logo_yellow.png", CIRCLECI_LOGO_YELLOW_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

CIRCLECI_LOGO_GREEN = CIRCLECI_LOGO_GREEN_ASSET.readall()
CIRCLECI_LOGO_RED = CIRCLECI_LOGO_RED_ASSET.readall()
CIRCLECI_LOGO_WHITE = CIRCLECI_LOGO_WHITE_ASSET.readall()
CIRCLECI_LOGO_YELLOW = CIRCLECI_LOGO_YELLOW_ASSET.readall()

CIRCLECI_PIPELINES_API_URL = "https://circleci.com/api/v2/project/{}/pipeline"
CIRCLECI_WORKFLOWS_API_URL = "https://circleci.com/api/v2/pipeline/{}/workflow"
MAX_RESPONSE_BYTES = 1024 * 1024

def safe_segment(value):
    value = str(value or "")
    if not value or len(value) > 120:
        return ""
    for char in value.elems():
        if char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.":
            return ""
    return value

def request_json(url, token, params = {}):
    response = http.get(url, params = params, headers = {
        "Accept": "application/json",
        "Circle-Token": token,
    })
    body = response.body()
    data = json.decode(body, None) if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES else None
    return data if type(data) == "dict" else None

def main(config):
    api_token = str(config.get("api_token") or "")[:512]
    if not api_token:
        return render_fail("Please inform API token")

    vcs = config.str("vcs", "gh")
    if vcs not in ["gh", "bb"]:
        return render_fail("Please inform vcs type")

    org = safe_segment(config.get("org"))
    if not org:
        return render_fail("Please inform org name")

    repo = safe_segment(config.get("repo"))
    if not repo:
        return render_fail("Please inform repo name")

    latest_pipeline = fetch_latest_pipeline(api_token, vcs, org, repo, str(config.get("branch") or "")[:256])
    if latest_pipeline == None:
        return render_fail("Can't fetch pipeline")

    latest_workflow = fetch_latest_workflow(api_token, pipeline_id = safe_segment(latest_pipeline.get("id")))
    if latest_workflow == None:
        return render_fail("Can't fetch workflow")

    return render_widget(repo, latest_pipeline, latest_workflow)

def fetch_latest_pipeline(api_token, vcs, org, repo, branch):
    project_slug = "{}/{}/{}".format(vcs, org, repo)
    params = {}
    if branch:
        params["branch"] = branch

    pipelines = request_json(CIRCLECI_PIPELINES_API_URL.format(project_slug), api_token, params)
    if pipelines == None:
        return None
    items = pipelines.get("items")
    if type(items) != "list" or not items or type(items[0]) != "dict":
        return None

    return items[0]

def fetch_latest_workflow(api_token, pipeline_id):
    if not pipeline_id:
        return None
    workflows = request_json(CIRCLECI_WORKFLOWS_API_URL.format(pipeline_id), api_token)
    items = workflows.get("items") if workflows else None
    return items[0] if type(items) == "list" and items and type(items[0]) == "dict" else None

def logo_for_status(status):
    mapping = {
        "success": CIRCLECI_LOGO_GREEN,
        "running": CIRCLECI_LOGO_YELLOW,
        "failed": CIRCLECI_LOGO_RED,
        "error": CIRCLECI_LOGO_RED,
        "failing": CIRCLECI_LOGO_RED,
    }

    return mapping.get(status, CIRCLECI_LOGO_WHITE)

def render_widget(repo_name, latest_pipeline, latest_workflow):
    status = str(latest_workflow.get("status") or "unknown")[:40]
    trigger = latest_pipeline.get("trigger")
    actor = trigger.get("actor") if type(trigger) == "dict" else None
    author = str(actor.get("login") or "Unknown")[:120] if type(actor) == "dict" else "Unknown"
    timestamp = latest_workflow.get("stopped_at") or latest_workflow.get("created_at")
    when = str(timestamp)[:10] if type(timestamp) == "string" else "in progress"

    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = logo_for_status(status), width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(repo_name),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 16, height = 16, color = "#666"),
                            render.Box(width = 2, height = 16),
                            render.Marquee(
                                width = 48,
                                child = render.Column(
                                    children = [
                                        render.Text(author),
                                        render.Text(when),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_fail(message):
    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = CIRCLECI_LOGO_RED, width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(content = "Error", color = "f77"),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.WrappedText(content = message, width = 64, align = "left"),
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
                id = "api_token",
                name = "API Token",
                desc = "Your CircleCI Personal Token",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "vcs",
                name = "VCS",
                desc = "Version Control System",
                icon = "github",
                default = "gh",
                options = [
                    schema.Option(
                        display = "GitHub",
                        value = "gh",
                    ),
                    schema.Option(
                        display = "Bitbucket",
                        value = "bb",
                    ),
                ],
            ),
            schema.Text(
                id = "org",
                name = "Org",
                desc = "Organization that contains repo",
                icon = "building",
            ),
            schema.Text(
                id = "repo",
                name = "Repo",
                desc = "Repository you want to watch",
                icon = "book",
            ),
            schema.Text(
                id = "branch",
                name = "Branch",
                desc = "Filter by branch",
                icon = "codeBranch",
            ),
        ],
    )
