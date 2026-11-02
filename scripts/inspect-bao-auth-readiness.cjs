// Read-only metadata, never requests password hashes/salts, emails or tokens.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
require(resolve(base, 'logger')).logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const rules = require(resolve(base, 'gcp/rules'));
const project = 'beewise-lab-3';
const hash = text => createHash('sha256').update(text.replace(/\r\n/g, '\n').trim()).digest('hex');
(async () => {
  const accessible = await firebase.projects.list({project, nonInteractive: true});
  if (!accessible.some(item => item.projectId === project)) throw Error('Expected project not accessible.');
  const client = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'});
  const accounts = [];
  let nextPageToken;
  do {
    const {body} = await client.get(`/projects/${project}/accounts:batchGet`, {queryParams: {
      maxResults: 100, ...(nextPageToken ? {nextPageToken} : {}),
      fields: 'users(localId,disabled,providerUserInfo(providerId),createdAt,lastLoginAt),nextPageToken',
    }, timeout: 30000});
    accounts.push(...(body.users ?? []).map(user => ({
      accountAlias: 'uid-sha256:' + hash(user.localId).slice(0, 16),
      disabled: user.disabled === true,
      providers: (user.providerUserInfo ?? []).map(provider => provider.providerId),
      createdAtUtc: user.createdAt ? new Date(Number(user.createdAt)).toISOString() : null,
      hasPriorSignInTimestamp: Boolean(user.lastLoginAt && Number(user.lastLoginAt) > 0),
    })));
    nextPageToken = body.nextPageToken;
  } while (nextPageToken);
  const releases = await rules.listAllReleases(project);
  const rulesetName = await rules.getLatestRulesetName(project, 'cloud.firestore', releases);
  if (!rulesetName?.startsWith(`projects/${project}/rulesets/`)) throw Error('Unexpected rules release.');
  const files = await rules.getRulesetContent(rulesetName);
  const deployed = files.map(file => file.content ?? '').join('\n');
  const local = readFileSync(resolve(root, 'firebase/firestore.rules'), 'utf8');
  const hasApplicationMatch = text => /match\s+\/tutorApplications\/\{[^}]+\}/.test(text);
  const receipt = {timestampUtc: new Date().toISOString(), projectId: project, readOnly: true,
    credentialFieldsRequested: false, accountMetadata: accounts,
    enabledPasswordAccountCount: accounts.filter(user => !user.disabled && user.providers.includes('password')).length,
    identityScope: 'Metadata confirms account existence/provider only; owner identifies which are authorized test users. This read-only inspection uses no password and does not test login or session.',
    firestore: {rulesetName, deployedSha256: hash(deployed), repositorySha256: hash(local),
      deployedTutorApplicationsMatch: hasApplicationMatch(deployed), repositoryTutorApplicationsMatch: hasApplicationMatch(local),
      consequence: hasApplicationMatch(deployed)
        ? 'Own application match present; still require actual device login/profile/session verification.'
        : 'Auth SDK success is distinct from post-auth application-role read and parent profile creation. Missing match denies that read even when the application document does not exist; never bypass the role check.'},
    actualParentLogin: 'NOT DETERMINED by metadata inspection; see separate deployment and genuine device evidence',
  };
  writeFileSync(resolve(root, 'evidence/cloud/auth-provisioning-readiness.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})().catch(error => { console.log(JSON.stringify({status: 'BLOCKED', summary: String(error.message).replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[email omitted]').replace(/https?:\/\/\S+/g, '[URL omitted]').slice(0, 300)})); process.exitCode = 1; });
