"""Check PowerShell runner exit/status/hash handling with a synthetic uv process.

Windows only. Creates fresh retained output on D; never calls a host or device.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--work-directory', default='D:/CodexTemp/beewise-runner-checks')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
git_executable = shutil.which('git')
assert git_executable, 'Git is required for runner source-SHA recording.'
git_directory = str(Path(git_executable).resolve().parent)
work = Path(args.work_directory).resolve() / uuid.uuid4().hex
work.mkdir(parents=True)
double = work / 'bin'
double.mkdir()
env = os.environ.copy()
env['PATH'] = str(double) + os.pathsep + env['PATH']
env['ARTEMIS_BASE_URL'] = 'http://127.0.0.1:1'
env['ARTEMIS_DEVICE_SERIAL'] = 'HARNESS-DOUBLE-NO-DEVICE'
(double / 'adb.cmd').write_text(
    '@echo off\n'
    'if "%1"=="devices" echo List of devices attached\n'
    'if "%1"=="devices" echo HARNESS-DOUBLE-NO-DEVICE device\n'
    'exit /b 0\n', encoding='ascii')
checks = []
(double / 'uv-called.marker').unlink(missing_ok=True)
(double / 'uv.cmd').write_text(
    '@echo off\n'
    'echo called>>"%~dp0uv-called.marker"\n'
    'echo SYNTHETIC PROCESS DOUBLE: default-selection guard check\n'
    'exit /b 0\n', encoding='ascii')

# Missing ADB must fail before creating evidence or invoking uv. Use a
# dedicated PowerShell process profile so the caller's PATH cannot supply ADB.
missing_adb_output = work / 'missing-adb'
missing_adb_script = work / 'check-missing-adb.ps1'
missing_adb_script.write_text(
    "$env:PATH = $env:GIT_CMD_PATH + ';' + $env:SYSTEMROOT + '\\System32'\n"
    "$env:ARTEMIS_CASE_IDS = 'TC-01'\n"
    "$env:ARTEMIS_BASE_URL = 'http://127.0.0.1:1'\n"
    "$env:ARTEMIS_DEVICE_SERIAL = 'HARNESS-DOUBLE-NO-DEVICE'\n"
    f"& '{root / 'e2e_test/run-artemis.ps1'}' -OutputDirectory '{missing_adb_output}'\n"
    "exit $LASTEXITCODE\n", encoding='utf-8')
missing_adb_env = {**env, 'GIT_CMD_PATH': git_directory}
missing_adb_result = subprocess.run([
    'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    str(missing_adb_script),
], cwd=root, env=missing_adb_env, capture_output=True, text=True, timeout=60)
assert missing_adb_result.returncode == 2
missing_adb_manifest = json.loads((missing_adb_output / 'run-manifest.json').read_text(encoding='utf-8-sig'))
assert missing_adb_manifest['status'] == 'BLOCKED'
assert 'adb executable' in missing_adb_manifest['missing']
assert not (double / 'uv-called.marker').exists()
checks.append({'missingAdb': 'blocked', 'status': 'BLOCKED', 'uvInvoked': False,
               'pytestOutputsCreated': False, 'manifestCreated': True})

# Explicit serial in offline/unauthorized state must also fail closed.
(double / 'adb.cmd').write_text(
    '@echo off\n'
    'if "%1"=="devices" echo List of devices attached\n'
    'if "%1"=="devices" echo HARNESS-DOUBLE-NO-DEVICE offline\n'
    'if "%1"=="devices" echo unauthorized-device unauthorized\n'
    'exit /b 0\n', encoding='ascii')
offline_output = work / 'offline-device'
offline_result = subprocess.run([
    'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    str(root / 'e2e_test/run-artemis.ps1'), '-OutputDirectory', str(offline_output),
], cwd=root, env={**env, 'ARTEMIS_CASE_IDS': 'TC-01'},
   capture_output=True, text=True, timeout=60)
assert offline_result.returncode == 2
offline_manifest = json.loads((offline_output / 'run-manifest.json').read_text(encoding='utf-8-sig'))
assert offline_manifest['status'] == 'BLOCKED'
assert 'online authorized ARTEMIS_DEVICE_SERIAL' in offline_manifest['missing']
assert not (double / 'uv-called.marker').exists()
checks.append({'offlineDevice': 'blocked', 'status': 'BLOCKED', 'uvInvoked': False,
               'pytestOutputsCreated': False, 'manifestCreated': True})

# Restore the authorized synthetic ADB device for the remaining process-double checks.
(double / 'adb.cmd').write_text(
    '@echo off\n'
    'if "%1"=="devices" echo List of devices attached\n'
    'if "%1"=="devices" echo HARNESS-DOUBLE-NO-DEVICE device\n'
    'exit /b 0\n', encoding='ascii')

default_output = work / 'default-selection'
default_result = subprocess.run([
    'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    str(root / 'e2e_test/run-artemis.ps1'), '-OutputDirectory', str(default_output),
], cwd=root, env={**env, 'ARTEMIS_CASE_IDS': ''}, capture_output=True, text=True, timeout=60)
assert default_result.returncode != 0
assert 'ARTEMIS_CASE_IDS must explicitly select' in default_result.stderr
assert not (double / 'uv-called.marker').exists(), 'Default selection must not invoke pytest/uv.'
assert not default_output.exists(), 'Default selection must fail before creating run evidence.'
checks.append({'emptyCaseSelection': 'rejected', 'uvInvoked': False, 'outputCreated': False})
safe_cases = ['TC-01', 'TC-07', 'TC-13']
env['ARTEMIS_CASE_IDS'] = '|'.join(safe_cases)
for code in (7, 0):
    (double / 'uv.cmd').write_text(
        '@echo off\necho SYNTHETIC PROCESS DOUBLE: no mobile execution %*\n'
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
        assert record['selectedCases'] == safe_cases
        assert record['logSha256'].lower() == hashlib.sha256(Path(record['log']).read_bytes()).hexdigest()
        run_log_bytes = Path(record['log']).read_bytes()
        run_log = run_log_bytes.decode('utf-16') if run_log_bytes.startswith(b'\xff\xfe') else run_log_bytes.decode('utf-8-sig')
        assert 'test_tc01_ or test_tc07_ or test_tc13_' in run_log
    checks.append({'expectedExit': code, 'actualExit': result.returncode,
                   'status': expected, 'suiteRuns': len(records), 'hashesVerified': True})

(double / 'uv.cmd').write_text(
    '@echo off\necho TC-01 blocked: ARTEMIS trace synthetic-session reports a provider quota/rate-limit error\n'
    'exit /b 1\n', encoding='ascii')
quota_output = work / 'quota-blocked'
quota_result = subprocess.run([
    'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    str(root / 'e2e_test/run-artemis.ps1'), '-OutputDirectory', str(quota_output),
], cwd=root, env=env, capture_output=True, text=True, timeout=60)
quota_records = json.loads((quota_output / 'run-manifest.json').read_text(encoding='utf-8-sig'))
assert quota_result.returncode == 1, (quota_result.returncode, quota_result.stderr)
assert len(quota_records) == 1, quota_records
assert quota_records[0]['status'] == 'BLOCKED_QUOTA', quota_records
assert 'later suite runs were not submitted' in quota_result.stdout
checks.append({'quotaDetected': True, 'status': 'BLOCKED_QUOTA', 'laterRunsSubmitted': False})

rejected = subprocess.run([
    'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    str(root / 'e2e_test/run-artemis.ps1'),
], cwd=root, env={**env, 'ARTEMIS_CASE_IDS': 'TC-18'}, capture_output=True, text=True, timeout=60)
assert rejected.returncode != 0
assert 'outside the non-business-mutation subset' in rejected.stderr
checks.append({'unapprovedBusinessMutationCase': 'TC-18', 'rejected': True})
report = {'scope': 'Synthetic process doubles only; Android/host/AI NOT RUN',
          'status': 'PASS', 'checks': checks, 'retainedOutput': str(work)}
(work / 'check-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report))
