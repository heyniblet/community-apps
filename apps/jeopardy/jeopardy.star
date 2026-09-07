load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FALLBACK_QUESTION = {"category": "SCIENCE", "answer": "The planet known as the Red Planet", "response": "Mars", "air_date": ""}

def get_question():
    res = http.get("https://www.jeopardy.com/api/j6-clues", ttl_seconds = 21600)
    body = res.body()
    games = json.decode(body, []) if res.status_code == 200 and body and len(body) <= 256 * 1024 else []
    if type(games) != "list" or not games or type(games[0]) != "dict":
        return FALLBACK_QUESTION
    game = games[0]
    questions = []
    for key in ["clues_round_1", "clues_round_2", "clues_round_3"]:
        clues = game.get(key, [])
        if type(clues) == "list":
            questions.extend(clues[:100])
    if not questions:
        return FALLBACK_QUESTION
    question = questions[random.number(0, len(questions) - 1)]
    answers = question.get("answers", []) if type(question) == "dict" else []
    index = question.get("correct_answer_index", "") if type(question) == "dict" else ""
    if type(answers) != "list" or type(index) != "string" or not index.isdigit() or int(index) < 1 or int(index) > len(answers):
        return FALLBACK_QUESTION
    category = question.get("category")
    clue = question.get("clue")
    response = answers[int(index) - 1]
    if any([type(value) != "string" for value in [category, clue, response]]):
        return FALLBACK_QUESTION
    return {"category": category[:100], "answer": clue[:500], "response": response[:300], "air_date": str(game.get("date", ""))[:40]}

def display_for(duration, child):
    return render.Box(
        child = animation.Transformation(
            child = child,
            duration = duration,
            delay = 0,
            origin = animation.Origin(0, 0),
            direction = "normal",
            fill_mode = "forwards",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [],
                ),
            ],
        ),
    )

def category_section(category, category_duration):
    return render.Box(
        child = animation.Transformation(
            child = render.Box(
                color = "#00f",
                child = render.WrappedText(
                    content = "%s" % category.upper(),
                    font = "tb-8",
                    align = "center",
                    linespacing = 0,
                ),
            ),
            duration = category_duration,
            delay = 0,
            origin = animation.Origin(0.5, 0.5),
            direction = "normal",
            fill_mode = "forwards",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Scale(0.01, 0.01), animation.Translate(2, 2)],
                ),
                animation.Keyframe(
                    percentage = 0.5,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [],
                ),
            ],
        ),
    )

def answer_section(answer):
    return render.Box(
        color = "#00f",
        child = render.Marquee(
            height = 32,
            offset_start = 32,
            offset_end = 0,
            child = render.WrappedText(
                content = answer,
                width = 64,
                font = "tb-8",
                align = "center",
            ),
            scroll_direction = "vertical",
        ),
    )

def what_is_section():
    return render.Box(
        child = render.WrappedText(
            content = "WHAT IS...",
            width = 64,
            font = "tb-8",
            align = "center",
        ),
    )

def response_section(response, air_date):
    return render.Box(
        color = "#00f",
        child = render.Marquee(
            height = 32,
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(
                content = response + "\n \n(" + air_date + ")",
                width = 64,
                font = "tb-8",
                align = "center",
            ),
            scroll_direction = "vertical",
        ),
    )

def main(config):
    data = get_question()

    part_one = [
        category_section(data["category"], safe_duration(config.str("category_duration", "20"), 20)),
        display_for(safe_duration(config.str("answer_duration", "100"), 100), answer_section(data["answer"])),
    ]

    part_two = [
        display_for(safe_duration(config.str("what_is_delay", "20"), 20), what_is_section()),
        display_for(safe_duration(config.str("response_delay", "100"), 100), response_section(data["response"], data["air_date"])),
    ]

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Sequence(
            children = part_one + part_two if config.bool("show_all") else (
                part_one if not config.bool("show_response") else part_two
            ),
        ),
    )

def safe_duration(value, default):
    return min(max(int(value), 1), 1000) if value.isdigit() else default

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_all",
                name = "Show All",
                desc = "Show answer and response.",
                icon = "plus",
            ),
            schema.Toggle(
                id = "show_response",
                name = "Show Response",
                desc = "Show response if set, otherwise only show the answer.",
                icon = "plus",
            ),
            schema.Text(
                id = "category_duration",
                name = "Category duration",
                desc = "Duration to show the category",
                icon = "plus",
            ),
            schema.Text(
                id = "answer_duration",
                name = "Answer duration",
                desc = "Duration to show the answer",
                icon = "plus",
            ),
            schema.Text(
                id = "what_is_delay",
                name = "What Is delay",
                desc = "Duration to show 'what is'",
                icon = "plus",
            ),
            schema.Text(
                id = "response_delay",
                name = "Response delay",
                desc = "Duration to show the response",
                icon = "plus",
            ),
        ],
    )
