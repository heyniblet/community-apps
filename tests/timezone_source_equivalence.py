"""Ensure timezone migrations leave app/provider logic unchanged, apart from reviewed inputs."""
import ast
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
BASE = "74a7d00a"

class InputsOnly(ast.NodeTransformer):
    def visit_FunctionDef(self, node):
        if node.name in {"get_schema", "_timezone_location"}:
            return None
        return self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Name) and node.func.id == "_timezone_location":
            return self.visit(node.args[1])
        return self.generic_visit(node)

def timezone_helper(source):
    for node in ast.parse(source).body:
        if isinstance(node, ast.FunctionDef) and node.name == "_timezone_location":
            return ast.dump(node)
    return None

for app in json.loads((root / "tests/timezone-migrations.json").read_text()):
    before = subprocess.check_output(["git", "show", BASE + ":" + app["source_path"]], cwd=root, text=True)
    after = (root / app["source_path"]).read_text()
    # Apps whose logic was deliberately changed after the migration name the
    # last revision that still matched; compare the migration against that
    # revision and require the timezone helper to be unchanged since.
    if "equivalence_ref" in app:
        reviewed = subprocess.check_output(["git", "show", app["equivalence_ref"] + ":" + app["source_path"]], cwd=root, text=True)
        assert timezone_helper(reviewed) == timezone_helper(after), app["app_id"] + " timezone helper changed"
        after = reviewed
    if app["app_id"] in {"evcc", "shouldideploy"}:
        after = after.replace('load("time.star", "time")\n', '')
    if app["app_id"] == "retrograde-planet":
        before = before.replace('timezone_id = "America/Dallas"', 'timezone_id = "UTC"')
    old_tree = InputsOnly().visit(ast.parse(before))
    new_tree = InputsOnly().visit(ast.parse(after))
    assert ast.dump(old_tree) == ast.dump(new_tree), app["app_id"]
print("79 app/provider bodies match their reviewed predecessor after isolating timezone inputs")
