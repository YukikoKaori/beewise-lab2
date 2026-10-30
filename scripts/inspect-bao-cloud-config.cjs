// Read-only, fixed-project inventory via the authenticated Firebase CLI.
// Raw SDK config/templates stay private on D; only allowlisted metadata is emitted.
const {execFile} = require('node:child_process');
const {promisify} = require('node:util');
const {mkdirSync, writeFileSync} = require('node:fs');
const {resolve} = require('node:path');
const run = promisify(execFile);
const root = resolve(__dirname, '..');
const cli = resolve(root, 'firebase/node_modules/firebase-tools/lib/bin/firebase.js');
const projectId = 'beewise-lab-3';
const appId = '1:840483888286:android:50c11fbb460437ed6a2f8f';
const privateDir = 'D:/CodexTemp/beewise-lab3-tools/bao-cloud-private';
mkdirSync(privateDir, {recursive: true});
const pick = (item, keys) => Object.fromEntries(keys.filter(key => item?.[key] !== undefined).map(key => [key, item[key]]));
const list = value => Array.isArray(value) ? value : value?.databases ?? [];
const commands = [
  [['apps:list', 'ANDROID'], value => list(value).filter(app => app.appId === appId).map(app => pick(app, ['appId', 'displayName', 'platform', 'packageName', 'projectId']))],
  [['apps:android:sha:list', appId], value => list(value).map(cert => pick(cert, ['shaHash', 'certType']))],
  [['firestore:databases:list'], value => list(value).map(db => pick(db, ['name', 'locationId', 'type', 'databaseEdition']))],
  [['firestore:indexes'], value => value],
  [['appcheck:apps:list'], value => list(value).filter(app => app.appId === appId).map(app => pick(app, ['appId', 'platform', 'providers']))],
  [['appcheck:services:list'], value => list(value).map(service => pick(service, ['alias', 'serviceId', 'enforcementMode', 'replayProtection']))],
  [['remoteconfig:get', '--output', privateDir + '/remote-config-original.json'], value => {
    writeFileSync(privateDir + '/remote-config-private-receipt.json', JSON.stringify(value));
    return {versionNumber: value?.version?.versionNumber,
      parameters: Object.fromEntries(['home_tutor_limit', 'ai_result_limit', 'ai_matching_enabled', 'gemini_model'].map(key => [key, value?.parameters?.[key]?.defaultValue ?? null]))};
  }],
  [['apps:sdkconfig', 'ANDROID', appId, '--out', privateDir + '/google-services-current.json'], value => {
    const config = JSON.parse(value.fileContents);
    if (config.project_info?.project_id !== projectId) throw Error('Unexpected project, refusing config.');
    return {projectId: config.project_info.project_id,
      androidClients: config.client?.filter(client => client.client_info?.mobilesdk_app_id === appId).map(client => ({
        packageName: client.client_info.android_client_info?.package_name,
        oauthClientTypes: (client.oauth_client ?? []).map(oauth => oauth.client_type),
      }))};
  }],
];
(async () => {
  const records = [];
  // Bound Windows CLI process memory; an initial eight-process probe crashed one.
  for (let offset = 0; offset < commands.length; offset += 2) {
    records.push(...await Promise.all(commands.slice(offset, offset + 2).map(async ([args, sanitize]) => {
    const command = [...args, '--project', projectId, '--json', '--non-interactive'];
    try {
      const {stdout} = await run(process.execPath, [cli, ...command], {cwd: root, timeout: 120000, maxBuffer: 4 * 1024 * 1024});
      const payload = JSON.parse(stdout);
      return {command, timestampUtc: new Date().toISOString(), nativeExitCode: 0, status: 'PASS', result: sanitize(payload.result)};
    } catch (error) {
      // Do not include raw CLI output, emails or authentication URLs.
      let message = 'Read failed; inspect authenticated CLI privately.';
      try {
        const payload = JSON.parse(error.stdout ?? '{}');
        const raw = typeof payload.error === 'string' ? payload.error : payload.error?.message;
        if (raw) message = raw.replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[email omitted]').replace(/https?:\/\/\S+/g, '[URL omitted]').slice(0, 500);
      } catch {}
      return {command, timestampUtc: new Date().toISOString(), nativeExitCode: typeof error.code === 'number' ? error.code : null, status: 'BLOCKED', summary: message};
    }
    })));
  }
  const receipt = {projectId, appId, readOnly: true, records};
  writeFileSync(resolve(root, 'evidence/cloud/config-inventory.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})();
