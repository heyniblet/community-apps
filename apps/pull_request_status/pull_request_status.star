load("encoding/json.star", "json")
load("http.star", "http")
load("images/closed_icon_36165f4e.png", CLOSED_ICON_36165f4e_ASSET = "file")
load("images/merged_icon_f460a18e.png", MERGED_ICON_f460a18e_ASSET = "file")
load("images/open_icon_edd4ab84.png", OPEN_ICON_edd4ab84_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64
MAX_RESPONSE_BYTES = 262144

CLOSED_ICON = CLOSED_ICON_36165f4e_ASSET.readall()
MERGED_ICON = MERGED_ICON_f460a18e_ASSET.readall()
OPEN_ICON = OPEN_ICON_edd4ab84_ASSET.readall()

def read_repo_pr_label_setup(config):
    repo_pr_label_setup = []
    for i in range(3):
        pr = config.get("pr_" + str(i))
        if pr:
            entry = pr.split(" ")
            if len(entry) >= 3 and valid_repo(entry[0]) and entry[1].isdigit() and int(entry[1]) > 0:
                repo_pr_label_setup.append([entry[0], entry[1], " ".join(entry[2:])])
    return repo_pr_label_setup

def valid_repo(repo):
    parts = repo.split("/")
    if len(parts) != 2 or not parts[0] or not parts[1] or len(repo) > 201:
        return False
    for char in repo.elems():
        if not (char.isalnum() or char in "-._/"):
            return False
    return True

# returns "merged" or "closed" or "open"
def get_pr_status(repo, pr):
    api_url = "https://api.github.com/repos/" + repo + "/pulls/" + str(pr)

    response = http.get(api_url, ttl_seconds = 300, headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "Niblet-Community-App",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    body = response.body()

    # Parse the response JSON
    if response.status_code == 200 and body and len(body) <= MAX_RESPONSE_BYTES:
        pr_data = json.decode(body, None)
        if type(pr_data) != "dict":
            return None
        if pr_data.get("merged_at") != None:
            return "merged"
        elif pr_data.get("state") == "closed":
            return "closed"
        else:
            return "open"
    else:
        return None

def get_status_icon(status):
    if not status:
        return None
    if status == "merged":
        return MERGED_ICON
    elif status == "closed":
        return CLOSED_ICON
    else:
        return OPEN_ICON

def main(config):
    repo_pr_setup = read_repo_pr_label_setup(config)

    repo_pr_status_list = [[repo, pr, label, get_pr_status(repo, pr)] for repo, pr, label in repo_pr_setup]

    elements_to_display = [[label, get_status_icon(status)] for repo, pr, label, status in repo_pr_status_list]

    if len(elements_to_display) == 0:
        return render_message("Add: owner/repo PR label")

    # hide_after = config.str("hide_after")

    # displaying_prs = []
    # for repo, pr, status in repo_pr_status_list:
    #     # check in cache if in cache
    #     # if yes: get update time and status
    #     # if changed: update value and time
    #     if (hide_after == "never"):
    #         continue
    #     hide_after_hours = int(hide_after)

    image_height = min(int(24 / len(elements_to_display)), 15)
    return render.Root(
        render.Padding(
            render.Column(
                [
                    render.Text(
                        "PR-Overview",
                        font = "tom-thumb",
                    ),
                    render.Box(
                        width = TIDBYT_WIDTH,
                        height = 1,
                        color = "#ffffff",
                    ),
                ] +
                [
                    render.Row(
                        [
                            render.Marquee(
                                render.WrappedText(
                                    label,
                                    font = "tom-thumb",
                                ),
                                width = 62 - image_height,
                            ),
                            (render.Image(
                                src = status_icon,
                                height = image_height,
                            ) if status_icon else render.Text(
                                "?",
                            )),
                        ],
                        main_align = "space_between",
                        expanded = True,
                        cross_align = "center",
                    )
                    for label, status_icon in elements_to_display
                ],
                expanded = True,
                main_align = "space_evenly",
            ),
            pad = (1, 0, 1, 0),
        ),
    )

def render_message(message):
    return render.Root(child = render.Box(child = render.WrappedText(message, align = "center")))

# HIDE_AFTER_OPTIONS = [
#     "never",
#     "1",
#     "2",
#     "10",
#     "24",
#     "48",
# ]

def get_schema():
    # hide_after_schema_options = [
    #     schema.Option(
    #         display = "Never" if option == "never" else (option + " hours"),
    #         value = option,
    #     )
    #     for option in HIDE_AFTER_OPTIONS
    # ]

    return schema.Schema(
        version = "1",
        fields = [
            # schema.Dropdown(
            #     id = "hide_after",
            #     name = "Hide merged PRs after",
            #     desc = "Hide a merged pull request after a certain amount of time",
            #     icon = "clock",
            #     default = HIDE_AFTER_OPTIONS[0],
            #     options = hide_after_schema_options,
            # ),
            schema.Text(
                id = "pr_0",
                name = "Repository and Pull Request 1",
                desc = "Use: owner/repository PR-number label",
                icon = "git",
            ),
            schema.Text(
                id = "pr_1",
                name = "Repository and Pull Request 2",
                desc = "Use: owner/repository PR-number label",
                icon = "git",
            ),
            schema.Text(
                id = "pr_2",
                name = "Repository and Pull Request 3",
                desc = "Use: owner/repository PR-number label",
                icon = "git",
            ),
        ],
    )
