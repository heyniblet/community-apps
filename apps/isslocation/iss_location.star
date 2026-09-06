"""
Applet: ISS Location
Summary: Current ISS city/country 
Description: Current city/country/ocean the ISS is flying over.
Author: carmineguida
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://api.wheretheiss.at/v1/satellites/25544"
GEO_URL = "https://secure.geonames.org/findNearbyPlaceNameJSON"
OCEAN_URL = "https://secure.geonames.org/oceanJSON"
FONT = "tom-thumb"
LOC_FONT = "tb-8"

################################################################################

def get_geo_info(geonames):
    city = ""
    country = ""
    adminName1 = ""
    countryCode = ""
    for g in geonames:
        if type(g) != "dict":
            continue
        if "countryCode" in g:
            countryCode = g["countryCode"]
        if "countryName" in g:
            country = g["countryName"]
        if "name" in g:
            city = g["name"]
        if "adminName1" in g:
            adminName1 = g["adminName1"]

    if (countryCode == "US"):
        country = adminName1

    return (str(city)[:100], str(country)[:100])

################################################################################

def get_lat_lon():
    rep = http.get(API_URL)
    if (rep.status_code != 200):
        return None
    data = rep.json()
    if type(data) != "dict" or type(data.get("latitude")) not in ["int", "float"] or type(data.get("longitude")) not in ["int", "float"]:
        return None
    lat = str(data.get("latitude"))
    lon = str(data.get("longitude"))

    if (len(lat) > 7):
        lat = lat[:7]
    if (len(lon) > 7):
        lon = lon[:7]

    return (lat, lon)

################################################################################

def get_ocean(api_key, lat, lon):
    country = ""
    rep = http.get(OCEAN_URL, params = {"username": api_key, "lat": lat, "lng": lon})
    if (rep.status_code != 200):
        return ("unknown location", country, "#444444")

    data = rep.json()
    ocean = data.get("ocean") if type(data) == "dict" else None
    if type(ocean) != "dict":
        city = "unknown location"
        color = "#444444"
    else:
        city = str(ocean.get("name") or "unknown location")[:100]
        color = "#33A2FF"

    return (city, country, color)

################################################################################

def get_iss_dict(api_key):
    position = get_lat_lon()
    if position == None:
        return None
    (lat, lon) = position

    rep = http.get(GEO_URL, params = {"username": api_key, "lat": lat, "lng": lon})
    if (rep.status_code != 200):
        return None

    data = rep.json()
    geonames = data.get("geonames") if type(data) == "dict" else None
    if type(geonames) != "list":
        return None
    geonames = geonames[:10]

    if len(geonames) == 0:
        (city, country, color) = get_ocean(api_key, lat, lon)
    else:
        (city, country) = get_geo_info(geonames)
        color = "#E29315"

    iss_dict = {"lat": lat, "lon": lon, "city": city, "country": country, "color": color}
    return iss_dict

################################################################################

def main(config):
    api_key = config.get("api_key")
    if type(api_key) != "string" or not api_key or len(api_key) > 128:
        return render.Root(child = render.Text("Need api_key."))

    iss_dict = get_iss_dict(api_key)
    if iss_dict == None:
        return render.Root(child = render.WrappedText("ISS location unavailable", width = 64, align = "center"))

    content = iss_dict["city"] + " " + iss_dict["country"]
    content = content.strip()

    render_iss = render.Box(color = "#2D38BF", padding = 1, width = 15, height = 11, child = render.Text("ISS", font = "5x8", color = "#000000"))
    render_lat_lon = render.Column(children = [
        render.Text("Lat:%s" % iss_dict["lat"], font = FONT, color = "#888888"),
        render.Text("Lon:%s" % iss_dict["lon"], font = FONT, color = "#888888"),
    ])
    render_top = render.Padding(pad = (1, 1, 1, 0), child = render.Row(children = [render_iss, render.Box(color = "#000000", width = 1, height = 11), render_lat_lon]))
    render_sep = render.Box(color = "#222222", width = 64, height = 1)
    render_loc = render.Padding(pad = (1, 0, 1, 1), child = render.WrappedText(content = content, font = LOC_FONT, color = iss_dict["color"]))

    return render.Root(child = render.Column(children = [render_top, render_sep, render_loc]))

################################################################################

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Geonames API Key",
                desc = "GeoNames username enabled for free web services (geonames.org).",
                icon = "key",
                secret = True,
            ),
        ],
    )
