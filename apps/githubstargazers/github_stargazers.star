"""
Applet: GitHub Stargazers
Summary: Display GitHub repo stars
Description: Display the GitHub stargazer count for a repo.
Author: fulghum
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/github_image.png", GITHUB_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_IMAGE = GITHUB_IMAGE_ASSET.readall()
GITHUB_API_VERSION = "2026-03-10"

def main(config):
    org_name = valid_component(config.get("org_name") or "tronbyt")
    repo_name = valid_component(config.get("repo_name") or "apps")
    if not org_name or not repo_name:
        return message("Check repository")

    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
    }
    api_key = config.get("github_api_key")
    if api_key:
        if not valid_secret(api_key):
            return message("Check GitHub token")
        headers["Authorization"] = "Bearer %s" % api_key

    response = http.get("https://api.github.com/repos/%s/%s" % (org_name, repo_name), headers = headers)
    if response.status_code != 200 or len(response.body()) > 2 * 1024 * 1024:
        return message("GitHub unavailable (%d)" % response.status_code)
    payload = json.decode(response.body(), {})
    count = payload.get("stargazers_count") if type(payload) == "dict" else None
    if type(count) != "int" or count < 0:
        return message("Star count unavailable")

    display_name = "%s/%s" % (org_name, repo_name)
    name = render.Text(color = "#6cc644", content = display_name)
    if len(display_name) > 12:
        name = render.Marquee(width = 64, child = name)
    stars = "%s stars" % humanize.comma(count)
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly" if len(stars) > 5 else "center",
                    cross_align = "center",
                    children = [
                        render.Padding(pad = (1, 1, 1, 1), child = render.Image(GITHUB_IMAGE, height = 16)),
                        render.WrappedText(stars, font = "tb-8" if len(stars) > 7 else "6x13"),
                    ],
                ),
                name,
            ],
        ),
    )

def valid_component(value):
    if type(value) != "string":
        return None
    value = value.strip()
    if not value or len(value) > 100 or not all([char.isalnum() or char in "-_." for char in value.codepoints()]):
        return None
    return value

def valid_secret(value):
    return type(value) == "string" and value and len(value) <= 2048 and "\r" not in value and "\n" not in value

def message(text):
    return render.Root(child = render.WrappedText(text, color = "#ffcc66"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "org_name", name = "Org Name", icon = "user", desc = "Name of the organization, or account, containing the GitHub repository"),
            schema.Text(id = "repo_name", name = "Repo Name", icon = "user", desc = "Name of the GitHub repository for which to display stargazer count"),
            schema.Text(id = "github_api_key", name = "GitHub API Key", icon = "key", desc = "A GitHub API key to increase rate limits.", secret = True),
        ],
    )
