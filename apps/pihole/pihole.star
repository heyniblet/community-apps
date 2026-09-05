"""
Applet: PiHole
Summary: PiHole stats for Tidbyt
Description: Display Pi-hole blocking statistics on Tidbyt.
Author: siva801
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/pihole_logo.png", PIHOLE_LOGO_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

PIHOLE_LOGO = PIHOLE_LOGO_ASSET.readall()

HOST = ""
API_KEY = ""
VERSION = "v5"
GREEN = "#00cc00"
RED = "#ff4136"

TTL_SECONDS = 60
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_PLOT_POINTS = 288

version_options = [
    schema.Option(
        display = "V5",
        value = "v5",
    ),
    schema.Option(
        display = "V6",
        value = "v6",
    ),
]

def response_json(resp):
    body = resp.body()
    if resp.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        print("Pi-hole request failed with status %d" % resp.status_code)
        return None
    payload = resp.json()
    return payload if type(payload) == "dict" else None

def normalize_host(value):
    value = value.strip().rstrip("/")
    if not value.startswith("https://") or len(value) > 512 or "@" in value or "?" in value or "#" in value:
        return None
    return value

def get_pihole_stats(endpoint, api_key, ttl):
    resp = http.get("%s/admin/api.php" % endpoint, params = {"summaryRaw": "", "auth": api_key}, ttl_seconds = ttl)
    summary = response_json(resp)

    resp = http.get("%s/admin/api.php" % endpoint, params = {"overTimeData10mins": "", "auth": api_key}, ttl_seconds = ttl)
    plot_data = response_json(resp)
    return summary, plot_data

def get_pihole_v6_stats(endpoint, api_key, ttl):
    resp = http.post("%s/api/auth" % endpoint, json_body = {"password": api_key})
    auth = response_json(resp)
    session = auth.get("session") if auth else None
    sid = session.get("sid") if type(session) == "dict" else None
    if not sid:
        return None, None
    headers = {"X-FTL-SID": sid}

    resp = http.get("%s/api/stats/summary" % endpoint, headers = headers, ttl_seconds = ttl)
    summary = response_json(resp)

    resp = http.get("%s/api/history" % endpoint, headers = headers, ttl_seconds = ttl)
    plot_data = response_json(resp)
    http.delete("%s/api/auth" % endpoint, headers = headers)
    return summary, plot_data

def main(config):
    host = config.str("host", HOST)
    api_key = config.str("api_key", API_KEY)
    version = config.str("version", VERSION)
    ttl_value = str(config.get("ttl", TTL_SECONDS))
    ttl = int(ttl_value) if re.match(r"^\d{1,4}$", ttl_value) else TTL_SECONDS
    ttl = max(30, min(3600, ttl))

    total_queries = 0
    total_ads = 0
    query_plot = []
    ad_plot = []

    if not host or not api_key:
        return render.Root(
            render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Padding(
                        pad = (2, 1, 1, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Column(
                                    children = [
                                        render.Image(PIHOLE_LOGO, width = 10),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text("Add Host", color = RED),
                                        render.Text("Add Key", color = RED),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

    else:
        host = normalize_host(host)
        if not host or version not in ["v5", "v6"]:
            return render.Root(child = render.WrappedText("Use a public HTTPS Pi-hole URL", color = RED, align = "center"))
        summary, plot_data = get_pihole_stats(host, api_key, ttl) if version == "v5" else get_pihole_v6_stats(host, api_key, ttl)

        if not summary or not plot_data:
            return render.Root(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text("Error! Check APP config.", color = RED),
                        ),
                    ],
                ),
            )

        queries = summary.get("queries") if version == "v6" else None
        if version == "v6" and type(queries) != "dict":
            return render.Root(child = render.WrappedText("Invalid Pi-hole data", color = RED, align = "center"))
        total_queries = summary.get("dns_queries_today") if version == "v5" else queries.get("total")
        total_ads = summary.get("ads_blocked_today") if version == "v5" else queries.get("blocked")
        ads_percentage = summary.get("ads_percentage_today") if version == "v5" else queries.get("percent_blocked")
        if type(total_queries) not in ["int", "float"] or type(total_ads) not in ["int", "float"] or type(ads_percentage) not in ["int", "float"]:
            return render.Root(child = render.WrappedText("Invalid Pi-hole data", color = RED, align = "center"))

        if version == "v5":
            domains_over_time = plot_data.get("domains_over_time")
            ads_over_time = plot_data.get("ads_over_time")
            if type(domains_over_time) != "dict" or type(ads_over_time) != "dict":
                return render.Root(child = render.WrappedText("Invalid Pi-hole history", color = RED, align = "center"))
            query_plot_time_buckets = sorted(domains_over_time.keys())[-MAX_PLOT_POINTS:]
            for idx, time_bucket in enumerate(query_plot_time_buckets):
                if idx >= len(query_plot):
                    query_plot.append(domains_over_time[time_bucket])
                else:
                    query_plot[idx] = domains_over_time[time_bucket]
            ad_plot_time_buckets = sorted(ads_over_time.keys())[-MAX_PLOT_POINTS:]
            for idx, time_bucket in enumerate(ad_plot_time_buckets):
                if idx >= len(ad_plot):
                    ad_plot.append(ads_over_time[time_bucket])
                else:
                    ad_plot[idx] = ads_over_time[time_bucket]
        else:
            history = plot_data.get("history")
            if type(history) != "list":
                return render.Root(child = render.WrappedText("Invalid Pi-hole history", color = RED, align = "center"))
            query_plot = [x.get("total", 0) for x in history[-MAX_PLOT_POINTS:] if type(x) == "dict"]
            ad_plot = [x.get("blocked", 0) for x in history[-MAX_PLOT_POINTS:] if type(x) == "dict"]

        query_plot = [value for value in query_plot if type(value) in ["int", "float"]] or [0]
        ad_plot = [value for value in ad_plot if type(value) in ["int", "float"]] or [0]

        return render.Root(
            render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Padding(
                        pad = (2, 1, 1, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Column(
                                    children = [
                                        render.Image(PIHOLE_LOGO, width = 10),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text(humanize.comma(int(total_queries))),
                                        render.Row(
                                            children = [
                                                render.Text(humanize.comma(int(total_ads)), color = RED),
                                                render.Text(" (" + humanize.ftoa(ads_percentage, 0) + "%)", color = RED),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Row(
                        expanded = True,
                        children = [
                            render.Stack(
                                children = [
                                    render.Plot(
                                        data = list(enumerate(query_plot)),
                                        width = 64,
                                        height = 14,
                                        color = GREEN,
                                        fill = True,
                                        y_lim = (0, max(1, max(query_plot))),
                                    ),
                                    render.Plot(
                                        data = list(enumerate(ad_plot)),
                                        width = 64,
                                        height = 14,
                                        color = RED,
                                        fill = True,
                                        fill_color = "#660500",
                                        y_lim = (0, max(1, max(ad_plot))),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "host",
                name = "Host",
                desc = "Public HTTPS URL for your Pi-hole reverse proxy",
                icon = "computer",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key or App Password",
                desc = "Pi-hole v5 API key or v6 application password",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "version",
                name = "Version",
                desc = "Pi-hole Version",
                icon = "v",
                default = version_options[0].value,
                options = version_options,
            ),
            schema.Text(
                id = "ttl",
                name = "ttl",
                desc = "TTL For http cache",
                icon = "v",
                default = "60",
            ),
        ],
    )
