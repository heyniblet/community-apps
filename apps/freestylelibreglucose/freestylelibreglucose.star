"""
Freestyle Libre Glucose
Displays real-time glucose levels from Freestyle Libre via LibreLinkUp.
Shows current value, trend arrow, 4-hour history graph, and color-coded alerts.

Author: Bob (@Eserobe)
"""

load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ─── Configuración de la API ───────────────────────────────────────────────────

LLU_REGIONS = {
    "eu": "https://api-eu.libreview.io",
    "eu2": "https://api-eu2.libreview.io",
    "us": "https://api.libreview.io",
    "de": "https://api-de.libreview.io",
    "fr": "https://api-fr.libreview.io",
    "jp": "https://api-jp.libreview.io",
    "ap": "https://api-ap.libreview.io",
    "au": "https://api-au.libreview.io",
}

LLU_BASE_HEADERS = {
    "version": "4.17.0",
    "product": "llu.ios",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Connection": "keep-alive",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
}

# Flechas de tendencia del sensor
TREND_ARROWS = {
    1: "↓↓",  # caída rápida
    2: "↓",  # caída
    3: "→",  # estable
    4: "↑",  # subida
    5: "↑↑",  # subida rápida
}

# ─── Helpers ───────────────────────────────────────────────────────────────────

def auth_headers(token, account_id):
    return {
        "version": "4.17.0",
        "product": "llu.ios",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Connection": "keep-alive",
        "Pragma": "no-cache",
        "Cache-Control": "no-cache",
        "Authorization": "Bearer " + token,
        "account-id": account_id,
    }

def glucose_color(value, low, high):
    if value < low:
        return "#f44"  # rojo — hipoglucemia
    elif value > high:
        return "#fa0"  # naranja — hiperglucemia
    else:
        return "#0d0"  # verde — rango normal

def error_screen(msg):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                color = "#f44",
                width = 60,
                align = "center",
            ),
        ),
    )

def warning_screen(msg):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                color = "#fa0",
                width = 60,
                align = "center",
            ),
        ),
    )

# ─── Llamadas a la API ─────────────────────────────────────────────────────────

LLU_DEFAULT_URL = "https://api.libreview.io"

def llu_login(email, password, base_url):
    """
    Devuelve (token, account_id, url_final, error).
    El login siempre empieza en LLU_DEFAULT_URL y sigue el redirect al servidor regional.
    """
    body = json.encode({"email": email, "password": password})
    rep = http.post(base_url + "/llu/auth/login", headers = LLU_BASE_HEADERS, body = body)

    raw = rep.body()
    if rep.status_code != 200 or not raw or len(raw) > 256 * 1024:
        return None, None, base_url, "HTTP " + str(rep.status_code)

    data = json.decode(raw, {})
    if type(data) != "dict":
        return None, None, base_url, "Invalid response"
    status_value = data.get("status")
    if type(status_value) not in ["int", "float"] and (type(status_value) != "string" or not status_value.isdigit()):
        return None, None, base_url, "Invalid response"
    status = int(status_value)

    # Rate limit
    if status == 429:
        return None, None, base_url, "Rate limit (429)"

    # Redirect al servidor regional correcto (status == 2)
    if status == 2:
        outer = data.get("data", {})
        shard = (
            outer.get("region") or
            outer.get("shard") or
            data.get("region") or
            data.get("shard") or
            ""
        )
        redirect = outer.get("redirect", {})
        if not shard and type(redirect) == "dict":
            shard = redirect.get("region") or redirect.get("shard") or ""

        if not shard:
            # Sin región en la respuesta: probar el endpoint global como fallback
            fallback = "https://api.libreview.io"
            if base_url != fallback:
                return llu_login(email, password, fallback)
            return None, None, base_url, "No region: " + str(data)

        shard = str(shard).lower()
        if shard not in LLU_REGIONS:
            return None, None, base_url, "Unsupported region"
        new_url = LLU_REGIONS[shard]
        if new_url == base_url:
            return None, None, base_url, "Redirect loop: " + shard
        return llu_login(email, password, new_url)

    if status != 0:
        error = data.get("error", {})
        err_msg = error.get("message", "") if type(error) == "dict" else ""
        return None, None, base_url, "status=" + str(status) + " " + str(err_msg)[:120]

    inner = data.get("data", {})
    inner = inner if type(inner) == "dict" else {}
    ticket = inner.get("authTicket", {})
    ticket = ticket if type(ticket) == "dict" else {}
    token = ticket.get("token", "")
    user = inner.get("user") or {}
    user_id = user.get("id", "") if type(user) == "dict" else ""

    # account-id = SHA-256(user.id) — requerido por la API LibreLinkUp
    account_id = hash.sha256(user_id) if type(user_id) == "string" and user_id and len(user_id) <= 200 else ""

    if type(token) != "string" or not token or len(token) > 4096 or not account_id:
        return None, None, base_url, "Token vacío"

    return token, account_id, base_url, None

def llu_connections(token, account_id, base_url):
    rep = http.get(base_url + "/llu/connections", headers = auth_headers(token, account_id))
    if rep.status_code != 200:
        return None, "HTTP " + str(rep.status_code)
    body = rep.body()
    data = json.decode(body, {}) if body and len(body) <= 512 * 1024 else {}
    if type(data) != "dict":
        return None, "Invalid response"
    conns = data.get("data", [])
    return (conns[:100], None) if type(conns) == "list" else (None, "Invalid response")

def llu_graph(token, account_id, patient_id, base_url):
    if type(patient_id) != "string" or not re.match(r"^[A-Za-z0-9_-]{1,100}$", patient_id):
        return None, "Invalid patient"
    url = base_url + "/llu/connections/" + patient_id + "/graph"
    rep = http.get(url, headers = auth_headers(token, account_id))
    if rep.status_code != 200:
        return None, "HTTP " + str(rep.status_code)
    body = rep.body()
    data = json.decode(body, {}) if body and len(body) <= 1024 * 1024 else {}
    result = data.get("data", {}) if type(data) == "dict" else {}
    return (result, None) if type(result) == "dict" else (None, "Invalid response")

# ─── App principal ─────────────────────────────────────────────────────────────

def main(config):
    email = config.get("email", "")
    password = config.get("password", "")
    low_str = config.get("low_threshold", "70")
    high_str = config.get("high_threshold", "180")

    if type(email) != "string" or type(password) != "string" or not email or len(email) > 320 or not password or len(password) > 512:
        return warning_screen("Configura tu cuenta LibreLinkUp")

    low = int(low_str) if str(low_str).isdigit() and int(low_str) >= 20 and int(low_str) <= 400 else 70
    high = int(high_str) if str(high_str).isdigit() and int(high_str) >= 20 and int(high_str) <= 400 else 180
    if low >= high:
        low, high = 70, 180

    token, account_id, base_url, err = llu_login(email, password, LLU_DEFAULT_URL)
    if err != None:
        return error_screen("Login: " + err)

    # ── Conexiones (pacientes) ────────────────────────────────────────────────
    conns, err = llu_connections(token, account_id, base_url)
    if err != None:
        return error_screen("Conexión: " + err)
    if conns == None or len(conns) == 0:
        return warning_screen("Sin conexiones LibreLinkUp")

    conn = conns[0]
    if type(conn) != "dict":
        return error_screen("Conexión inválida")
    patient_id = conn.get("patientId", "")
    glucose_m = conn.get("glucoseMeasurement") or {}
    if type(glucose_m) != "dict" or type(glucose_m.get("Value")) not in ["int", "float"]:
        return error_screen("Lectura inválida")
    current = int(glucose_m.get("Value"))
    if current < 0 or current > 1000:
        return error_screen("Lectura inválida")
    trend = glucose_m.get("TrendArrow", 3)
    trend_id = int(trend) if type(trend) in ["int", "float"] else 3
    arrow = TREND_ARROWS.get(trend_id, "→")

    # Minutos desde la última lectura (para los cuadraditos)
    n_dots = 0
    ts_str = glucose_m.get("FactoryTimestamp", "") or glucose_m.get("Timestamp", "")
    if ts_str != "":
        t = None
        fmt = None
        if "/" in ts_str:
            if "AM" in ts_str or "PM" in ts_str:
                fmt = "1/2/2006 3:04:05 PM"
            else:
                fmt = "1/2/2006 15:04:05"
        elif "T" in ts_str:
            if ts_str.endswith("Z"):
                fmt = "2006-01-02T15:04:05Z"
            else:
                fmt = "2006-01-02T15:04:05"

        if fmt:
            parsed = time.parse_time(ts_str, format = fmt, location = "UTC")
            if parsed != None and str(parsed) != "0001-01-01 00:00:00 +0000 UTC":
                t = parsed
        if t != None:
            diff = time.now() - t
            n_dots = int(diff.seconds) // 60  # diff.minutes no funciona en Pixlet
            if n_dots < 0:
                n_dots = 0
            if n_dots > 9:
                n_dots = 9

    dot_widgets = []
    for i in range(n_dots):
        if i > 0:
            dot_widgets.append(render.Box(width = 1, height = 2))
        dot_widgets.append(render.Box(width = 2, height = 2, color = "#888"))

    # ── Datos históricos para la gráfica ─────────────────────────────────────
    graph_data, _ = llu_graph(token, account_id, patient_id, base_url)
    raw_history = []
    if graph_data != None:
        raw_history = graph_data.get("graphData", [])
        if type(raw_history) != "list":
            raw_history = []

    # Ventana fija de 4h (240 min). x = minutos desde "hace 4h" hasta "ahora"
    start = len(raw_history) - 48 if len(raw_history) > 48 else 0
    points = [point for point in raw_history[start:] if type(point) == "dict" and type(point.get("Value")) in ["int", "float"] and point.get("Value") >= 0 and point.get("Value") <= 1000]
    n_pts = len(points)

    plot_data = []
    for i, pt in enumerate(points):
        minutes = 240.0 - float(n_pts - 1 - i) * 5.0
        plot_data.append((minutes, float(pt.get("Value", current))))

    if len(plot_data) < 2:
        plot_data = [(235.0, float(current)), (240.0, float(current))]

    color = glucose_color(current, low, high)

    # ── Gráfica con color por zona y separadores horarios ────────────────────
    low_f = float(low)
    high_f = float(high)

    data_low = [pt for pt in plot_data if pt[1] < low_f]
    data_normal = [pt for pt in plot_data if pt[1] >= low_f and pt[1] <= high_f]
    data_high = [pt for pt in plot_data if pt[1] > high_f]

    plot_layers = []
    if len(data_low) >= 2:
        plot_layers.append(render.Plot(
            data = data_low,
            color = "#f44",
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(data_normal) >= 2:
        plot_layers.append(render.Plot(
            data = data_normal,
            color = color,
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(data_high) >= 2:
        plot_layers.append(render.Plot(
            data = data_high,
            color = "#fa0",
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(plot_layers) == 0:
        plot_layers = [render.Plot(
            data = plot_data,
            color = color,
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        )]

    sep_row = render.Row(
        children = [
            render.Box(width = 16, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
            render.Box(width = 14, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
            render.Box(width = 15, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
        ],
    )

    graph_widget = render.Stack(children = plot_layers + [sep_row])

    # Marco de 1px con dimensiones fijas 64×32
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = color,
            padding = 1,
            child = render.Stack(
                children = [
                    render.Box(
                        width = 62,
                        height = 30,
                        color = "#000",
                    ),
                    render.Column(
                        children = [
                            render.Box(
                                width = 62,
                                height = 13,
                                child = render.Row(
                                    cross_align = "center",
                                    children = [
                                        render.Box(width = 2),
                                        render.Text(
                                            content = str(current),
                                            font = "6x13",
                                            color = color,
                                        ),
                                        render.Box(width = 2),
                                        render.Text(
                                            content = arrow,
                                            font = "tb-8",
                                            color = color,
                                        ),
                                        render.Box(width = 3),
                                    ] + dot_widgets,
                                ),
                            ),
                            graph_widget,
                        ],
                    ),
                ],
            ),
        ),
        max_age = 300,
    )

# ─── Esquema de configuración ──────────────────────────────────────────────────

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "email",
                name = "Email LibreLinkUp",
                desc = "Correo de tu cuenta LibreLinkUp",
                icon = "envelope",
                secret = True,
            ),
            schema.Text(
                id = "password",
                name = "Contraseña LibreLinkUp",
                desc = "Contraseña de tu cuenta LibreLinkUp",
                icon = "lock",
                secret = True,
            ),
            schema.Text(
                id = "low_threshold",
                name = "Umbral bajo (mg/dL)",
                desc = "Por debajo se muestra en rojo. Por defecto: 70",
                icon = "exclamation",
                default = "70",
            ),
            schema.Text(
                id = "high_threshold",
                name = "Umbral alto (mg/dL)",
                desc = "Por encima se muestra en naranja. Por defecto: 180",
                icon = "exclamation",
                default = "180",
            ),
        ],
    )
