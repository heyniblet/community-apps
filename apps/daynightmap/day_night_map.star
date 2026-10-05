# Modified in this community-maintained version; see Git history for contributors.
# Original author and license notices are retained below.

"""
Applet: Day Night Map
Summary: Day & Night World Map
Description: A map of the Earth showing the day and the night. The map is based on Equirectangular (0°) by Tobias Jung (CC BY-SA 4.0).
Author: Henry So, Jr.
"""

# Day & Night World Map
# Version 1.1.0
#
# Copyright (c) 2022 Henry So, Jr.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# See comments in the code for further attribution

load("encoding/json.star", "json")
load("images/am.png", AM_ASSET = "file")
load("images/char_0.png", CHAR_0_ASSET = "file")
load("images/char_1.png", CHAR_1_ASSET = "file")
load("images/char_2.png", CHAR_2_ASSET = "file")
load("images/char_3.png", CHAR_3_ASSET = "file")
load("images/char_4.png", CHAR_4_ASSET = "file")
load("images/char_5.png", CHAR_5_ASSET = "file")
load("images/char_6.png", CHAR_6_ASSET = "file")
load("images/char_7.png", CHAR_7_ASSET = "file")
load("images/char_8.png", CHAR_8_ASSET = "file")
load("images/char_9.png", CHAR_9_ASSET = "file")
load("images/colon.png", COLON_ASSET = "file")
load("images/map.png", MAP_ASSET = "file")
load("images/pixel.png", PIXEL_ASSET = "file")
load("images/pm.png", PM_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAP = MAP_ASSET.readall()
PIXEL = PIXEL_ASSET.readall()

WIDTH = 64
HALF_W = WIDTH // 2
HEIGHT = 32
HALF_H = HEIGHT // 2
HDIV = 360 / WIDTH
HALF_HDIV = HDIV / 2
COEF = 360 / 365.24
DATE_H = 7

CHAR_W = 9
SEP_W = 3

def main(config):
    location = config.get("location")

    #print(location)
    location = json.decode(location) if location else {}
    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")
    show_date = config.bool("show_date")

    tz = location.get(
        "timezone",
        time.tz(),
    )

    tm = config.get("force_time")
    if tm:
        tm = time.parse_time(tm).in_location(tz)
    else:
        tm = time.now().in_location(tz)

    if config.bool("center_location"):
        map_offset = -round(float(location.get("lng", "0")) * HALF_W / 180)
    else:
        map_offset = 0

    #print(map_offset)

    formatted_date = tm.format("Mon 2 Jan 2006")
    date_shadow = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Text(
                content = formatted_date,
                font = "tom-thumb",
                color = "#000",
            ),
        ],
    )

    night_above, sunrise = sunrise_plot(tm)
    return render.Root(
        delay = 1000,
        child = render.Stack([
            render.Padding(
                pad = (map_offset, 0, 0, 0),
                child = render.Image(MAP),
            ),
            render.Padding(
                pad = (
                    map_offset + (-WIDTH if map_offset > 0 else WIDTH),
                    0,
                    0,
                    0,
                ),
                child = render.Image(MAP),
            ) if map_offset != 0 else None,
            render.Row([
                render.Padding(
                    pad = (0, y if night_above else 0, 0, 0),
                    child = render.Image(
                        src = PIXEL,
                        width = 1,
                        height = HEIGHT - y if night_above else y,
                    ),
                )
                for i in range(WIDTH)
                for y in [sunrise[(i - map_offset) % WIDTH]]
            ]),
            render.Column(
                main_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Animation([
                                render_time(tm, time_format[0]),
                                render_time(tm, time_format[1]) if blink_time else None,
                            ]),
                            render.Padding(
                                pad = (1, 9, 0, 0),
                                child = render.Image(AM_PM[tm.hour < 12]),
                            ) if time_format[2] else None,
                        ],
                    ),
                    render.Box(
                        width = WIDTH,
                        height = 3,
                    ) if show_date else None,
                ],
            ) if time_format else None,
            render.Padding(
                pad = (0, HEIGHT - DATE_H, 0, 0),
                child = render.Stack([
                    render.Padding(
                        pad = (-1, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (2, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 0, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 1, 0, 0),
                        child = render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = formatted_date,
                                    font = "tom-thumb",
                                    color = "#ff0",
                                ),
                            ],
                        ),
                    ),
                ]),
            ) if show_date else None,
        ]),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the display of date/time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "center_location",
                name = "Center On Location",
                desc = "Whether to center the map on the location.",
                icon = "compress",
                default = False,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "omit",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in TIME_FORMATS
                ],
            ),
            schema.Toggle(
                id = "blink_time",
                name = "Blinking Time Separator",
                desc = "Whether to blink the colon between hours and minutes.",
                icon = "asterisk",
                default = False,
            ),
            schema.Toggle(
                id = "show_date",
                name = "Date Overlay",
                desc = "Whether the date overlay should be shown.",
                icon = "calendarCheck",
                default = False,
            ),
        ],
    )

def sunrise_plot(tm):
    tm = tm.in_location("UTC")
    anchor = time.time(
        year = tm.year,
        month = 1,
        day = 1,
        location = "UTC",
    )
    days = int((tm - anchor).hours // 24)

    tan_dec = TAN_DEC[days]
    tau = 15 * (tm.hour + tm.minute / 60) - 180

    # Use the sunrise equation to compute the latitude
    # See https://en.wikipedia.org/wiki/Position_of_the_Sun
    def lat(lon):
        return atan(-cos(lon + tau) / tan_dec)

    return (
        tan_dec > 0,
        [
            HALF_H - round(lat(lon) * HALF_H / 90)
            #lat(lon)
            for lon in LONGITUDES
        ],
    )

def sin(degrees):
    return math.sin(math.radians(degrees))

def cos(degrees):
    return math.cos(math.radians(degrees))

def tan(degrees):
    return math.tan(math.radians(degrees))

def asin(x):
    return math.degrees(math.asin(x))

def atan(x):
    return math.degrees(math.atan(x))

def round(x):
    return int(math.round(x))

def render_time(tm, format):
    formatted_time = tm.format(format)
    offset = 5 - len(formatted_time)
    offset_pad = pad_of(offset)
    return render.Stack([
        render.Padding(
            pad = (pad_of(i + offset) - offset_pad, 0, 0, 0),
            child = render.Image(CHARS[c]),
        )
        for i, c in enumerate(formatted_time.elems())
        if c != " "
    ])

def pad_of(i):
    if i > 2:
        return (i - 1) * CHAR_W + SEP_W
    elif i > 0:
        return i * CHAR_W
    else:
        return 0

# Pre-computed tangent to the declination of the sun, one entry per day of the
# year. See https://en.wikipedia.org/wiki/Position_of_the_Sun
# Niblet: this used to be computed with trigonometry at module load on every
# render; it is now a constant table holding the exact same float values,
# generated from (for d in range(366)):
#     tan(asin(sin(-23.44) * cos(
#         COEF * (d + 10) +
#         (360 / math.pi * 0.0167 * sin(COEF * (d - 2))),
#     )))
TAN_DEC = [
    -0.42609653840697087,
    -0.42447403443370135,
    -0.4226963244074535,
    -0.42076486879563973,
    -0.41868124590980843,
    -0.416447147371882,
    -0.4140643733186288,
    -0.41153482737140107,
    -0.40886051139895047,
    -0.40604352010166106,
    -0.4030860354458364,
    -0.3999903209767344,
    -0.3967587160388795,
    -0.393393629931801,
    -0.3898975360287639,
    -0.38627296588529103,
    -0.3825225033633357,
    -0.37864877879586717,
    -0.3746544632154076,
    -0.37054226266871426,
    -0.36631491263834953,
    -0.36197517259037604,
    -0.3575258206658171,
    -0.35296964853191537,
    -0.3483094564075657,
    -0.34354804827565255,
    -0.3386882272933754,
    -0.3337327914100176,
    -0.32868452920003777,
    -0.32354621591780897,
    -0.3183206097788578,
    -0.31301044847103326,
    -0.3076184458976883,
    -0.3021472891536972,
    -0.29659963573394493,
    -0.29097811097283094,
    -0.2852853057123266,
    -0.2795237741952086,
    -0.27369603217926475,
    -0.26780455526753716,
    -0.2618517774490166,
    -0.2558400898436445,
    -0.24977183964499627,
    -0.24364932925362362,
    -0.23747481559370354,
    -0.23125050960539628,
    -0.2249785759051173,
    -0.21866113260581038,
    -0.21230025128923566,
    -0.20589795712227257,
    -0.19945622910926464,
    -0.19297700047250907,
    -0.1864621591531028,
    -0.17991354842450072,
    -0.17333296761131456,
    -0.16672217290607833,
    -0.16008287827692416,
    -0.15341675645934727,
    -0.14672544002548815,
    -0.1400105225246179,
    -0.1332735596887798,
    -0.12651607069781176,
    -0.1197395394982436,
    -0.11294541617084129,
    -0.10613511834183292,
    -0.09931003263312672,
    -0.09247151614708006,
    -0.085620897981642,
    -0.0787594807719271,
    -0.07188854225451907,
    -0.06500933685102295,
    -0.05812309726759601,
    -0.051231036107391076,
    -0.044334347493030384,
    -0.037434208696402814,
    -0.030531781773237482,
    -0.023628215200055723,
    -0.016724645511234374,
    -0.009822198934031244,
    -0.002921993019533471,
    0.0039748617324250925,
    0.010867260256251472,
    0.017754101313294697,
    0.024634285896024857,
    0.03150671564541027,
    0.03837029128319564,
    0.04522391106077114,
    0.05206646922632012,
    0.05889685451195308,
    0.0657139486425568,
    0.07251662486811929,
    0.07930374652135025,
    0.08607416560245795,
    0.09282672139302109,
    0.09956023910096701,
    0.10627352853874415,
    0.11296538283687894,
    0.11963457719519421,
    0.12627986767407698,
    0.13289999002829014,
    0.13949365858593135,
    0.14605956517526789,
    0.15259637810228321,
    0.15910274118189904,
    0.1655772728259496,
    0.17201856519110617,
    0.17842518339006178,
    0.1847956647693958,
    0.1911285182576451,
    0.19742222378720262,
    0.20367523179375088,
    0.20988596279701885,
    0.21605280706670893,
    0.22217412437749615,
    0.2282482438570298,
    0.2342734639308862,
    0.24024805236841057,
    0.24617024643336574,
    0.25203825314324513,
    0.25785024964103176,
    0.26360438368308214,
    0.26929877424666826,
    0.2749315122605501,
    0.2805006614617447,
    0.28600425938141844,
    0.29144031846256274,
    0.29680682731179175,
    0.3021017520872584,
    0.3073230380242925,
    0.3124686110999373,
    0.3175363798370916,
    0.32252423724845836,
    0.32743006291995275,
    0.33225172523264396,
    0.3369870837216791,
    0.34163399156999374,
    0.3461902982339229,
    0.35065385219711614,
    0.35502250384843015,
    0.3592941084787057,
    0.3634665293905733,
    0.3675376411146428,
    0.37150533272464664,
    0.375367511243317,
    0.3791221051300014,
    0.38276706784024894,
    0.38630038144686196,
    0.3897200603111809,
    0.39302415479270225,
    0.39621075498447994,
    0.39927799446118084,
    0.40222405402613526,
    0.40504716544326247,
    0.40774561513935154,
    0.41031774786188724,
    0.4127619702773601,
    0.4150767544948868,
    0.41726064149990894,
    0.41931224448281623,
    0.4212302520474837,
    0.42301343128499425,
    0.4246606306981789,
    0.42617078296309135,
    0.4275429075141128,
    0.42877611294006385,
    0.4298695991794876,
    0.4308226595041427,
    0.431634682280703,
    0.43230515250171864,
    0.43283365307800475,
    0.4332198658858064,
    0.43346357256334117,
    0.433564655052592,
    0.43352309588355664,
    0.4333389781994948,
    0.4330124855230781,
    0.4325439012647012,
    0.4319336079755562,
    0.43118208634940364,
    0.4302899139782521,
    0.4292577638684122,
    0.42808640272457427,
    0.4267766890106883,
    0.42532957079747447,
    0.42374608340736414,
    0.42202734686855975,
    0.42017456319068175,
    0.4181890134751762,
    0.4160720548742389,
    0.41382511741249806,
    0.411449700686088,
    0.40894737045401286,
    0.40631975513687785,
    0.40356854223813315,
    0.4006954747029494,
    0.39770234722971387,
    0.3945910025489274,
    0.39136332768397647,
    0.38802125020787825,
    0.3845667345096418,
    0.38100177808337043,
    0.37732840785265276,
    0.37354867654216173,
    0.3696646591077045,
    0.36567844923526543,
    0.36159215591883265,
    0.3574079001260577,
    0.3531278115600027,
    0.3487540255244652,
    0.34428867989957634,
    0.339733912233593,
    0.33509185695603844,
    0.33036464271658283,
    0.3255543898533338,
    0.32066320799348824,
    0.31569319378861255,
    0.31064642878617826,
    0.305524977438346,
    0.3003308852484164,
    0.295066177054819,
    0.2897328554519975,
    0.2843328993470832,
    0.27886826265081555,
    0.27334087310077965,
    0.26775263121467424,
    0.2621054093710157,
    0.25640105101439425,
    0.25064136998217945,
    0.24482814994933746,
    0.23896314398788412,
    0.23304807423732268,
    0.22708463168233814,
    0.22107447603391345,
    0.21501923570999407,
    0.20892050791178837,
    0.20277985879178526,
    0.19659882370959014,
    0.19037890757170303,
    0.18412158525141264,
    0.17782830208505607,
    0.17150047444095073,
    0.1651394903574151,
    0.15874671024637052,
    0.15232346765914945,
    0.1458710701112196,
    0.13939079996267498,
    0.1328839153514563,
    0.12635165117638378,
    0.11979522012722385,
    0.11321581375911952,
    0.10661460360885655,
    0.0999927423505458,
    0.09335136498842571,
    0.08669159008460811,
    0.0800145210196976,
    0.07332124728431634,
    0.06661284579967186,
    0.05989038226539207,
    0.053154912532937325,
    0.046407484002978096,
    0.039649137045183906,
    0.032880906438946846,
    0.026103822833590504,
    0.019318914226667948,
    0.01252720745896907,
    0.00572972972489502,
    -0.001072489903167613,
    -0.00787841893781621,
    -0.01468701992832218,
    -0.021497248902447395,
    -0.028308053799824744,
    -0.035118372898412326,
    -0.041927133235580616,
    -0.04873324902548412,
    -0.05553562007446125,
    -0.062333130196307485,
    -0.06912464562939781,
    -0.07590901345775397,
    -0.08268506003832002,
    -0.08945158943684473,
    -0.09620738187496637,
    -0.1029511921912661,
    -0.10968174831926154,
    -0.11639774978552579,
    -0.12309786623132758,
    -0.12978073596143613,
    -0.13644496452396498,
    -0.14308912332538867,
    -0.1497117482851188,
    -0.15631133853429993,
    -0.1628863551637501,
    -0.16943522002624875,
    -0.17595631459864824,
    -0.18244797890957165,
    -0.18890851053870572,
    -0.19533616369400464,
    -0.2017291483733415,
    -0.208085629617416,
    -0.21440372686095474,
    -0.22068151338945077,
    -0.22691701590889501,
    -0.23310821423610634,
    -0.23925304111742424,
    -0.24534938218361318,
    -0.2513950760489129,
    -0.2573879145621789,
    -0.26332564321804497,
    -0.2692059617359469,
    -0.27502652481473394,
    -0.28078494307037416,
    -0.28647878416401745,
    -0.2921055741273293,
    -0.2976627988916096,
    -0.30314790602671243,
    -0.3085583066952215,
    -0.31389137782666504,
    -0.3191444645158153,
    -0.32431488264829234,
    -0.32939992175574045,
    -0.334396848101865,
    -0.33930290799948054,
    -0.34411533135755734,
    -0.34883133545596823,
    -0.3534481289442824,
    -0.35796291605954966,
    -0.36237290105650527,
    -0.36667529284211214,
    -0.37086730980474136,
    -0.3749461848266983,
    -0.3789091704671393,
    -0.3827535443007917,
    -0.38647661439624054,
    -0.390075724915954,
    -0.3935482618186235,
    -0.39689165864291825,
    -0.4001034023503124,
    -0.4031810392033224,
    -0.40612218065428746,
    -0.40892450921875784,
    -0.4115857843066391,
    -0.41410384798350464,
    -0.41647663063393114,
    -0.4187021564983708,
    -0.4207785490549307,
    -0.422704036217533,
    -0.42447695532224783,
    -0.4260957578741626,
    -0.42755901402795604,
    -0.4288654167763978,
    -0.4300137858222772,
    -0.4310030711107888,
    -0.43183235600113473,
    -0.4325008600580564,
    -0.43300794144614074,
    -0.4333530989120624,
    -0.4335359733423822,
    -0.4335563488871099,
    -0.43341415364193536,
    -0.4331094598847919,
    -0.43264248386522774,
    -0.43201358514789084,
    -0.43122326551424106,
    -0.4302721674293807,
    -0.42916107208359033,
    -0.4278908970207609,
    -0.42646269336838993,
]

LONGITUDES = [
    (x - HALF_W) * HDIV + HALF_HDIV
    for x in range(WIDTH)
]

DEFAULT_TIMEZONE = "America/New_York"

TIME_FORMATS = {
    "omit": None,
    "12-hour": ("3:04", "3 04", True),
    "24-hour": ("15:04", "15 04", False),
}

CHARS = {
    "0": CHAR_0_ASSET.readall(),
    "1": CHAR_1_ASSET.readall(),
    "2": CHAR_2_ASSET.readall(),
    "3": CHAR_3_ASSET.readall(),
    "4": CHAR_4_ASSET.readall(),
    "5": CHAR_5_ASSET.readall(),
    "6": CHAR_6_ASSET.readall(),
    "7": CHAR_7_ASSET.readall(),
    "8": CHAR_8_ASSET.readall(),
    "9": CHAR_9_ASSET.readall(),
    ":": COLON_ASSET.readall(),
}

AM_PM = {
    True: AM_ASSET.readall(),
    False: PM_ASSET.readall(),
}

# The following Base64-encoded image is a scaled-down version of
# Equirectangular (0°) by Tobias Jung
# found at https://map-projections.net/single-view/rectang-0:flat-stf
# This image released under the CC BY-SA 4.0 International license
