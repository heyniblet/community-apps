"""Offline ordering, deduplication and calendar-window checks for every score app."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = str(Path(sys.argv[1]).resolve())
names = ['nflscores','ncaafscores','ncaamscores','ncaawscores','ncaabscores','mlbscores','nhlscores','nbascores','wnbascores','mlsscores','eplscores','cflscores','soccermens','soccerwomens','mhkyscores','wbcscores','uflscores','xflscores']
events = []
for i in range(8, 0, -1):
    events.append({"id": str(i), "date": f"2026-09-{i+10:02d}T12:00:00Z",
                   "status": {"type": {"state": "pre"}},
                   "competitions": [{"competitors": [
                       {"team": {"id": "T", "abbreviation": "T"}},
                       {"team": {"id": "OTHER", "abbreviation": "OTHER"}}
                   ]}]})

events += [dict(events[0], updated=True)]
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    for name in names:
        source = next((root/'apps'/name).glob('*.star')).read_text()
        assert 'page_size =' not in source and '60 // len(scores)' not in source, name
        source = source.replace('def get_schema(', 'def original_get_schema(', 1)
        source = source.replace('def main(', 'def app_main(', 1).replace('def get_cachable_data(', 'def original_get_cachable_data(',1)
        source += '\nEVENTS = json.decode('+repr(json.dumps(events))+')\ndef get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):\n    if "dates=" in url and "-" in url.split("dates=")[1].split("&")[0]:\n        fail("date range request escaped daily expansion")\n    return json.encode({"events": EVENTS})\n'
        if name in ['mlbscores','nbascores','wnbascores']:
            invocation = 'get_scores(time.now(), "all")'
            calendar = ''
        elif name == 'ncaafscores':
            invocation = 'get_scores("https://example.com/scoreboard?limit=300", time.now(), "all")'
            calendar = ''
        else:
            invocation = 'get_scores({"league": "https://example.com/scoreboard?dates=20260920-20260927"}'+(')' if name in ['soccermens','soccerwomens'] else ', "all")')
            calendar = '''
    for start, end in [("20261231", "20270107"), ("20260307", "20260314"), ("20261031", "20261107")]:
        urls = scoreboard_urls("https://example.com/scoreboard?limit=300&dates=" + start + "-" + end + "&groups=80")
        if len(urls) != 8 or len({u: True for u in urls}) != 8:
            fail("calendar dates omitted or repeated")
        if not urls[0].endswith("dates=" + start + "&groups=80") or not urls[-1].endswith("dates=" + end + "&groups=80"):
            fail("calendar window or conference changed")
'''
        if name in ['soccermens','soccerwomens']:
            calendar += '\n    if get_comp_label("https://example.com/scoreboard?dates=20260920-20260927", "TEST") != "TEST":\n        fail("wide layout label fallback changed")\n'
        focus = ''
        if name not in ['soccermens','soccerwomens']:
            selected_call = invocation.replace('"all"', '"T"')
            expected = '[str(i) for i in range(8,0,-1)]' if name == 'nflscores' else '["1"]'
            focus = '\n    if [s["id"] for s in '+selected_call+'] != '+expected+':\n        fail("team focus changed")\n'
        order = '[str(i) for i in range(8,0,-1)]' if name == 'nflscores' else '[str(i) for i in range(1,9)]'
        updated = '0' if name == 'nflscores' else '-1'
        source += '\ndef main(config):\n    scores = '+invocation+'\n    if [s["id"] for s in scores] != '+order+' or not scores['+updated+'].get("updated"):\n        fail("games missing, duplicated, out of order, or stale")\n'+calendar+focus+'    return [render.Root(child=render.Text("OK"))]\n'
        path=tmp/(name+'.star'); path.write_text(source)
        subprocess.run([runtime,'render',str(path),'--output',str(tmp/'test.webp'),'--silent'],check=True)
print('18 score apps: complete ordered games, deduplication and calendar windows passed')
