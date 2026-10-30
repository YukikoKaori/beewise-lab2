"""Check PowerShell runner exit/status/hash handling with a synthetic uv process.

Windows only. Creates fresh retained output on D; never calls a host or device.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--work-directory', default='D:/CodexTemp/beewise-runner-checks')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
work = Path(args.work_directory).resolve() / uuid.uuid4().hex
work.mkdir(parents=True)
double = work / 'bin'
double.mkdir()
env = os.environ.copy()
env['PATH'] = str(double) + os.pathsep + env['PATH']
env['ARTEMIS_BASE_URL'] = 'http://127.0.0.1:1'
env['ARTEMIS_DEVICE_SERIAL'] = 'HARNESS-DOUBLE-NO-DEVICE'
checks = []
for code in (7, 0):
    (double / 'uv.cmd').write_text(
        '@echo off\necho SYNTHETIC PROCESS DOUBLE: no mobile execution\n'
        f'exit /b {code}\n', encoding='ascii')
    output = work / f'exit-{code}'
    result = subprocess.run([
        'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        str(root / 'e2e_test/run-artemis.ps1'), '-OutputDirectory', str(output),
    ], cwd=root, env=env, capture_output=True, text=True, timeout=60)
    (work / f'exit-{code}.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    records = json.loads((output / 'run-manifest.json').read_text(encoding='utf-8-sig'))
    expected = 'FAIL' if code else 'PENDING_VERIFICATION'
    assert result.returncode == code, (result.returncode, result.stderr)
    assert len(records) == 3
    for record in records:
        assert record['exitCode'] == code and record['status'] == expected
        assert record['logSha256'].lower() == hashlib.sha256(Path(record['log']).read_bytes()).hexdigest()
    checks.append({'expectedExit': code, 'actualExit': result.returncode,
                   'status': expected, 'suiteRuns': len(records), 'hashesVerified': True})
report = {'scope': 'Synthetic process doubles only; Android/host/AI NOT RUN',
          'status': 'PASS', 'checks': checks, 'retainedOutput': str(work)}
(work / 'check-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report))
