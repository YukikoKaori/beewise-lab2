// One synthetic probe to an explicitly observed dedicated test installation only.
// Uses the CLI's normal SDK client; no bearer extraction, passwords or topics.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
require(resolve(base, 'logger')).logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const project = 'beewise-lab-3';
const alias = value => 'uid-sha256:' + createHash('sha256').update(value).digest('hex').slice(0, 16);
const [ownerAlias, expectedInstallationAlias, stage] = process.argv.slice(2);
if (!['foreground', 'background', 'terminated', 'malformed', 'unauthorized-chat', 'cross-recipient'].includes(stage)) throw Error('Unknown synthetic probe.');
(async () => {
  const accessible = await firebase.projects.list({project, nonInteractive: true});
  if (!accessible.some(item => item.projectId === project)) throw Error('Wrong project.');
  const allowed = new Set(JSON.parse(readFileSync(resolve(root, 'evidence/cloud/auth-provisioning-readiness.json'), 'utf8')).accountMetadata.map(user => user.accountAlias));
  if (!allowed.has(ownerAlias) || !/^uid-sha256:[a-f0-9]{16}$/.test(expectedInstallationAlias)) throw Error('Unapproved target.');
  const identity = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'});
  const {body} = await identity.get(`/projects/${project}/accounts:batchGet`, {queryParams: {
    maxResults: 100, fields: 'users(localId,disabled),nextPageToken'}, timeout: 30000});
  if (body.nextPageToken) throw Error('Incomplete identity inventory.');
  const owner = (body.users ?? []).find(user => alias(user.localId) === ownerAlias && !user.disabled);
  if (!owner) throw Error('Dedicated owner unavailable.');
  const store = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const {body: registration} = await store.get(`/projects/${project}/databases/(default)/documents/parents/${owner.localId}/devices`,
    {queryParams: {'mask.fieldPaths': 'platform', pageSize: 100}, timeout: 30000});
  if (registration.nextPageToken || registration.documents?.length !== 1) throw Error('Require exactly one observed test installation.');
  const device = registration.documents[0];
  const fid = device.name.split('/').pop();
  if (device.fields?.platform?.stringValue !== 'android' || alias(fid) !== expectedInstallationAlias) throw Error('Installation changed; inspect before sending.');
  const other = (body.users ?? []).find(user => allowed.has(alias(user.localId)) && alias(user.localId) !== ownerAlias && !user.disabled);
  if (stage === 'cross-recipient' && !other) throw Error('Second dedicated identity unavailable.');
  const recipient = stage === 'cross-recipient' ? other : owner;
  const probeId = `bao-pr3-${stage}-${Date.now()}`;
  const route = stage === 'malformed' ? 'https://invalid.example.test/forbidden'
    : stage === 'unauthorized-chat' ? '/chats/bao-negative-other-account' : '/search';
  const message = {fid, data: {recipientUid: recipient.localId, route, probeId},
    android: {priority: 'high', ttl: '120s', restricted_package_name: 'com.beewise.beewise'}};
  if (stage !== 'cross-recipient') message.notification = {title: `[TEST] Bao PR3 ${stage}`, body: 'Isolated-device validation: ' + probeId};
  const response = await new Client({urlPrefix: 'https://fcm.googleapis.com', apiVersion: 'v1'})
    .post(`/projects/${project}/messages:send`, {message}, {timeout: 30000, resolveOnHTTPError: true});
  const receipt = {timestampUtc: new Date().toISOString(), projectId: project, stage, probeId,
    ownerAlias, recipientAlias: alias(recipient.localId), installationAlias: expectedInstallationAlias,
    statusCode: response.status, acceptedMessageName: response.body?.name ?? null,
    errorStatus: response.body?.error?.status ?? null,
    limitation: 'API acceptance is not device delivery; correlate genuine device/PID/UI evidence. No topic/bulk send or service configuration change.'};
  writeFileSync(resolve(root, `evidence/cloud/fcm-${probeId}.json`), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
  if (response.status >= 400) process.exitCode = 1;
})().catch(() => { console.log(JSON.stringify({status: 'BLOCKED', summary: 'Probe failed or target guard rejected it; no sensitive payload/error printed.'})); process.exitCode = 1; });
