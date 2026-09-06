"""
Applet: TiddlySynth
Summary: Pixel art synths
Description: Adorn your Tidbyt with an array of animated retro synths. Most of the classics are here, plus an evolving selection of wacky fantasy music making devices.
Author: Owain Rich
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/failsafe_image.png", FAILSAFE_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FAILSAFE_IMAGE = FAILSAFE_IMAGE_ASSET.readall()

jsonUrl = "https://www.fourontuesday.com/tidbyt/synths/synths.json"

DEFAULT_TYPE = "all"

#this image will be rendered if we can't reach the server to parse json

jsonData = False

def main(config):
    synthType = config.get("SynthSelector", DEFAULT_TYPE)
    if synthType not in ["classic", "fantasy", "all"]:
        synthType = DEFAULT_TYPE
    jsonData = getJsonData()
    kind = synthType if synthType != "all" else ["classic", "fantasy"][random.number(0, 1)]
    synth = selectSynth(jsonData, kind)
    synthData = http.get(synth, ttl_seconds = 3600) if synth else None
    body = synthData.body() if synthData else ""
    content_type = synthData.headers.get("Content-Type", "").lower() if synthData else ""
    theSynth = body if synthData and synthData.status_code == 200 and body and len(body) <= 2 * 1024 * 1024 and content_type.startswith("image/") else FAILSAFE_IMAGE
    return render.Root(
        render.Image(src = theSynth),
    )

#go and get json data and cache for 10 mins
def getJsonData():
    res = http.get(jsonUrl, ttl_seconds = 600)
    body = res.body()
    return json.decode(body, {}) if res.status_code == 200 and body and len(body) <= 64 * 1024 else {}

def selectSynth(data, kind):
    feed = data.get(kind, []) if type(data) == "dict" else []
    if type(feed) != "list" or not feed:
        return None
    item = feed[random.number(0, min(len(feed), 100) - 1)]
    url = item.get("url") if type(item) == "dict" else None
    return url if type(url) == "string" and len(url) <= 2048 and url.startswith("https://www.fourontuesday.com/") else None

def get_schema():
    synthoptions = [
        schema.Option(
            display = "Classic Synths",
            value = "classic",
        ),
        schema.Option(
            display = "Fantasy Synths",
            value = "fantasy",
        ),
        schema.Option(
            display = "Classic and Fantasy",
            value = "all",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "SynthSelector",
                name = "Synths",
                desc = "Select what synths you want to see.",
                icon = "gaugeHigh",
                default = "all",
                options = synthoptions,
            ),
        ],
    )
