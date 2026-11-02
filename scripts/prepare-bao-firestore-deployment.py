"""Prepare a frozen, non-deleting Firestore release. Never deploys anything."""
import datetime
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PRIVATE = Path('D:/CodexTemp/beewise-lab3-tools/bao-cloud-private')
BUNDLE = PRIVATE / 'firestore-auth-bootstrap-20261031'
PROJECT = 'beewise-lab-3'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def rules_hash(data):
    return digest(data.decode('utf-8').replace('\r\n', '\n').strip().encode())


def main():
    cli = ROOT / 'firebase/node_modules/firebase-tools/lib/bin/firebase.js'
    result = subprocess.run(['node', str(cli), 'firestore:indexes', '--project', PROJECT,
                             '--json', '--non-interactive'], capture_output=True, timeout=120)
    if result.returncode:
        raise RuntimeError('Index inventory failed; no raw CLI output emitted.')
    current_indexes = json.loads(result.stdout)['result']
    # Never generate a deletion-capable incomplete index list.
    if current_indexes != {'indexes': [], 'fieldOverrides': []}:
        raise RuntimeError('Live indexes/overrides changed; review a preserving union first.')
    readiness = json.loads((ROOT / 'evidence/cloud/auth-provisioning-readiness.json').read_text())
    baseline = (PRIVATE / 'deployed-firestore.rules').read_bytes()
    if rules_hash(baseline) != readiness['firestore']['deployedSha256']:
        raise RuntimeError('Live baseline snapshots differ; refresh inspection first.')
    if BUNDLE.exists():
        raise RuntimeError('Frozen bundle already exists; do not overwrite a reviewed release.')
    BUNDLE.mkdir(parents=True)
    inputs = {'firestore.rules': 'firebase/firestore.rules',
              'firestore.indexes.json': 'firebase/firestore.indexes.json',
              'storage.rules': 'firebase/storage.rules', 'rules.test.cjs': 'firebase/rules.test.cjs'}
    for target, source in inputs.items():
        (BUNDLE / target).write_bytes((ROOT / source).read_bytes())
    (BUNDLE / 'previous-deployed-firestore.rules').write_bytes(baseline)
    deploy_config = {'firestore': {'rules': 'firestore.rules', 'indexes': 'firestore.indexes.json'}}
    validation_config = {**deploy_config, 'storage': {'rules': 'storage.rules'},
                         'emulators': {'firestore': {'port': 8080}, 'storage': {'port': 9199},
                                       'ui': {'enabled': False}, 'singleProjectMode': True}}
    for name, value in [('firebase.deploy.json', deploy_config), ('firebase.validation.json', validation_config)]:
        (BUNDLE / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
    hashes = {p.name: digest(p.read_bytes()) for p in BUNDLE.iterdir() if p.is_file()}
    receipt = {'preparedAtUtc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'sourceSha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
               'projectId': PROJECT, 'bundleDirectory': str(BUNDLE), 'liveWritesPerformed': False,
               'deploymentAuthorization': 'REQUIRED; not yet granted', 'fileSha256': hashes,
               'repositoryRulesNormalizedSha256': rules_hash((BUNDLE / 'firestore.rules').read_bytes()),
               'baselineRulesetName': readiness['firestore']['rulesetName'],
               'baselineRulesNormalizedSha256': rules_hash(baseline), 'baselineIndexConfiguration': current_indexes,
               'indexChange': 'Create chats(parentId ASC, updatedAt DESC) only; no existing indexes/overrides to remove',
               'rollback': 'Previous deployed rules lack security guards; not an approved secure rollback. Halt and repair forward; never auto-restore weaker rules.'}
    (BUNDLE / 'manifest.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    (ROOT / 'evidence/cloud/prepared-firestore-deployment.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
