#Shows current song being played on Capital Radio 604.
#
#by Craig J. Johnston
#email: ibanyan@gmail.com

load("http.star", "http")

# Import the required libraries
load("render.star", "render")

#Set the fonts
SMALLFONT = "tom-thumb"
FONT = "tb-8"
HFONT = "6x13"

#Set your IceCast JSON info URL.
icecast_json_url = "https://streaming.galaxywebsolutions.com/json/stream/capitalradio604"

# Main function to render the Tidbyt app

#Here we are calling the JSON info URL and including all the headers.  We check to make sure it returns a HTTP 200.
#If not, we fail the app which makes it stop.

#We can then retirieve the song playing right now plus the last 5 songs played.

def main():
    rep = http.get(icecast_json_url, ttl_seconds = 60)
    if rep.status_code != 200:
        print("Capital Radio request failed with status %d" % rep.status_code)
        return message("Capital 604", "Temporarily unavailable")

    body = rep.body().strip()
    payload = rep.json() if len(body) <= 65536 and body.startswith("{") and body.endswith("}") else {}
    now_playing = payload.get("nowplaying", "") if type(payload) == "dict" else ""
    if type(now_playing) != "string" or not now_playing.strip():
        return message("Capital 604", "No track information")

    # last_song_1 = rep.json()["trackhistory"][0]
    # last_song_2 = rep.json()["trackhistory"][1]
    # last_song_3 = rep.json()["trackhistory"][2]
    # last_song_4 = rep.json()["trackhistory"][3]
    # last_song_5 = rep.json()["trackhistory"][4]
    # station_name = rep.json()["servername"]
    # We are collecting the last 5 tracks played but not using them just yet ...

    #Simplest layout for version 1.

    return render.Root(
        child = render.Column(
            # Column is a vertical children layout
            children = [
                render.Stack(
                    children = [
                        render.Box(width = 64, height = 13, color = "#ffffff"),
                        render.Text("Capital 604", font = HFONT, height = 12, color = "#228ee9"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Text("Now Playing...", font = FONT, height = 10, color = "#03287c"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(now_playing[:200], font = FONT, height = 8),
                        ),
                    ],
                ),
            ],
        ),
    )

def message(title, detail):
    return render.Root(
        child = render.Column(
            children = [
                render.Text(title, font = HFONT, color = "#228ee9"),
                render.Text(detail, font = SMALLFONT),
            ],
            main_align = "center",
            cross_align = "center",
        ),
    )
