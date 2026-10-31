// IAM metadata observation complements device evidence; it never proves client access.
// No email, password, token, profile text or notification body is requested.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
require(resolve(base, 'logger')).logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const project = 'beewise-lab-3';
const alias = uid => 'uid-sha256:' + createHash('sha256').update(uid).digest('hex').slice(0, 16);
const stage = process.argv[2];
if (!stage || !/^[a-z0-9-]{1,60}$/.test(stage)) throw Error('Use a non-identifying stage label.');
(async () => {
  const accessible = await firebase.projects.list({project, nonInteractive: true});
  if (!accessible.some(item => item.projectId === project)) throw Error('Wrong project.');
  const allowed = new Set(JSON.parse(readFileSync(resolve(root, 'evidence/cloud/auth-provisioning-readiness.json'), 'utf8')).accountMetadata.map(user => user.accountAlias));
  const identity = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'});
  const store = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const accounts = [];
  let nextPageToken;
  do {
    const {body} = await identity.get(`/projects/${project}/accounts:batchGet`, {queryParams: {
      maxResults: 100, ...(nextPageToken ? {nextPageToken} : {}),
      fields: 'users(localId,disabled,providerUserInfo(providerId),lastLoginAt),nextPageToken'}, timeout: 30000});
    for (const user of body.users ?? []) {
      if (!allowed.has(alias(user.localId))) continue;
      const path = `/projects/${project}/databases/(default)/documents/parents/${user.localId}`;
      const parent = await store.get(path, {queryParams: {'mask.fieldPaths': 'createdAt', fields: 'createTime,updateTime,fields'}, timeout: 30000, resolveOnHTTPError: true});
      if (![200, 404].includes(parent.status)) throw Error('Parent metadata unavailable.');
      const devices = await store.get(path + '/devices', {queryParams: {'mask.fieldPaths': 'platform', pageSize: 100}, timeout: 30000});
      accounts.push({accountAlias: alias(user.localId), enabled: user.disabled !== true,
        providers: (user.providerUserInfo ?? []).map(provider => provider.providerId),
        lastSignInAtUtc: user.lastLoginAt ? new Date(Number(user.lastLoginAt)).toISOString() : null,
        parent: {exists: parent.status === 200, createTime: parent.body?.createTime ?? null, updateTime: parent.body?.updateTime ?? null},
        devices: (devices.body.documents ?? []).map(document => ({installationAlias: alias(document.name.split('/').pop()), platform: document.fields?.platform?.stringValue, updateTime: document.updateTime})),
        deviceListComplete: !devices.body.nextPageToken});
    }
    nextPageToken = body.nextPageToken;
  } while (nextPageToken);
  const receipt = {timestampUtc: new Date().toISOString(), projectId: project, stage, readOnly: true,
    requestedPersonalOrCredentialFields: false, accounts,
    limitation: 'Admin/IAM metadata only. Requires separate genuine device login/session evidence; does not demonstrate client authorization or cross-account denial.'};
  writeFileSync(resolve(root, `evidence/cloud/test-users-${stage}.json`), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})().catch(() => { console.log(JSON.stringify({status: 'BLOCKED', summary: 'Dedicated test metadata inspection failed; no sensitive error content emitted.'})); process.exitCode = 1; });
