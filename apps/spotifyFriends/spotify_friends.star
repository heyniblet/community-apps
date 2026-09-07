"""
Applet: Spotify Friends
Summary: Spotify friend activity
Description: Displays last listening activity for random spotify friend.
Author: klaffitte
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

spotifyTokenUrl = "https://open.spotify.com/get_access_token?reason=transport&productType=web_player"
spotifyFriendUrl = "https://guc-spclient.spotify.com/presence-view/v1/buddylist"

def main(config):
    configCookie = config.get("spDcCookie")
    username = config.get("username")
    if type(configCookie) == "string" and len(configCookie) <= 4096 and type(username) == "string" and len(username) <= 100:
        spDcCookie = "sp_dc=" + str(configCookie)

        tokenResponse = getAuthToken(spotifyTokenUrl, spDcCookie)
        if tokenResponse["status"] != 200:
            return render_error("Token request failed", tokenResponse["status"])

        else:
            friendResponse = getFriendData(spotifyFriendUrl, tokenResponse["token"])
            if friendResponse["status"] != 200:
                return render_error("Friend request failed", friendResponse["status"])

            else:
                friends = friendResponse["friendData"].get("friends")
                if type(friends) != "list" or not friends:
                    return render_error("No friend activity")
                friend = friends[random.number(0, min(len(friends), 50) - 1)]
                user = friend.get("user") if type(friend) == "dict" else None
                track = friend.get("track") if type(friend) == "dict" else None
                artist = track.get("artist") if type(track) == "dict" else None
                if type(user) != "dict" or type(track) != "dict" or type(artist) != "dict":
                    return render_error("Invalid friend activity")

                imageResponse = getImage(track.get("imageUrl"))
                if imageResponse["status"] != 200:
                    return render_error("Image request failed", imageResponse["status"])

                else:
                    return render.Root(
                        child = render.Padding(
                            pad = 2,
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(
                                            content = str(user.get("name") or username)[:80],
                                            offset = 1,
                                            color = "#1DB954",
                                        ),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        children = [
                                            render.Image(
                                                width = 20,
                                                src = imageResponse["image"],
                                            ),
                                            render.Column(
                                                expanded = True,
                                                main_align = "space_between",
                                                children = [
                                                    render.Marquee(
                                                        width = 38,
                                                        child = render.Text(
                                                            content = str(track.get("name") or "Unknown track")[:120],
                                                        ),
                                                    ),
                                                    render.Marquee(
                                                        width = 38,
                                                        child = render.Text(
                                                            content = str(artist.get("name") or "Unknown artist")[:120],
                                                            offset = 1,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    )

    else:
        return render_error("Missing username or sp_dc cookie")

def render_error(message, status = None):
    suffix = " (" + str(status) + ")" if status != None else ""
    return render.Root(child = render.WrappedText(content = message + suffix, width = 64, align = "center"))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "spDcCookie",
                name = "spDc Cookie",
                desc = "Your Spotify web browser authentication cookie",
                icon = "spotify",
                secret = True,
            ),
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Your Spotify username (not display name)",
                icon = "user",
            ),
        ],
    )

#get auth token
def getAuthToken(spotifyTokenUrl, spDcCookie):
    res = http.get(spotifyTokenUrl, headers = {"Cookie": spDcCookie})
    if res.status_code != 200:
        return {"token": None, "status": res.status_code}
    data = res.json()
    token = data.get("accessToken") if type(data) == "dict" else None
    return {"token": "Bearer " + token if type(token) == "string" else None, "status": 200 if token else 502}

#get friend data
def getFriendData(spotifyFriendUrl, accessToken):
    res = http.get(spotifyFriendUrl, headers = {"Authorization": accessToken})
    if res.status_code != 200:
        return {"friendData": {}, "status": res.status_code}
    data = res.json()
    return {"friendData": data if type(data) == "dict" else {}, "status": 200 if type(data) == "dict" else 502}

#get cover art
def getImage(image_url):
    if type(image_url) != "string" or not image_url.startswith("https://i.scdn.co/image/"):
        return {"image": None, "status": 502}
    res = http.get(image_url)
    image = res.body()
    imageResponse = {
        "image": image,
        "status": res.status_code,
    }
    return imageResponse
