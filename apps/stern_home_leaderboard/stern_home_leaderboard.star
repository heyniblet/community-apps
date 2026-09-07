load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def format_score(n):
    s = str(n)
    res = ""
    count = 0
    for i in range(len(s) - 1, -1, -1):
        if count == 3:
            res = "," + res
            count = 0
        res = s[i] + res
        count += 1
    return res

def login(username, password):
    login_url = "https://api.prd.sternpinball.io/api/v2/token/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Content-Type": "application/json",
    }

    usernames_to_try = [username]
    if "@" in username:
        usernames_to_try.append(username.split("@")[0])

    for u in usernames_to_try:
        body = json.encode({"username": u, "password": password})
        rep = http.post(login_url, headers = headers, body = body)

        if rep.status_code == 200:
            data = rep.json()
            token = data.get("access") or data.get("access_token") if type(data) == "dict" else None
            if type(token) == "string" and len(token) <= 4096:
                return {"token": token}

    return None

def extract_until_quote(games_body, start_idx):
    end1 = games_body.find('\\"', start_idx)
    end2 = games_body.find('"', start_idx)

    valid_ends = []
    if end1 != -1:
        valid_ends.append(end1)
    if end2 != -1:
        valid_ends.append(end2)

    if valid_ends:
        return games_body[start_idx:min(valid_ends)]
    return ""

def get_machines(auth):
    machines_url = "https://api.prd.sternpinball.io/api/v1/portal/user_registered_machines/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
    }
    rep = http.get(machines_url, headers = headers, params = {"group_type": "home"})
    if rep.status_code != 200:
        return []
    data = rep.json()
    user = data.get("user") if type(data) == "dict" else None
    machines = user.get("machines") if type(user) == "dict" else None
    if type(machines) == "list":
        return machines[:20]
    return []

def get_high_scores(auth, machine_id):
    clean_id = str(machine_id).split(".")[0]
    if len(clean_id) > 20 or not clean_id.isdigit():
        return []
    url = "https://api.prd.sternpinball.io/api/v1/portal/game_machine_high_scores/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
    }
    rep = http.get(url, headers = headers, params = {"machine_id": clean_id})
    if rep.status_code != 200:
        return []
    data = rep.json()
    scores = data.get("high_score") if type(data) == "dict" else None
    if type(scores) == "list":
        return scores[:10]
    return []

def main(config):
    username = config.get("username")
    password = config.get("password")
    game_filter = config.get("game_filter", "")

    SCALE = 2 if canvas.is2x() else 1
    FONT = "terminus-16" if canvas.is2x() else "tb-8"
    SMALL_FONT = "tb-8" if canvas.is2x() else "tom-thumb"

    if type(username) != "string" or type(password) != "string" or not username or not password or len(username) > 254 or len(password) > 1024:
        return render.Root(
            child = render.WrappedText("Configure Stern username & password", font = FONT),
        )

    auth = login(username, password)
    if not auth:
        return render.Root(
            child = render.WrappedText("Login failed. Check credentials.", font = FONT),
        )

    machines = get_machines(auth)
    if not machines:
        return render.Root(
            child = render.WrappedText("No machines found.", font = FONT),
        )

    # filter machines
    if game_filter:
        filtered = []
        for m in machines:
            if type(m) != "dict":
                continue
            model_dict = m.get("model") or {}
            model_dict = model_dict if type(model_dict) == "dict" else {}
            title_dict = model_dict.get("title") or {}
            title_dict = title_dict if type(title_dict) == "dict" else {}
            name = str(title_dict.get("name") or "")[:100]
            if game_filter.lower() in name.lower():
                filtered.append(m)
        if filtered:
            machines = filtered

    all_content = []

    # Fetch global games list to extract logo URLs
    games_url = "https://insider.sternpinball.com/games?_rsc=1"
    games_body = ""
    g_rep = http.get(games_url, ttl_seconds = 86400)
    if g_rep.status_code == 200:
        games_body = g_rep.body()

    # We will loop through the machines and append their high scores
    for m in machines:
        if type(m) != "dict":
            continue
        model_dict = m.get("model") or {}
        model_dict = model_dict if type(model_dict) == "dict" else {}
        title_dict = model_dict.get("title") or {}
        title_dict = title_dict if type(title_dict) == "dict" else {}
        machine_name = str(title_dict.get("name") or m.get("name") or "Unknown Game")[:100]

        logo_url = ""
        if games_body:
            idx = games_body.find('\\"name\\":\\"' + machine_name + '\\"')
            if idx == -1:
                idx = games_body.find('"name":"' + machine_name + '"')

            if idx > -1:
                s_idx = games_body.find("variable_width_logo", idx, idx + 5000)
                if s_idx > -1:
                    http_start = games_body.find("http", s_idx, s_idx + 100)
                    if http_start > -1:
                        logo_url = extract_until_quote(games_body, http_start)

        scores = get_high_scores(auth, m.get("id"))

        banner_child = None
        if logo_url.startswith("https://stern-wagtail-1.s3.amazonaws.com/"):
            logo_rep = http.get(logo_url, ttl_seconds = 3600)
            if logo_rep.status_code == 200:
                banner_child = render.Image(src = logo_rep.body(), width = canvas.width())

        if not banner_child:
            banner_child = render.Text(machine_name, font = FONT, color = "#ff0")

        # Machine title banner
        all_content.append(banner_child)

        if not scores:
            all_content.append(render.Text("No scores yet", font = SMALL_FONT))
        else:
            for i, s in enumerate(scores):
                if type(s) != "dict":
                    continue
                user = s.get("user") or {}
                user = user if type(user) == "dict" else {}
                player = str(user.get("username") or user.get("name") or user.get("initials") or "UNK")[:10]
                score_val = number(s.get("score"))
                rank = "GC" if i == 0 else str(i)

                # Colors based on rank
                rank_color = "#fff"
                if i == 0:
                    rank_color = "#f0f"
                elif i == 1:
                    rank_color = "#f00"
                elif i == 2:
                    rank_color = "#f80"

                all_content.append(
                    render.Row(
                        children = [
                            render.Text("%s: " % rank, font = FONT, color = rank_color),
                            render.Text(player, font = FONT, color = "#fff"),
                        ],
                    ),
                )
                all_content.append(
                    render.Padding(
                        pad = (4 * SCALE, 0, 0, 6 * SCALE),
                        child = render.Text(format_score(score_val), font = FONT, color = "#0ff"),
                    ),
                )

        # Add spacing between machines
        all_content.append(render.Box(width = canvas.width(), height = 6 * SCALE, color = "#000"))

    # If no content, just skip
    if not all_content:
        return render.Root(child = render.WrappedText("No scores found.", font = FONT))

    return render.Root(
        delay = 80 // SCALE,
        child = render.Marquee(
            height = canvas.height(),
            scroll_direction = "vertical",
            child = render.Column(children = all_content),
        ),
    )

def number(value):
    if type(value) in ["int", "float"] and value >= 0:
        return int(value)
    if type(value) == "string" and len(value) <= 24 and value.isdigit():
        return int(value)
    return 0

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Stern Username",
                desc = "Your Stern Insider Connected username",
                icon = "user",
            ),
            schema.Text(
                id = "password",
                name = "Stern Password",
                desc = "Your Stern Insider Connected password",
                icon = "lock",
                secret = True,
            ),
            schema.Text(
                id = "game_filter",
                name = "Game Filter (Optional)",
                desc = "Filter to a specific game by name or model",
                icon = "magnifyingGlass",
            ),
        ],
    )
