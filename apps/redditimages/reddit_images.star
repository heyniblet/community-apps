"""
Applet: Reddit Images
Summary: Shuffle Subreddit Images
Description: Show a random image post from a custom list of subreddits (up to 10) and/or a list of default subreddits. Use the ID displayed to access the post on a computer, at https://www.reddit.com/{id}. Reddit API client credentials are required.
Author: Nicole Brooks
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/error_img.png", ERROR_IMG_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ERROR_IMG = ERROR_IMG_ASSET.readall()

DEFAULT_SUBREDDITS = ["blackcats", "aww", "eyebleach", "itookapicture", "cats", "pic", "otters", "plants"]
APPROVED_FILETYPES = [".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"]
IMAGE_PREFIXES = ["https://i.redd.it/", "https://preview.redd.it/", "https://external-preview.redd.it/"]
TOKEN_URL = "https://www.reddit.com/api/v1/access_token"
LISTING_PREFIX = "https://oauth.reddit.com/r/"
USER_AGENT = "Niblet Reddit Images/1.0 (hello@heyniblet.com)"
MAX_TOKEN_BYTES = 64 * 1024
MAX_LISTING_BYTES = 512 * 1024
MAX_IMAGE_BYTES = 4 * 1024 * 1024
CACHE_SECONDS = 300

def main(config):
    # Build full sub list based on user options.
    allSubs = combineSubs(config)

    # Get subreddit name and chosen post (pseudo)randomly.
    chosenSub = allSubs[getRandomNumber(len(allSubs))]
    currentPost = getPosts(chosenSub, config)

    # Render image/text
    imgSrc = get_image(currentPost.get("url"))
    return render.Root(
        max_age = CACHE_SECONDS,
        child =
            render.Box(
                color = "#0f0f0f",
                child = render.Row(
                    children = [
                        render.Image(
                            src = imgSrc,
                            width = 35,
                            height = 35,
                        ),
                        render.Padding(
                            expanded = True,
                            pad = 1,
                            child = render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                children = [
                                    render.Marquee(
                                        width = 28,
                                        child = render.Text(
                                            content = currentPost["title"],
                                            font = "tom-thumb",
                                            color = "#8899A6",
                                        ),
                                    ),
                                    render.Marquee(
                                        width = 28,
                                        child = render.Text(
                                            content = currentPost["sub"],
                                            font = "tom-thumb",
                                            color = "#6B8090",
                                        ),
                                    ),
                                    render.Text(
                                        content = currentPost["id"],
                                        font = "tom-thumb",
                                        color = "#556672",
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
    )

# Gets a random number from 0 to the number specified (non-inclusive).
def getRandomNumber(max):
    return random.number(0, max - 1)

# Combines the default subs (if applicable) with any custom subs inputted.
def combineSubs(config):
    allSubs = []
    allSubs = checkCustomSubSchema("subOne", config, allSubs)
    allSubs = checkCustomSubSchema("subTwo", config, allSubs)
    allSubs = checkCustomSubSchema("subThree", config, allSubs)
    allSubs = checkCustomSubSchema("subFour", config, allSubs)
    allSubs = checkCustomSubSchema("subFive", config, allSubs)
    allSubs = checkCustomSubSchema("subSix", config, allSubs)
    allSubs = checkCustomSubSchema("subSeven", config, allSubs)
    allSubs = checkCustomSubSchema("subEight", config, allSubs)
    allSubs = checkCustomSubSchema("subNine", config, allSubs)
    allSubs = checkCustomSubSchema("subTen", config, allSubs)

    # If the toggle is set to true, or there are no custom values, add the defaults too
    if config.bool("defaults", False) == True or len(allSubs) == 0:
        allSubs = allSubs + DEFAULT_SUBREDDITS

    return allSubs

# Checks if the user entered data in the given input.
def checkCustomSubSchema(subNum, config, currentArray):
    sub = buildSubPrefix(config.str(subNum, ""))
    if sub:
        currentArray.append(sub)
    return currentArray

# Removes any /r or /r/ characters users might have put on the sub name.
def buildSubPrefix(name):
    name = name.strip().lower()
    for prefix in ["https://www.reddit.com/r/", "http://www.reddit.com/r/", "/r/", "r/"]:
        if name.startswith(prefix):
            name = name[len(prefix):]
            break
    name = name.split("/")[0]
    if len(name) < 2 or len(name) > 21 or not all([char.isalnum() or char == "_" for char in name.codepoints()]):
        return ""
    return name

# Gets either the cached posts or runs an API call to reddit for more.
def getPosts(subname, config):
    newTokenRes = getNewAccessToken(config)
    accessToken = newTokenRes.get("access_token") if type(newTokenRes) == "dict" else None
    if type(accessToken) != "string" or not accessToken:
        return handleApiError("Add Reddit API credentials")

    apiUrl = LISTING_PREFIX + subname + "/hot.json?limit=30&raw_json=1"
    auth = "Bearer " + accessToken
    rep = http.get(
        apiUrl,
        headers = {
            "User-Agent": USER_AGENT,
            "Authorization": auth,
        },
        ttl_seconds = CACHE_SECONDS,
    )
    body = rep.body()
    data = json.decode(body, None) if rep.status_code == 200 and body and len(body) <= MAX_LISTING_BYTES else None
    listing = data.get("data", {}) if type(data) == "dict" else {}
    posts = listing.get("children", []) if type(listing) == "dict" else []
    if type(posts) != "list":
        return handleApiError("Reddit unavailable")

    allImagePosts = []
    for child in posts[:30]:
        post = child.get("data", {}) if type(child) == "dict" else {}
        image_url = post_image_url(post)
        if image_url:
            allImagePosts.append({
                "id": post.get("id", ""),
                "image_url": image_url,
                "subreddit_name_prefixed": post.get("subreddit_name_prefixed", "r/" + subname),
                "title": post.get("title", ""),
            })

    return setRandomPost(allImagePosts, subname)

# Build an error display for users.
def handleApiError(message = "Reddit unavailable"):
    return {
        "sub": "r/???",
        "title": message,
        "id": "00000",
    }

# Get random post from all image posts for that sub. Build and return display data.
def setRandomPost(allImagePosts, subname):
    if len(allImagePosts) > 0:
        chosen = allImagePosts[getRandomNumber(len(allImagePosts))]
        return {
            "url": chosen["image_url"],
            "sub": safe_text(chosen["subreddit_name_prefixed"], "r/" + subname, 28),
            "id": safe_text(chosen["id"], "00000", 12),
            "title": safe_text(chosen["title"], "Untitled", 240),
        }

    else:
        # This else will only run if there are no image posts in the top 30 in /r/hot for a sub.
        return {
            "sub": "r/" + subname,
            "title": "no results",
            "id": "00000",
        }

# Get a new reddit access token.
# https://github.com/reddit-archive/reddit/wiki/OAuth2#application-only-oauth
def getNewAccessToken(config):
    client_id = config.str("reddit_client_id", "").strip()
    authSecret = config.str("reddit_client_secret", "").strip()
    if not valid_credential(client_id) or not authSecret or len(authSecret) > 256:
        return {}
    auth = tuple([client_id, authSecret])
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
    }
    body = dict(
        grant_type = "client_credentials",
    )
    res = http.post(
        url = TOKEN_URL,
        headers = headers,
        auth = auth,
        form_body = body,
        form_encoding = "application/x-www-form-urlencoded",
    )
    response_body = res.body()
    data = json.decode(response_body, None) if res.status_code == 200 and response_body and len(response_body) <= MAX_TOKEN_BYTES else None
    return data if type(data) == "dict" else {}

def valid_credential(value):
    return value and len(value) <= 128 and all([char.isalnum() or char in "-_" for char in value.codepoints()])

def post_image_url(post):
    if type(post) != "dict":
        return None
    direct = post.get("url_overridden_by_dest", post.get("url"))
    if valid_image_url(direct):
        return direct
    preview = post.get("preview", {})
    images = preview.get("images", []) if type(preview) == "dict" else []
    if type(images) == "list" and len(images) > 0 and type(images[0]) == "dict":
        resolutions = images[0].get("resolutions", [])
        if type(resolutions) == "list" and len(resolutions) > 0 and type(resolutions[0]) == "dict":
            url = resolutions[0].get("url")
            url = url.replace("&amp;", "&") if type(url) == "string" else None
            return url if valid_image_url(url) else None
    return None

def valid_image_url(url):
    if type(url) != "string" or not any([url.startswith(prefix) for prefix in IMAGE_PREFIXES]):
        return False
    path = url.split("?")[0].lower()
    return any([path.endswith(extension) for extension in APPROVED_FILETYPES])

def get_image(url):
    if not valid_image_url(url):
        return ERROR_IMG
    response = http.get(url, ttl_seconds = 24 * 60 * 60)
    body = response.body()
    return body if response.status_code == 200 and body and len(body) <= MAX_IMAGE_BYTES else ERROR_IMG

def safe_text(value, fallback, limit):
    return value[:limit] if type(value) == "string" and value else fallback

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "subOne",
                name = "Custom sub 1",
                desc = "Enter up to 10 subreddits you would like to pull images from.",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subTwo",
                name = "Custom sub 2",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subThree",
                name = "Custom sub 3",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subFour",
                name = "Custom sub 4",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subFive",
                name = "Custom sub 5",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subSix",
                name = "Custom sub 6",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subSeven",
                name = "Custom sub 7",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subEight",
                name = "Custom sub 8",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subNine",
                name = "Custom sub 9",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subTen",
                name = "Custom sub 10",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Toggle(
                id = "defaults",
                name = "Include defaults",
                desc = "In addition to custom subreddits, include defaults? (/r/cats, /r/otters, /r/blackcats, /r/plants, /r/itookapicture, /r/aww, /r/eyebleach, /r/pic)",
                icon = "otter",
                default = False,
            ),
            schema.Text(
                id = "reddit_client_id",
                name = "Reddit Client ID",
                desc = "The client ID from your Reddit API application.",
                icon = "key",
            ),
            schema.Text(
                id = "reddit_client_secret",
                name = "Reddit Client Secret",
                desc = "A Reddit client secret to access the Reddit API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
