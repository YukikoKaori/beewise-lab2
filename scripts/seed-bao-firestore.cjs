// Development-only, explicitly authorized synthetic fixtures. Never imported by app.
// Creates only; cannot overwrite, approve tutors, delete data or target another project.
const {resolve} = require('node:path');
const {writeFileSync} = require('node:fs');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
const projectId = 'beewise-lab-3';
if (!process.argv.includes('--write-fixtures') || process.env.BAO_FIXTURE_PROJECT !== projectId) {
  console.error('Refused. Requires --write-fixtures and BAO_FIXTURE_PROJECT=beewise-lab-3; inspect source first.');
  process.exit(2);
}
require(resolve(base, 'logger')).logger.silent = true;
const firebase = require(resolve(base, 'index'));
const {Client} = require(resolve(base, 'apiv2'));
const namespace = 'bao-lab3-20261030';
const records = [];
const value = item => typeof item === 'boolean' ? {booleanValue: item}
  : typeof item === 'number' ? {integerValue: String(item)}
  : Array.isArray(item) ? {arrayValue: {values: item.map(value)}} : {stringValue: item};
(async () => {
  const accessible = await firebase.projects.list({project: projectId, nonInteractive: true});
  if (!accessible.some(project => project.projectId === projectId)) throw Error('Correct project is not accessible.');
  const client = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  for (let index = 1; index <= 6; index++) {
    const documentId = `${namespace}-tutor-${String(index).padStart(2, '0')}`;
    const fields = {
      name: `[TEST] Gia sư tổng hợp Bảo ${index}`,
      credential: 'Dữ liệu tổng hợp để kiểm thử; không phải gia sư thật',
      introduction: 'SYNTHETIC TEST FIXTURE. Chỉ dùng kiểm thử BeeWise Lab 3, không đặt lịch hay thanh toán thực.',
      subjects: [index % 2 ? 'Toán' : 'Tiếng Anh'], grades: ['8'], hourlyFee: 100000 + index * 10000,
      areas: ['Hà Nội'], teachingModes: ['online'], availability: 'Lịch thử nghiệm; không nhận học sinh thật',
      verified: false, active: true, fixtureNamespace: namespace, syntheticTestFixture: true,
      fixtureProvenance: 'User-authorized Bảo Lab 3 runtime fixture; no personal data',
    };
    const response = await client.post(`/projects/${projectId}/databases/(default)/documents/tutors`,
      {fields: Object.fromEntries(Object.entries(fields).map(([key, item]) => [key, value(item)]))},
      {queryParams: {documentId}, timeout: 30000, resolveOnHTTPError: true});
    records.push({documentId, timestampUtc: new Date().toISOString(), httpStatus: response.status,
      status: response.status === 200 ? 'PASS' : 'BLOCKED', verified: false, syntheticTestFixture: true});
    writeFileSync(resolve(root, 'evidence/cloud/fixture-actions.json'), JSON.stringify({projectId, namespace,
      action: 'Create labeled test tutors only', authorization: 'Explicit user reply permits separate labeled fixtures',
      records, rollback: 'No automatic deletion. Fixtures remain clearly labeled/unverified; removal needs separate user authorization.'}, null, 2) + '\n');
    if (response.status !== 200) throw Error(`Create failed HTTP ${response.status}; no overwrite/retry/delete attempted.`);
  }
  console.log(JSON.stringify({projectId, created: records.length, records}, null, 2));
})().catch(error => { console.error(String(error.message).replace(/https?:\/\/\S+/g, '[URL omitted]')); process.exitCode = 1; });
