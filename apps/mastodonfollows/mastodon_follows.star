"""Display a Mastodon account's follower count."""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/mastodon_icon.png", MASTODON_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

MASTODON_ICON = MASTODON_ICON_ASSET.readall()

def config_value(value, default):
    if type(value) != "string" or not value.strip():
        return default
    value = value.strip()
    if value.startswith("{"):
        option = json.decode(value, {})
        value = option.get("value") if type(option) == "dict" else None
    return value.strip() if type(value) == "string" and value.strip() else default

def main(config):
    username = config_value(config.get("username"), "lisamelton").lstrip("@")
    instance = config_value(config.get("instance"), "mastodon.social")
    instance = instance[len("https://"):] if instance.startswith("https://") else instance
    instance = instance.rstrip("/")

    if (
        len(username) > 80 or
        len(instance) > 253 or
        any([char in username for char in ["/", "?", "#", "@", " "]]) or
        any([char in instance for char in ["/", "?", "#", "@", " ", ":"]])
    ):
        return message("Configure a valid Mastodon account")

    account = "@%s@%s" % (username, instance)
    followers = get_followers_count(instance, username)
    count_text = "Not found" if followers == None else "%s %s" % (
        humanize.comma(followers),
        humanize.plural_word(followers, "follower"),
    )
    account_text = render.Text(account[:340], color = "#3c3c3c")
    if len(account) > 12:
        account_text = render.Marquee(width = 64, child = account_text)

    return render.Root(child = render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [render.Image(MASTODON_ICON), render.WrappedText(count_text)],
            ),
            account_text,
        ],
    ))

def get_followers_count(instance, username):
    response = http.get(
        "https://%s/api/v1/accounts/lookup" % instance,
        params = {"acct": username},
        headers = {"Accept": "application/json"},
    )
    body = response.body()
    if response.status_code != 200 or not body or len(body) > 131072:
        return None
    account = json.decode(body, {})
    count = account.get("followers_count") if type(account) == "dict" else None
    return count if type(count) == "int" and count >= 0 and count <= 1000000000000 else None

def message(text):
    return render.Root(child = render.WrappedText(text, width = 64, align = "center"))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(
            id = "instance",
            name = "Instance",
            desc = "Mastodon server hostname, such as mastodon.social.",
            icon = "gear",
            default = "mastodon.social",
        ),
        schema.Text(
            id = "username",
            name = "User Name",
            icon = "user",
            desc = "Account name whose follower count should be displayed.",
            default = "lisamelton",
        ),
    ])
