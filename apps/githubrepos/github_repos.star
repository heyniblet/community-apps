"""
Applet: GitHub Badge
Summary: GitHub badge status
Description: Displays a GitHub badge for the status of the configured action.
Author: Cavallando
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/github_failed.png", GITHUB_FAILED_ICON_ASSET = "file")
load("images/github_fault.png", GITHUB_FAULT_ICON_ASSET = "file")
load("images/github_loading.png", GITHUB_LOADING_ICON_ASSET = "file")
load("images/github_logo.png", GITHUB_LOGO_ASSET = "file")
load("images/github_neutral.png", GITHUB_NEUTRAL_ICON_ASSET = "file")
load("images/github_success.png", GITHUB_SUCCESS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

GITHUB_API_VERSION = "2026-03-10"

GITHUB_LOGO = GITHUB_LOGO_ASSET.readall()
GITHUB_FAILED_ICON = GITHUB_FAILED_ICON_ASSET.readall()
GITHUB_SUCCESS_ICON = GITHUB_SUCCESS_ICON_ASSET.readall()
GITHUB_NEUTRAL_ICON = GITHUB_NEUTRAL_ICON_ASSET.readall()
GITHUB_FAULT_ICON = GITHUB_FAULT_ICON_ASSET.readall()
GITHUB_LOADING_ICON = GITHUB_LOADING_ICON_ASSET.readall()

def should_show_jobs(repos, dwell_time):
    now = time.now()
    for repo in repos:
        if "data" not in repo:
            continue
        job = repo["data"]
        conclusion = str(job.get("conclusion", "unknown"))

        # Show all repos if any repo is not success (including cancelled)
        if conclusion not in ["success", "cancelled"]:
            return True

        # Show all repos if any success is recent
        updated_value = job.get("updated_at")
        if type(updated_value) != "string" or len(updated_value) != 20:
            return True
        updated_at = time.parse_time(updated_value, format = "2006-01-02T15:04:05Z").in_location("UTC")
        duration = now - updated_at
        if duration.seconds <= dwell_time * 60:
            return True

    return False

def get_status_icon(status, conclusion):
    """Gets the decoded icon string for a given Workflow Status from github

    Args:
        status: The status of the workflow, can be anyone of the statuses found here
            https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow

    Returns:
    The appropriate icon string
    """
    if status == "failed" or status == "timed_out" or conclusion == "failure":
        return GITHUB_FAILED_ICON
    elif status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif (
        status == "cancelled" or
        status == "skipped" or
        status == "stale" or
        status == "neutral"
    ):
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def fetch_workflow_data(repos, access_token):
    """Fetches the workflow data from GitHub

    Args:
        config: The schema config from TidByt

    Returns:
        The workflow data if it can be found or an error message from the request
    """
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
    }
    if access_token:
        if not valid_secret(access_token):
            return "error", "Check GitHub token"
        headers["Authorization"] = "Bearer {}".format(access_token)

    modified_repos = []
    for repo in repos:
        owner_name, repo_name, branch_name, workflow_id = repo["str"].split("/")
        resp = http.get(
            "https://api.github.com/repos/{}/{}/actions/workflows/{}/runs".format(owner_name, repo_name, workflow_id),
            params = {"branch": branch_name, "per_page": "1", "page": "1"},
            headers = headers,
        )
        if resp.status_code != 200 or len(resp.body()) > 2 * 1024 * 1024:
            return "error", "GitHub unavailable (%d)" % resp.status_code
        data = json.decode(resp.body(), {})

        runs = data.get("workflow_runs", []) if type(data) == "dict" else []
        if type(runs) == "list" and runs and type(runs[0]) == "dict":
            repo_copy = {
                "owner": repo["owner"],
                "name": repo["name"],
                "branch": repo["branch"],
                "workflow": repo["workflow"],
                "str": repo["str"],
                "data": runs[0],
            }
            modified_repos.append(repo_copy)
    return modified_repos, None

# def get_display_text(repo):
#     return config.get("display_text") or "{}/{}".format(repo[0], repo[1])

def render_status_badge(status, repos):
    # workflow_data is an array
    rows = []
    if type(repos) == "list":
        for repo in repos:
            status = str(repo["data"].get("status", "unknown"))
            conclusion = str(repo["data"].get("conclusion", "unknown"))
            rows.append(
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 37,
                            child = render.Text(
                                content = repo["name"],
                                font = "tom-thumb",
                            ),
                        ),
                        render.Image(src = get_status_icon(status, conclusion)),
                    ],
                ),
            )
    else:
        rows.append(
            render.Row(
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 37,
                        child = render.Text(
                            content = repos,
                            font = "tom-thumb",
                        ),
                    ),
                    render.Image(src = get_status_icon(status, "failure")),
                ],
            ),
        )
    return render.Root(
        child = render.Stack(
            children = [
                # render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = BADGE_BACKGROUND, width = 64, height = 30)),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (1, 9, 2, 10),
                            child = render.Image(
                                width = 13,
                                height = 13,
                                src = GITHUB_LOGO,
                            ),
                        ),
                        render.Column(
                            expanded = True,
                            children = rows,
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    """Main render function for the App

    Args:
        config: The schema config from TidByt

    Returns:
        A Root view to render to the app
    """
    repo1 = config.str("repo1", "owner/repo/branch/workflow")
    repo2 = config.str("repo2", "owner/repo/branch/workflow")
    repo3 = config.str("repo3", "owner/repo/branch/workflow")
    repos_strs = [repo1, repo2, repo3]
    repos = []
    for repo in repos_strs:
        if repo == "owner/repo/branch/workflow" or repo == "":
            continue
        parts = repo.split("/")
        if len(parts) != 4 or not valid_component(parts[0]) or not valid_component(parts[1]) or not valid_branch(parts[2]) or not valid_component(parts[3]):
            return render_status_badge("failed", "Check repo configuration")
        owner, name, branch, workflow = parts
        repos.append({"owner": owner, "name": name, "branch": branch, "workflow": workflow, "str": repo})
    if not repos:
        return render_status_badge("failed", "Configure a repository")

    timeout = config.get("timeout", "0")
    if type(timeout) != "string" or not timeout.isdigit() or len(timeout) > 5:
        return render_status_badge("failed", "Check success timeout")
    timeout = min(int(timeout), 10080)

    workflow_data = []
    workflow_data, err = fetch_workflow_data(repos, config.get("access_token", None))

    if err:
        return render_status_badge("failed", err)
        # elif len(workflow_data) == 0 and access_token == None:
        #     return render_status_badge("success", "no data")

    elif workflow_data and type(workflow_data) != "string":
        should_show = should_show_jobs(workflow_data, timeout)
        if not should_show:
            return []

        return render_status_badge("success", workflow_data)
    elif workflow_data:
        return render_status_badge("failed", workflow_data)
    else:
        return render_status_badge("failed", "Could not connect to GitHub")

def valid_component(value):
    return type(value) == "string" and value and len(value) <= 100 and all([char.isalnum() or char in "-_." for char in value.codepoints()])

def valid_branch(value):
    return type(value) == "string" and value and len(value) <= 200 and "\r" not in value and "\n" not in value

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 2048 and "\r" not in value and "\n" not in value

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "GitHub Personal Access Token",
                desc = "Personal Access token (optional, only required for private repos)",
                icon = "lock",
                secret = True,
            ),
            schema.Text(
                id = "repo1",
                name = "Repo 1",
                desc = "Repo 1",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo2",
                name = "Repo 2",
                desc = "Repo 2",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo3",
                name = "Repo 3",
                desc = "Repo 3",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "timeout",
                name = "All Success Timeout",
                desc = "How long to show all green",
                icon = "clock",
                default = "0",
            ),
        ],
    )
