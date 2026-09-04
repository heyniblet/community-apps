load("0764.01.gif", GLYPH_1 = "file")
load("1031.03.gif", GLYPH_2 = "file")
load("1086.00.gif", GLYPH_3 = "file")
load("render.star", "render")
load("time.star", "time")

GLYPHS = [GLYPH_1, GLYPH_2, GLYPH_3]

def main():
    glyph = GLYPHS[time.now().day % len(GLYPHS)]
    return render.Root(child = render.Image(src = glyph.readall(), width = 64, height = 32))
