load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon.png", ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICON = ICON_ASSET.readall()
MAX_RESPONSE_BYTES = 256 * 1024

def main(config):
    token = config.get("api-token")
    domain = gitlab_origin(config.get("custom-domain", "https://gitlab.com/"))
    if type(token) != "string" or not token or len(token) > 512 or any([char in token for char in ["\r", "\n"]]):
        message = "Configure GitLab token"
    elif not domain:
        message = "Use a public HTTPS GitLab URL"
    else:
        message = get_issues(token, domain)

    return render.Root(
        child = render.Row(
            expanded = True,
            cross_align = "top",
            children = [render.Image(src = ICON), render.WrappedText(message[:160])],
        ),
    )

def get_issues(token, domain):
    response = http.get(
        domain + "/api/v4/user_counts",
        headers = {"PRIVATE-TOKEN": token},
    )
    body = response.body()
    if response.status_code != 200 or len(body) > MAX_RESPONSE_BYTES:
        return "GitLab unavailable (%d)" % response.status_code
    payload = json.decode(body, {})
    count = payload.get("assigned_issues") if type(payload) == "dict" else None
    if type(count) != "int" or count < 0 or count > 1000000:
        return "Invalid GitLab response"
    if count == 0:
        return "You have no open issues!"
    if count == 1:
        return "You have 1 open issue!"
    return "You have %d open issues!" % count

def gitlab_origin(value):
    if type(value) != "string" or len(value) > 2048 or not value.startswith("https://") or any([char in value for char in [" ", "\t", "\r", "\n", "?", "#"]]):
        return ""
    parts = value.split("/", 3)
    host = parts[2].lower() if len(parts) >= 3 else ""
    if not host or "@" in host or ":" in host:
        return ""
    path = parts[3].strip("/") if len(parts) == 4 else ""
    return "" if path else "https://" + host

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api-token",
                name = "Your GitLab access token",
                desc = "A read-only GitLab personal access token.",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "custom-domain",
                name = "GitLab URL",
                desc = "Public HTTPS root URL for GitLab.com or a self-managed instance.",
                icon = "cube",
                default = "https://gitlab.com/",
            ),
        ],
    )
