"""Run with python3 .github/scripts/test-targets.py."""
import os
from pathlib import Path
import subprocess
import tempfile

script = Path(__file__).with_name("determine-targets.sh").resolve()
checker = Path(__file__).with_name("check-apps.sh").resolve()
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=root, text=True).strip()
    git("init", "-q")
    git("config", "user.email", "ci@example.test")
    git("config", "user.name", "CI")
    git("commit", "--allow-empty", "-qm", "base")
    base = git("rev-parse", "HEAD")
    for app in ("one", "two"):
        path = root / "apps" / app
        path.mkdir(parents=True)
        (path / "main.star").write_text("pass\n")
    git("add", ".")
    git("commit", "-qm", "apps")
    output = root / "output"
    env = dict(os.environ, BASE_SHA=base, HEAD_SHA=git("rev-parse", "HEAD"), GITHUB_OUTPUT=str(output))
    subprocess.run(["bash", str(script)], cwd=root, env=env, check=True)
    assert output.read_text() == "targets=apps/one apps/two\n"
    fake = root / "pixlet"
    fake.write_text('#!/bin/sh\nprintf "%s\n" "$*" >> "$CALLS"\n')
    fake.chmod(0o755)
    env.update(PATH=str(root)+os.pathsep+env["PATH"], TARGETS="apps/one apps/two", CALLS=str(root/"calls"))
    subprocess.run(["bash", str(checker)], cwd=root, env=env, check=True)
    assert (root/"calls").read_text().splitlines() == ["check apps/one", "check apps/two"]
    output.unlink()
    env["BASE_SHA"] = env["HEAD_SHA"]
    subprocess.run(["bash", str(script)], cwd=root, env=env, check=True)
    assert output.read_text() == "targets=\n"
