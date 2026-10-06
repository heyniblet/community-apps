load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("random.star", "random")

# Edit this list with your real sports, schools, title counts, and logo URLs.
# Each sport is split into pages of 3 schools. Pages advance every 2 seconds,
# e.g. ranks 1-3, then 2 seconds later ranks 4-5, then the next sport starts.
# The order sports appear in is randomized each time this app re-renders.
SPORTS_DATA = [
    {
        "sport": "FOOTBALL",
        "top5": [
            {"school": "Alabama", "titles": "13", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/333.png"},
            {"school": "Notre Dame", "titles": "8", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/87.png"},
            {"school": "Ohio State", "titles": "7", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/194.png"},
            {"school": "Oklahoma", "titles": "7", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/201.png"},
            {"school": "USC", "titles": "7", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/30.png"},
        ],
    },
    {
        "sport": "M BASKETBALL",
        "top5": [
            {"school": "UCLA", "titles": "11", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/26.png"},
            {"school": "Kentucky", "titles": "8", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/96.png"},
            {"school": "North Carolina", "titles": "6", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/153.png"},
            {"school": "UConn", "titles": "6", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/41.png"},
            {"school": "Duke", "titles": "5", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/150.png"},
            {"school": "Indiana", "titles": "5", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/84.png"},
        ],
    },
    {
        "sport": "BASEBALL",
        "top5": [
            {"school": "USC", "titles": "12", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/30.png"},
            {"school": "LSU", "titles": "8", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/99.png"},
            {"school": "Texas", "titles": "6", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/251.png"},
            {"school": "Arizona State", "titles": "5", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/9.png"},
            {"school": "Cal St. Fullerton", "titles": "4", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/2239.png"},
            {"school": "Miami (FL)", "titles": "4", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/2390.png"},
            {"school": "Arizona", "titles": "4", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/12.png"},
        ],
    },
    {
        "sport": "SYNCHRO SWIM",
        "top5": [
            {"school": "Ohio State", "titles": "34", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/194.png"},
            {"school": "Stanford", "titles": "10", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/24.png"},
            {"school": "Arizona", "titles": "2", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/12.png"},
            {"school": "Lindenwood", "titles": "1", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/2815.png"},
            {"school": "Incarnate Word", "titles": "1", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/2916.png"},
        ],
    },
    {
        "sport": "W ICE HOCKEY",
        "top5": [
            {"school": "Wisconsin", "titles": "8", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/275.png"},
            {"school": "Minnesota", "titles": "6", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/135.png"},
            {"school": "MN Duluth", "titles": "5", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/134.png"},
            {"school": "Clarkson", "titles": "3", "logo_url": ""},
            {"school": "Ohio State", "titles": "2", "logo_url": "https://a.espncdn.com/i/teamlogos/ncaa/500/194.png"},
        ],
    },
]

LOGO_SIZE = 8  # pixels
SCHOOLS_PER_PAGE = 3
PAGE_DELAY_MS = 2000
MAX_NAME_CHARS = 9  # keeps long names from overlapping the title count

def main(config):
    shuffled_sports = shuffle(SPORTS_DATA)

    frames = []
    for sport_entry in shuffled_sports:
        pages = chunk_list(sport_entry["top5"], SCHOOLS_PER_PAGE)
        start_rank = 1
        for page in pages:
            frames.append(build_page_frame(sport_entry["sport"], page, start_rank))
            start_rank += len(page)

    return render.Root(
        delay = PAGE_DELAY_MS,
        child = render.Animation(children = frames),
    )

def shuffle(items):
    result = list(items)
    n = len(result)
    for i in range(n - 1, 0, -1):
        j = random.number(0, i)
        tmp = result[i]
        result[i] = result[j]
        result[j] = tmp
    return result

def chunk_list(items, size):
    chunks = []
    for i in range(0, len(items), size):
        chunks.append(items[i:i + size])
    return chunks

def build_page_frame(sport_name, page_teams, start_rank):
    rows = [build_row(start_rank + i, team) for i, team in enumerate(page_teams)]

    header = render.Text(
        content = sport_name,
        font = "tom-thumb",
        color = "#FFA500",
    )

    return render.Column(
        children = [header] + rows,
    )

def build_row(rank, team):
    logo = get_logo(team["logo_url"], LOGO_SIZE)
    name_color = "#FFFFFF" if rank == 1 else "#AAAAAA"
    short_name = truncate(team["school"], MAX_NAME_CHARS)

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    logo,
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Text(
                            content = "%d %s" % (rank, short_name),
                            font = "tom-thumb",
                            color = name_color,
                        ),
                    ),
                ],
            ),
            render.Text(
                content = team["titles"],
                font = "tom-thumb",
                color = "#FFD700",
            ),
        ],
    )

def truncate(text, max_len):
    if len(text) <= max_len:
        return text
    return text[:max_len]

def get_logo(logo_url, size):
    if not logo_url:
        return render.Box(width = size, height = size, color = "#333333")

    res = http.get(logo_url, ttl_seconds = 86400)
    if res.status_code != 200:
        return render.Box(width = size, height = size, color = "#333333")

    return render.Image(src = res.body(), width = size, height = size)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
