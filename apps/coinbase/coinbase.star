"""
Applet: Coinbase
Summary: Coinbase Balance Tracker
Description: Displays your current Coinbase holdings and balances.
Author: harrywynn
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/coinbase_logo.png", COINBASE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

COINBASE_LOGO = COINBASE_LOGO_ASSET.readall()

COINBASE_CLIENT_SECRET = secret.decrypt("AV6+xWcEIOP/Rql2nyueyFjL9f51E2W1wDvcqtKyvXWRuSZwf7pNagbGLNridKAHG4Nw4oW2FZssbHNfsGwWAmSqXG3VN8oSvw0UY+4AB2LU3HMl5eEN9A139V08wU3/vOX7ouCUtHWwNkhHRngkQHqQiZSTK0KNOYTaIO9aeb7uzFwLdMdATDEQ2ypUjrvOt4l8UM1HIpXaIjn8T5bE+q7AYgaLww==")
COINBASE_CLIENT_ID = secret.decrypt("AV6+xWcEVIfI5lKs4wUCRh+CyWiA2VJ8Jngv8g/klexY7x7qR4KGIopsbZOIq/syABtfSToDA/nx5J8Mhy+XakIUjxESmr3V9fKOeymlJd7G/0VImVbAJYoZoTU2PMgzHcr7+HUV3SVUGrmZk62eMH5y77pWPb6MXIeLXAwTYFL6ZBk3NQCkP6EIN0dOP9h+ubvvBWMLE1U3Imc9ZdqxC4XPEQmPPg==")

def main(config):
    if config.get("token") == None:
        return render.Root(
            child = render.Text("Please login"),
        )

    auth_token = config.get("token")

    # load exchange rates
    # get current exchange rates
    res = http.get("https://api.coinbase.com/v2/exchange-rates", ttl_seconds = 900)

    if res.status_code != 200 or len(res.body()) > 1048576:
        return render.Root(
            child = render.Text("Rates unavailable!"),
        )
    rates_data = res.json()
    rate_container = rates_data.get("data", {}) if type(rates_data) == "dict" else {}
    rates = rate_container.get("rates", {}) if type(rate_container) == "dict" else {}
    if type(rates) != "dict":
        return render.Root(child = render.Text("Rates unavailable!"))

    # load account balances
    res = http.get("https://api.coinbase.com/api/v3/brokerage/accounts?limit=250", headers = {
        "Authorization": "Bearer " + auth_token,
    })

    if res.status_code != 200 or len(res.body()) > 2097152:
        return render.Root(
            child = render.Text("Accounts unavailable!"),
        )
    accounts_data = res.json()
    accounts = accounts_data.get("accounts", []) if type(accounts_data) == "dict" else []

    if type(accounts) != "list":
        return render.Root(
            child = render.Text("Accounts unavailable!"),
        )

    # for display
    currencies = []
    balance = 0.0

    # match account balances to rates
    for x in accounts[:250]:
        if type(x) != "dict" or type(x.get("available_balance")) != "dict":
            continue
        currency = x.get("currency")
        if currency not in rates:
            continue
        available = float(x["available_balance"].get("value", "0"))

        # only count if we have a balance
        if available > 0.0:
            balance += available / float(rates[currency])
            currencies.append(currency)

    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 3),
                            child = render.Text(
                                content = ("$" + humanize.ftoa(num = balance, digits = 2)),
                                font = "6x13",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = COINBASE_LOGO, width = 9),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Marquee(
                                width = 52,
                                align = "center",
                                child = render.Text(
                                    content = " | ".join(currencies),
                                    font = "tom-thumb",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def oauth_handler(params):
    params = json.decode(params)

    params["client_secret"] = COINBASE_CLIENT_SECRET or "fake-client-secret"

    res = http.post("https://login.coinbase.com/oauth2/token", params = params)

    if res.status_code != 200:
        fail("token request failed with status code: %d" % res.status_code)

    body = res.body()
    if len(body) > 65536:
        fail("token response is too large")
    token_data = res.json()
    if type(token_data) != "dict" or not token_data.get("access_token"):
        fail("token response is invalid")
    return token_data["access_token"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "token",
                name = "Coinbase Account",
                desc = "",
                icon = "",
                handler = oauth_handler,
                client_id = COINBASE_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://login.coinbase.com/oauth2/auth",
                scopes = [
                    "wallet:accounts:read",
                ],
            ),
        ],
    )
