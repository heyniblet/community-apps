load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BACKGROUND_COLOR = "#638475"
ERROR_BACKGROUND_COLOR = "#540B0E"
API_KEY = "api_key"

def render_error_message(message):
    return render.Root(
        render.Box(
            color = ERROR_BACKGROUND_COLOR,
            child = render.Column(children = [
                render.Text(content = "Error", font = "6x13"),
                render.Marquee(child = render.Text(content = message), align = "center", width = 50),
            ]),
        ),
    )

def render_sales(count, total):
    return render.Root(
        render.Box(
            color = BACKGROUND_COLOR,
            child = render.Column(children = [
                render.Text(content = "Sales Today", color = "#FFFECB"),
                render.Text(content = total, font = "6x13"),
                render.Text(content = "{} orders".format(count)),
            ]),
        ),
    )

def get_beginning_of_today():
    now = time.now()

    year = now.year
    month = now.month
    day = now.day

    return time.time(year = year, month = month, day = day, hour = 0)

def get_total(charges):
    total = 0

    for charge in charges[:100]:
        amount = charge.get("amount") if type(charge) == "dict" else None
        if type(amount) == "int" and amount >= 0 and charge.get("paid") != False:
            total = total + amount

    return total // 100

def stripe_api(endpoint, params, api_key):
    url = "https://api.stripe.com/v1/{}".format(endpoint)

    headers = {"Content-Type": "application/json", "Authorization": "Bearer {}".format(api_key)}

    response = http.get(url = url, headers = headers, params = params)
    body = response.body()
    return json.decode(body, {}) if response.status_code == 200 and body and len(body) <= 256 * 1024 else {}

def get_charges(api_key):
    beginning_of_today = get_beginning_of_today().unix

    query = "status:\"succeeded\" AND created >= {}".format(beginning_of_today)

    res = stripe_api(endpoint = "charges/search", params = {"limit": "100", "query": query}, api_key = api_key)

    return res

def get_sales(api_key):
    res = get_charges(api_key)

    data = res.get("data") if type(res) == "dict" else None

    if type(data) == "list":
        total = get_total(data)
        return {"total": "$" + humanize.comma(total), "count": len(data)}

    return {"error": "Stripe data unavailable"}

def get_content(api_key):
    return get_sales(api_key)

def main(config):
    api_key = config.get(API_KEY)

    if type(api_key) != "string" or len(api_key) < 8 or len(api_key) > 256 or any([c in api_key for c in [" ", "\t", "\r", "\n"]]):
        return render_error_message("API Key required.")

    content = get_content(api_key)

    error = content.get("error")

    if error:
        return render_error_message(error)

    total = content.get("total")
    count = content.get("count")

    return render_sales(count = count, total = total)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = API_KEY,
                name = "API Key",
                desc = "Your Stripe secret key",
                icon = "user",
                secret = True,
            ),
        ],
    )
