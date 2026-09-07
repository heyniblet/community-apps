"""Show Workspace ONE UEM device totals by platform."""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/wsicon.png", WSICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

WSICON = WSICON_ASSET.readall()

def configured(config):
    values = [config.get(key) or "" for key in ["ogi", "tenantcodei", "tenanturli", "adminuseri", "adminpasswordi"]]
    if not all([type(value) == "string" for value in values]):
        return None
    og, tenant_code, tenant_url, username, password = values
    if (
        not tenant_url.startswith("https://") or
        any([char in tenant_url for char in ["?", "#", "@"]]) or
        len(tenant_url) > 512 or
        len(og) > 20 or
        not og.isdigit() or
        not tenant_code or
        len(tenant_code) > 256 or
        not username or
        len(username) > 256 or
        not password or
        len(password) > 1024
    ):
        return None
    return struct(og = og, tenant_code = tenant_code, tenant_url = tenant_url.rstrip("/"), username = username, password = password)

def request_json(url, headers):
    response = http.get(url, headers = headers)
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 1048576:
        return None
    value = json.decode(body, None)
    return value if type(value) == "dict" else None

def number(value):
    if type(value) in ["int", "float"] and value >= 0:
        return float(value)
    if type(value) == "string" and len(value) <= 20 and value.isdigit():
        return float(value)
    return 0.0

def main(config):
    settings = configured(config)
    if settings == None:
        return status("Configure Workspace ONE API access")
    headers = {
        "Authorization": "Basic " + base64.encode(settings.username + ":" + settings.password),
        "Accept": "application/json",
        "aw-tenant-code": settings.tenant_code,
    }
    root = request_json(settings.tenant_url + "/API/system/groups/devicecounts?organizationgroupid=" + settings.og, headers)
    devices = request_json(settings.tenant_url + "/API/mdm/devices/devicecountinfo?organizationgroupid=" + settings.og, headers)
    groups = root.get("LocationGroups") if root != None else None
    platforms = devices.get("Platforms") if devices != None else None
    if type(groups) != "list" or not groups or type(platforms) != "dict":
        return status("Workspace ONE API unavailable")

    first_group = groups[0]
    root_name = str(first_group.get("LocationGroupName") or "Workspace ONE")[:80] if type(first_group) == "dict" else "Workspace ONE"
    rows = [
        ("Android", number(platforms.get("Android"))),
        ("iOS", number(platforms.get("Apple"))),
        ("macOS", number(platforms.get("AppleOsX"))),
        ("Windows", number(platforms.get("WindowsRT"))),
    ]
    return render.Root(child = render.Column(children = [
        render.Row(children = [render.Image(src = WSICON), render.Marquee(width = 64, child = render.Text(root_name, font = "5x8", color = "#00a"))]),
    ] + [render.Text(name + ": " + humanize.ftoa(count, 0), height = 6, font = "tom-thumb") for name, count in rows]))

def status(text):
    return render.Root(child = render.WrappedText(text, width = 64, align = "center"))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "ogi", name = "Root Organization Group ID", desc = "Numeric ID from the OG Details page.", icon = "pager"),
        schema.Text(id = "tenantcodei", name = "Tenant Code", desc = "AirWatch API key from the REST API settings.", icon = "code", secret = True),
        schema.Text(id = "tenanturli", name = "Tenant URL", desc = "Public HTTPS API URL for your Workspace ONE tenant (port 443).", icon = "html5"),
        schema.Text(id = "adminuseri", name = "API Admin's Username", desc = "Username for the API admin user.", icon = "person"),
        schema.Text(id = "adminpasswordi", name = "API Admin's Password", desc = "Password for the API admin user.", icon = "unlock", secret = True),
    ])
