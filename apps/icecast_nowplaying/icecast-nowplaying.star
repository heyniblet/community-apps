"""
Icecast Now Playing - A Tidbyt app showing the currently playing song from an Icecast server
"""

load("http.star", "http")
load("images/icecast_logo.gif", ICECAST_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICECAST_LOGO = ICECAST_LOGO_ASSET.readall()

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured values
    status_url = config.get("status_url", "")
    custom_name = config.get("custom_name", "")
    text_color = config.get("text_color", "#0ff1b2")

    # Validate that a URL is provided
    if type(status_url) != "string" or not status_url.startswith("https://") or len(status_url) > 512 or "@" in status_url or "#" in status_url:
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Please configure Icecast status URL",
                            font = "tb-8",
                            color = "#ff0000",
                            align = "center",
                        ),
                    ],
                ),
            ),
        )

    # Fetch current playing track
    current_data = fetch_current_track(status_url)

    if current_data == None:
        # Fallback display if API is unavailable
        station_name = str(custom_name)[:100] if custom_name else "Icecast Radio"
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = ICECAST_LOGO,
                            width = 32,
                            height = 16,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = station_name + " • Loading...",
                                font = "tb-8",
                                color = text_color,
                            ),
                            scroll_direction = "horizontal",
                        ),
                    ],
                ),
            ),
        )

    # Display current track info
    server_name = str(current_data.get("server_name") or "Icecast Radio")[:100]
    title = str(current_data.get("title") or "Unknown Track")[:200]

    # Use custom name if provided, otherwise use server_name
    display_name = str(custom_name)[:100] if custom_name else server_name

    # Parse title for artist and song
    artist = ""
    song = ""
    if " - " in title:
        parts = title.split(" - ", 1)
        artist = parts[0].strip()
        song = parts[1].strip()

    # Build the display
    children = []

    # Top row: Logo on left, station name in remaining space
    station_text = None
    if len(display_name) > 8:
        station_text = render.Marquee(
            width = 46,
            child = render.Text(
                content = display_name,
                font = "tb-8",
                color = "#888888",
            ),
            scroll_direction = "horizontal",
        )
    else:
        station_text = render.Text(
            content = display_name,
            font = "tb-8",
            color = "#888888",
        )

    top_row = render.Row(
        main_align = "start",
        cross_align = "center",
        children = [
            render.Image(
                src = ICECAST_LOGO,
                width = 16,
                height = 12,
            ),
            render.Box(width = 2, height = 1),  # Small spacer
            station_text,
        ],
    )
    children.append(top_row)

    # Add separator
    children.append(
        render.Box(
            width = 64,
            height = 1,
            color = "#333333",
        ),
    )

    # Add track info - if we have artist and song, show on two lines
    if len(artist) > 0 and len(song) > 0:
        # Artist line
        artist_widget = None
        if len(artist) > 10:
            artist_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = artist,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            artist_widget = render.Text(
                content = artist,
                font = "tb-8",
                color = text_color,
            )
        children.append(artist_widget)

        # Song line
        song_widget = None
        if len(song) > 10:
            song_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = song,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            song_widget = render.Text(
                content = song,
                font = "tb-8",
                color = text_color,
            )
        children.append(song_widget)
    else:
        # No dash, show full title
        title_widget = None
        if len(title) > 10:
            title_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = title,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            title_widget = render.Text(
                content = title,
                font = "tb-8",
                color = text_color,
            )
        children.append(title_widget)

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def get_schema():
    """
    Configuration schema for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "status_url",
                name = "Icecast Status URL",
                desc = "Public HTTPS URL to your Icecast status-json.xsl endpoint (port 443).",
                icon = "radio",
            ),
            schema.Text(
                id = "custom_name",
                name = "Custom Stream Name (Optional)",
                desc = "Custom name for your stream (leave blank to use server_name from Icecast)",
                icon = "tag",
                default = "",
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for track information text",
                icon = "palette",
                default = "#0ff1b2",
            ),
        ],
    )

def fetch_current_track(url):
    """
    Fetch current track from Icecast server status-json.xsl endpoint
    """

    resp = http.get(url)

    if resp.status_code == 200:
        data = resp.json()

        # The Icecast status-json.xsl returns data in this structure:
        # {
        #   "icestats": {
        #     "source": [ ... ] or { ... }  (can be array or single object)
        #   }
        # }

        if type(data) == "dict" and type(data.get("icestats")) == "dict":
            icestats = data["icestats"]
            source = None

            # Handle both array and single source cases
            if "source" in icestats:
                source_data = icestats["source"]

                # If it's a list, get the first source
                if type(source_data) == "list":
                    if len(source_data) > 0:
                        source = source_data[0]
                else:
                    # It's a single source object
                    source = source_data

            if type(source) == "dict":
                # Extract title and server_name
                title = source.get("title", "Unknown Track")
                server_name = source.get("server_name", "Icecast Radio")

                track_data = {
                    "title": title,
                    "server_name": server_name,
                }
                return track_data

        return None
    else:
        return None
