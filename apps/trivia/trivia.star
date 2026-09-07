"""
Applet: Trivia
Summary: Random trivia question
Description: Displays a random trivia question with category and difficulty.
Author: Jack Sherbal
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

NUM_QUESTIONS = 20
JSERVICE = "https://opentdb.com/api.php?amount=%d&type=multiple&encode=base64" % NUM_QUESTIONS
CACHE_TTL_SECONDS = 15 * NUM_QUESTIONS
MAX_RESPONSE_BYTES = 512 * 1024

def get_data():
    cached_index = cache.get("question_index") or "0"
    question_index = int(cached_index) if cached_index.isdigit() else 0

    rep = http.get(JSERVICE, ttl_seconds = CACHE_TTL_SECONDS)
    body = rep.body()
    if rep.status_code != 200 or not body or len(body) > MAX_RESPONSE_BYTES:
        return None

    payload = json.decode(body, {})
    questions = payload.get("results", []) if type(payload) == "dict" and payload.get("response_code") == 0 else []
    if type(questions) != "list" or not questions:
        return None

    cache.set("question_index", str(question_index + 1), ttl_seconds = CACHE_TTL_SECONDS)
    question = questions[question_index % len(questions)]
    return question if type(question) == "dict" else None

def remove_chars(strr):
    return re.compile(r"<[^>]+>").sub("", strr)

def calc_delay(question, category):
    Q_LEN = len(question) + len(category)

    if Q_LEN < 30:
        return 15

    elif Q_LEN < 40:
        return 10

    elif Q_LEN < 50:
        return 5

    return 0

def main(config):
    body = get_data()
    required = ["difficulty", "question", "correct_answer", "category"]
    if body == None or any([type(body.get(key)) != "string" for key in required]):
        return render.Root(child = render.WrappedText(content = "Trivia is temporarily unavailable"), max_age = 60)
    value = base64.decode(body["difficulty"]).upper()
    question = remove_chars(base64.decode(body["question"]))[:1000]
    answer = remove_chars(base64.decode(body["correct_answer"]))[:500]
    category = remove_chars(base64.decode(body["category"]))[:300]

    DELAY = int(config.str("scroll_speed", DEFAULT_SPEED)) + calc_delay(question, category)
    ANSWER_DELAY = config.str("answer_delay", DEFAULT_ANSWER_DELAY)

    return render.Root(
        max_age = 60,
        child = render.Box(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.WrappedText(
                            content = value,
                            color = "#d69f4c",
                            font = "CG-pixel-4x5-mono",
                            height = 6,
                            align = "center",
                        ),
                        height = 6,
                    ),
                    render.Box(
                        height = 1,
                        color = "#fff",
                    ),
                    render.Box(
                        height = 1,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = "Category:\n%s\n----------\n \n%s\n----------\n %s%s" % (category, question, ANSWER_DELAY, answer),
                                        font = "tb-8",
                                        align = "center",
                                    ),
                                ],
                            ),
                            height = 24,
                            offset_start = 22,
                            scroll_direction = "vertical",
                            align = "center",
                        ),
                    ),
                ],
            ),
            color = "#060CE9",
        ),
        delay = DELAY,
    )

DEFAULT_SPEED = "70"
DEFAULT_ANSWER_DELAY = "\n \n"

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slower", value = "110"),
        schema.Option(display = "Slow", value = "90"),
        schema.Option(display = "Normal (Default)", value = DEFAULT_SPEED),
        schema.Option(display = "Fast", value = "60"),
        schema.Option(display = "Faster", value = "40"),
    ]
    answer_delay = [
        schema.Option(display = "Slower", value = "\n \n \n \n"),
        schema.Option(display = "Slow", value = "\n \n \n"),
        schema.Option(display = "Normal (Default)", value = DEFAULT_ANSWER_DELAY),
        schema.Option(display = "Fast", value = "\n"),
        schema.Option(display = "Immediate", value = " "),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "personRunning",
                default = DEFAULT_SPEED,
                options = scroll_speed,
            ),
            schema.Dropdown(
                id = "answer_delay",
                name = "Answer delay",
                desc = "How long before answer shows",
                icon = "clock",
                default = DEFAULT_ANSWER_DELAY,
                options = answer_delay,
            ),
        ],
    )
