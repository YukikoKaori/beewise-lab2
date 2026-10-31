// Authorized temporary RC experiment only. Conditional writes preserve concurrent work.
// Never publishes rules/providers/billing. Run restore after the device experiment.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync, existsSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
require(resolve(base, 'logger')).logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const project = 'beewise-lab-3';
const privateFile = 'D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/rc-authorized-roundtrip.json';
const receiptFile = resolve(root, 'evidence/cloud/remote-config-roundtrip.json');
const action = process.argv[2];
const clean = template => Object.fromEntries(['conditions', 'parameters', 'parameterGroups'].filter(k => template[k] !== undefined).map(k => [k, template[k]]));
const fingerprint = template => createHash('sha256').update(JSON.stringify(clean(template))).digest('hex');
(async () => {
  if (!['apply', 'restore'].includes(action)) throw Error('Choose apply or restore.');
  if (process.env.BAO_AUTHORIZED_RC_ROUNDTRIP !== '1') throw Error('Explicit authorized experiment flag required.');
  const accessible = await firebase.projects.list({project, nonInteractive: true});
  if (!accessible.some(p => p.projectId === project)) throw Error('Wrong project access.');
  const client = new Client({urlPrefix: 'https://firebaseremoteconfig.googleapis.com', apiVersion: 'v1'});
  const path = `/projects/${project}/remoteConfig`;
  const current = await client.get(path, {timeout: 30000});
  const etag = current.response.headers.get('etag');
  if (!etag || etag === '*') throw Error('Missing conditional write ETag.');
  let state = existsSync(privateFile) ? JSON.parse(readFileSync(privateFile)) : null;
  let template;
  if (action === 'apply') {
    if (state && !state.restored) throw Error('An experiment already needs restoration.');
    // This experiment was approved against an empty template; do not replace other work.
    if (Object.keys(current.body.parameters ?? {}).length || Object.keys(current.body.parameterGroups ?? {}).length || (current.body.conditions ?? []).length) throw Error('Template changed; stop for review.');
    template = {parameters: {
      home_tutor_limit: {defaultValue: {value: '2'}, valueType: 'NUMBER'},
      ai_result_limit: {defaultValue: {value: '1'}, valueType: 'NUMBER'},
      ai_matching_enabled: {defaultValue: {value: 'false'}, valueType: 'BOOLEAN'},
    }};
    state = {original: clean(current.body), originalEtag: etag, appliedTemplate: template, restored: false};
    writeFileSync(privateFile, JSON.stringify(state, null, 2));
  } else {
    if (!state || state.restored) throw Error('No pending experiment.');
    if (fingerprint(current.body) !== fingerprint(state.appliedTemplate)) throw Error('Concurrent template change; refusing overwrite.');
    template = state.original;
  }
  await client.put(path, template, {headers: {'If-Match': etag}, timeout: 30000});
  const after = await client.get(path, {timeout: 30000});
  if (fingerprint(after.body) !== fingerprint(template)) throw Error('Post-write template differs; inspect privately.');
  state.restored = action === 'restore';
  writeFileSync(privateFile, JSON.stringify(state, null, 2));
  const receipt = existsSync(receiptFile) ? JSON.parse(readFileSync(receiptFile)) : {project, authorization: 'User allowed temporary Remote Config changes with restoration', records: []};
  const record = {timestampUtc: new Date().toISOString(), action, conditionalWrite: true, status: 'PASS', version: after.body.version?.versionNumber,
    parameters: Object.fromEntries(Object.entries(after.body.parameters ?? {}).map(([key, value]) => [key, value.defaultValue?.value]))};
  receipt.records.push(record);
  writeFileSync(receiptFile, JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(record));
})().catch(error => { console.log(JSON.stringify({status: 'BLOCKED', summary: String(error.message).replace(/https?:\/\/\S+/g, '[URL omitted]').slice(0, 300)})); process.exitCode = 1; });
