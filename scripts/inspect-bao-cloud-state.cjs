// Fixed-project read-only management API inspection using Firebase CLI's normal
// authenticated SDK client. No credential file access or token extraction.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync, mkdirSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
const {logger} = require(resolve(base, 'logger'));
logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const rules = require(resolve(base, 'gcp/rules'));
const projectId = 'beewise-lab-3';
const privateDir = 'D:/CodexTemp/beewise-lab3-tools/bao-cloud-private';
mkdirSync(privateDir, {recursive: true});
const records = [];
const safe = value => String(value).replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[email omitted]').replace(/https?:\/\/\S+/g, '[URL omitted]').slice(0, 500);
const hash = value => createHash('sha256').update(value.replace(/\r\n/g, '\n').trim()).digest('hex');
async function inspect(name, callback) {
  try { records.push({name, timestampUtc: new Date().toISOString(), status: 'PASS', result: await callback()}); }
  catch (error) { records.push({name, timestampUtc: new Date().toISOString(), status: 'BLOCKED', summary: safe(error.message)}); }
}
async function get(origin, apiVersion, path, queryParams) {
  // Paths are constructed from the single allowlisted project, never caller input.
  const response = await new Client({urlPrefix: origin, apiVersion}).get(path, {queryParams, timeout: 30000, resolveOnHTTPError: true});
  if (response.status >= 400) throw Error('HTTP ' + response.status + ': ' + (response.body?.error?.message ?? 'read failed'));
  return response;
}
(async () => {
  const accessible = await firebase.projects.list({project: projectId, nonInteractive: true});
  if (!accessible.some(project => project.projectId === projectId)) throw Error('Correct project not accessible.');
  await inspect('Authentication local providers', async () => {
    const {body} = await get('https://identitytoolkit.googleapis.com/admin', 'v2', `/projects/${projectId}/config`, {fields: 'signIn(email(enabled,passwordRequired),anonymous(enabled))'});
    return {emailPasswordEnabled: body.signIn?.email?.enabled === true, passwordRequired: body.signIn?.email?.passwordRequired,
      anonymousEnabled: body.signIn?.anonymous?.enabled === true, configurationReturned: Boolean(body.signIn)};
  });
  await inspect('Google provider', async () => {
    const {body} = await get('https://identitytoolkit.googleapis.com/admin', 'v2', `/projects/${projectId}/defaultSupportedIdpConfigs/google.com`, {fields: 'enabled,clientId'});
    return {enabled: body.enabled === true, clientIdConfigured: Boolean(body.clientId)};
  });
  await inspect('Storage buckets', async () => {
    const {body} = await get('https://storage.googleapis.com', 'storage/v1', '/b', {project: projectId, maxResults: 100});
    return {buckets: (body.items ?? []).map(bucket => ({name: bucket.name, location: bucket.location, storageClass: bucket.storageClass})), complete: !body.nextPageToken};
  });
  await inspect('Billing state (read only)', async () => {
    const {body} = await get('https://cloudbilling.googleapis.com', 'v1', `/projects/${projectId}/billingInfo`);
    return {billingEnabled: body.billingEnabled === true};
  });
  await inspect('Deployed rules comparison', async () => {
    const releases = await rules.listAllReleases(projectId);
    const results = [];
    for (const [type, release] of [['firestore', 'cloud.firestore'], ['storage', 'firebase.storage']]) {
      const name = await rules.getLatestRulesetName(projectId, release, releases);
      if (!name) { results.push({type, activeReleaseFound: false}); continue; }
      if (!name.startsWith(`projects/${projectId}/rulesets/`)) throw Error('Unexpected rules project.');
      const content = await rules.getRulesetContent(name);
      const text = content?.[0]?.content ?? '';
      writeFileSync(privateDir + `/deployed-${type}.rules`, text);
      const local = readFileSync(resolve(root, `firebase/${type}.rules`), 'utf8');
      results.push({type, activeReleaseFound: true, rulesetName: name, normalizedSha256: hash(text), matchesRepository: hash(text) === hash(local)});
    }
    return results;
  });
  await inspect('Remote Config template', async () => {
    const {body, response} = await get('https://firebaseremoteconfig.googleapis.com', 'v1', `/projects/${projectId}/remoteConfig`);
    writeFileSync(privateDir + '/remote-config-full-original.json', JSON.stringify({template: body, etag: response.headers.get('etag')}, null, 2));
    return {versionNumber: body.version?.versionNumber ?? null, parameterCount: Object.keys(body.parameters ?? {}).length,
      parameters: Object.fromEntries(['home_tutor_limit', 'ai_result_limit', 'ai_matching_enabled', 'gemini_model'].map(key => [key, body.parameters?.[key]?.defaultValue ?? null]))};
  });
  await inspect('Firestore collection names (no document data)', async () => {
    const response = await new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'}).post(
      `/projects/${projectId}/databases/(default)/documents:listCollectionIds`, {pageSize: 100}, {timeout: 30000});
    const expected = ['tutors', 'parents', 'tutorApplications', 'connectionRequests', 'chats', 'invoices', 'paymentVerificationRequests', 'classes'];
    return {expectedCollectionsPresent: Object.fromEntries(expected.map(name => [name, (response.body.collectionIds ?? []).includes(name)])),
      complete: !response.body.nextPageToken, nestedMessagesAndResponses: 'NOT RUN; no personal chat documents inspected'};
  });
  await inspect('Android app registration', async () => {
    const {body} = await get('https://firebase.googleapis.com', 'v1beta1', `/projects/${projectId}/androidApps/1:840483888286:android:50c11fbb460437ed6a2f8f`);
    return {appId: body.appId, packageName: body.packageName, state: body.state};
  });
  await inspect('Android SHA registrations', async () => {
    const {body} = await get('https://firebase.googleapis.com', 'v1beta1', `/projects/${projectId}/androidApps/1:840483888286:android:50c11fbb460437ed6a2f8f/sha`);
    return {certificates: (body.certificates ?? []).map(cert => ({certType: cert.certType, shaHash: cert.shaHash})), complete: !body.nextPageToken};
  });
  await inspect('Firestore composite indexes', async () => {
    const {body} = await get('https://firestore.googleapis.com', 'v1', `/projects/${projectId}/databases/(default)/collectionGroups/-/indexes`);
    return {indexes: (body.indexes ?? []).map(index => ({name: index.name, state: index.state, queryScope: index.queryScope, fields: index.fields})), complete: !body.nextPageToken};
  });
  await inspect('App Check service enforcement', async () => {
    const {body} = await get('https://firebaseappcheck.googleapis.com', 'v1', '/projects/840483888286/services');
    return {services: (body.services ?? []).map(service => ({name: service.name, enforcementMode: service.enforcementMode})), complete: !body.nextPageToken};
  });
  await inspect('App Check Play Integrity provider', async () => {
    const {body} = await get('https://firebaseappcheck.googleapis.com', 'v1', '/projects/840483888286/apps/1:840483888286:android:50c11fbb460437ed6a2f8f/playIntegrityConfig');
    return {settingsReturned: Boolean(body.name), tokenTtl: body.tokenTtl, attestationVerified: false};
  });
  await inspect('Analytics project linkage', async () => {
    const {body} = await get('https://firebase.googleapis.com', 'v1beta1', `/projects/${projectId}/analyticsDetails`);
    return {linked: Boolean(body.analyticsProperty), streamCount: body.streamMappings?.length ?? 0};
  });
  const receipt = {projectId, readOnly: true, records};
  writeFileSync(resolve(root, 'evidence/cloud/live-management-state.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})().catch(error => { console.log(JSON.stringify({status: 'BLOCKED', summary: safe(error.message)})); process.exitCode = 1; });
