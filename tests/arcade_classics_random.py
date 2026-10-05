"""Run with: python3 tests/arcade_classics_random.py /path/to/niblet

Random mode picks from a deterministic generator seeded by the five-minute
slot, so the test walks several slots instead of seeding the random module.
It also checks that two renders in one slot are byte-identical.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

source = Path(__file__).resolve().parents[1] / "apps/arcadeclassics/arcade_classics.star"

with tempfile.TemporaryDirectory() as temporary:
    out = Path(temporary)
    for slot in range(8):
        minute = slot * 5
        for scale in ([], ["--2x"]):
            outputs = []
            for second in ("00", "59"):
                output = out / f"test-{slot}-{second}.webp"
                now = f"2026-10-05T12:{minute + 4 if second == '59' else minute:02d}:{second}Z"
                subprocess.run([sys.argv[1], "render", str(source), "animation=random", "speed=-1", "--now", now, "--output", str(output), "--silent", *scale], check=True)
                outputs.append(output.read_bytes())
            assert outputs[0] == outputs[1], f"slot {slot} renders differ"
print("Arcade random-mode regression passed at 1x and 2x")
