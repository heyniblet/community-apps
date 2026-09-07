"""Run with: python3 tests/arcade_classics_random.py /path/to/niblet"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

with tempfile.TemporaryDirectory() as temporary:
    app = Path(temporary) / "arcade"
    shutil.copytree(Path(__file__).resolve().parents[1] / "apps/arcadeclassics", app)
    source = app / "arcade_classics.star"
    source.write_text(source.read_text().replace("def main(config):", "def arcade_main(config):", 1))
    entry = app / "random_test.star"
    entry.write_text('load("arcade_classics.star", app_main="arcade_main")\nload("random.star", "random")\ndef main(config):\n    random.seed(int(config.str("test_seed", "0")))\n    return app_main(config)\n')
    for seed in range(4):
        for scale in ([], ["--2x"]):
            subprocess.run([sys.argv[1], "render", str(entry), "animation=random", "speed=50", f"test_seed={seed}", "--output", str(app / "test.webp"), "--silent", *scale], check=True)
print("Arcade random-mode regression passed at 1x and 2x")
