// Actual unauthenticated client SDK query. Uses public Firebase client config,
// never the CLI IAM session. Logs only counts and this workstream's fixture IDs.
const {readFileSync, writeFileSync} = require('node:fs');
const {resolve} = require('node:path');
const root = resolve(__dirname, '..');
const {initializeApp, deleteApp} = require(resolve(root, 'firebase/node_modules/firebase/app'));
const {getFirestore, collection, query, where, limit, getDocsFromServer, doc, getDocFromServer, terminate} = require(resolve(root, 'firebase/node_modules/firebase/firestore'));
if (process.env.FIRESTORE_EMULATOR_HOST) throw Error('Refused emulator redirection for live guest evidence.');
const config = JSON.parse(readFileSync(resolve(root, 'android/app/google-services.json')));
if (config.project_info.project_id !== 'beewise-lab-3') throw Error('Wrong project.');
const client = config.client.find(value => value.client_info.android_client_info.package_name === 'com.beewise.beewise');
const app = initializeApp({projectId: config.project_info.project_id, apiKey: client.api_key[0].current_key, appId: client.client_info.mobilesdk_app_id}, 'bao-guest-evidence');
const db = getFirestore(app);
const records = [];
(async () => {
  try {
    for (let index = 1; index <= 6; index++) {
      const id = `bao-lab3-20261030-tutor-${String(index).padStart(2, '0')}`;
      const snapshot = await getDocFromServer(doc(db, 'tutors', id));
      const data = snapshot.data() ?? {};
      const checks = {exists: snapshot.exists(), active: data.active === true,
        labeled: typeof data.name === 'string' && data.name.startsWith('[TEST]'),
        unverified: data.verified === false, synthetic: data.syntheticTestFixture === true,
        namespace: data.fixtureNamespace === 'bao-lab3-20261030'};
      const passed = Object.values(checks).every(Boolean) && !snapshot.metadata.fromCache;
      records.push({timestampUtc: new Date().toISOString(), id, checks, fromCache: snapshot.metadata.fromCache,
        status: passed ? 'PASS' : 'FAIL'});
      if (!passed) process.exitCode = 1;
    }
    for (const requestedLimit of [6, 2]) {
      const snapshot = await getDocsFromServer(query(collection(db, 'tutors'), where('active', '==', true), limit(requestedLimit)));
      const fixtures = snapshot.docs.filter(doc => doc.id.startsWith('bao-lab3-20261030-tutor-'));
      records.push({timestampUtc: new Date().toISOString(), requestedLimit, returnedCount: snapshot.size,
        fromCache: snapshot.metadata.fromCache, ownFixtureIds: fixtures.map(doc => doc.id),
        ownFixturesRemainUnverified: fixtures.every(doc => doc.data().verified === false && doc.data().syntheticTestFixture === true),
        status: snapshot.size === requestedLimit && !snapshot.metadata.fromCache ? 'PASS' : 'FAIL'});
    }
    // Real read-only negative checks; never create records or use an Auth identity.
    for (const path of ['parents/bao-negative-no-user', 'tutorApplications/bao-negative-no-user',
      'parents/bao-negative-no-user/devices/bao-negative-no-device', 'invoices/bao-negative-no-invoice']) {
      let outcome = 'unexpected-allowed';
      try { await getDocFromServer(doc(db, path)); }
      catch (error) { outcome = String(error.code ?? 'unknown'); }
      const passed = outcome === 'permission-denied';
      records.push({timestampUtc: new Date().toISOString(), test: 'Guest private-document read denied',
        path, outcome, status: passed ? 'PASS' : 'FAIL'});
      if (!passed) process.exitCode = 1;
    }
  } catch (error) {
    records.push({status: 'BLOCKED', summary: String(error.code ?? 'Client query failed')});
    process.exitCode = 1;
  } finally {
    await terminate(db);
    await deleteApp(app);
    const receipt = {projectId: 'beewise-lab-3', authentication: 'No Firebase Auth instance/identity; public client SDK only',
      test: 'Live public tutor queries and read-only guest private-document denials; NOT authenticated cross-account/Remote Config/Android visible behavior', records};
    writeFileSync(resolve(root, 'evidence/cloud/guest-firestore-query.json'), JSON.stringify(receipt, null, 2) + '\n');
    console.log(JSON.stringify(receipt, null, 2));
  }
})();
