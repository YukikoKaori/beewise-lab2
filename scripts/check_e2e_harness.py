"""Offline structural checks only; never reports Android scenarios as passed."""
import ast
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
functions = []
for path in sorted((root / 'e2e_test').glob('*.py')):
    tree = ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
    functions.extend(node.name for node in ast.walk(tree)
                     if isinstance(node, ast.AsyncFunctionDef) and node.name.startswith('test_tc'))
assert len(functions) == 26, functions
ids = [name.split('_')[1] for name in functions]
assert len(set(ids)) == 26, ids
assert set(ids) == {f'tc{i:02}' for i in range(1, 27)}
assert json.loads((root / 'e2e_test/scenarios.json').read_text(encoding='utf-8'))
runner = (root / 'e2e_test/run-artemis.ps1').read_text(encoding='utf-8')
assert 'PENDING_VERIFICATION' in runner and 'exit $exitCode' in runner
assert 'BLOCKED' in runner
print('PASS: 26 unique scenario functions, Python syntax, scenario JSON and evidence status guards. Android scenarios NOT RUN.')
