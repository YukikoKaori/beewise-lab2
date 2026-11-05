// N-03 ONLY. All identity/catalog setup is local. Workflow states go through
// parent Security Rules + the existing authenticated trusted backend endpoints.
import { createRequire } from 'node:module';
import { parseArgs } from 'node:util';
import { createRuntime } from '../../backend/src/runtime.js';
import { CONSULTANT_CLAIM } from '../../backend/src/auth.js';

const { values } = parseArgs({ options: {
  'execute-local-fixture': { type: 'boolean', default: false },
  'seed-catalog': { type: 'boolean', default: false },
  'fixture-id': { type: 'string' },
  case: { type: 'string' },
} });
if (!values['execute-local-fixture']) throw Error('Explicit local fixture switch required');
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080'
    || process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099'
    || process.env.FIREBASE_PROJECT_ID !== 'beewise-lab-3') {
  throw Error('Refusing non-local or unexpected Firebase target');
}
if (!values['seed-catalog'] && (!['TC-20', 'TC-22'].includes(values.case)
    || !/^n03-tc(?:20|22)-[a-z0-9-]+$/.test(values['fixture-id'] ?? ''))) {
  throw Error('Use a fresh disposable n03-tc20/tc22 fixture ID');
}
const require = createRequire(new URL('../../backend/package.json', import.meta.url));
const { FieldValue } = require('firebase-admin/firestore');
const env = { FIREBASE_PROJECT_ID: 'beewise-lab-3', PUBLIC_BASE_URL: 'http://10.0.2.2:8787' };
const { db, auth } = createRuntime(env);
const projectPath = 'projects/beewise-lab-3/databases/(default)/documents';
const tutorId = 'tutor_acd3824aa8734c63ac8827df';
const tutorName = 'Gia sư kỹ thuật (EMULATOR)';
// Public throwaway emulator-only credentials; never a production identity.
const password = 'n03-local-emulator-only';
const accounts = {
  parent: { uid: 'n03-parent', email: 'n03-parent@beewise.test', displayName: 'Phụ huynh N03 (EMULATOR)' },
  consultant: { uid: 'n03-consultant', email: 'n03-consultant@beewise.test', displayName: 'Tư vấn N03 (EMULATOR)' },
};
async function ensureIdentity(account) {
  try { return await auth.getUser(account.uid); }
  catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    return auth.createUser({ ...account, password, emailVerified: true });
  }
}
for (const account of Object.values(accounts)) await ensureIdentity(account);
await auth.setCustomUserClaims(accounts.consultant.uid, { [CONSULTANT_CLAIM]: true });

async function jsonRequest(url, token, body) {
  const response = await fetch(url, { method: 'POST',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body) });
  if (!response.ok) throw Error(`Local fixture contract failed HTTP ${response.status}`);
  return response.json();
}
async function signIn(account) {
  const result = await jsonRequest('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator-only',
    null, { email: account.email, password, returnSecureToken: true });
  return result.idToken;
}
const parentToken = await signIn(accounts.parent);
const consultantToken = await signIn(accounts.consultant);
const encode = (value) => typeof value === 'string' ? { stringValue: value }
  : typeof value === 'boolean' ? { booleanValue: value }
    : Array.isArray(value) ? { arrayValue: { values: value.map(encode) } }
      : { integerValue: String(value) };
const write = (path, data, stamps = ['createdAt']) => ({
  update: { name: `${projectPath}/${path}`, fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, encode(v)])) },
  updateTransforms: stamps.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
});
const commit = (writes) => jsonRequest(`http://127.0.0.1:8080/v1/${projectPath}:commit`, parentToken, { writes });
await commit([write(`parents/${accounts.parent.uid}`, {
  displayName: accounts.parent.displayName, email: accounts.parent.email,
}, ['createdAt', 'updatedAt'])]);

if (values['seed-catalog']) {
  const ref = db.doc(`tutors/${tutorId}`);
  const existing = await ref.get();
  if (existing.exists) throw Error('Catalog fixture already exists; never overwrite an existing record');
  await ref.create({ name: tutorName, credential: 'Demo kỹ thuật, chưa xác minh chuyên môn',
    introduction: 'Hồ sơ kỹ thuật cục bộ cho kiểm thử N-03; không phải xác minh nghề nghiệp.',
    subjects: ['Toán'], grades: ['8', '10'], hourlyFee: 150000, areas: ['TP.HCM'],
    teachingModes: ['online'], availability: 'Tối thứ 3 và thứ 5', active: true,
    verified: false, demoOnly: true, createdAt: FieldValue.serverTimestamp() });
  console.log(JSON.stringify({ environment: 'EMULATOR', catalogCreated: true, tutorId,
    active: true, verified: false, demoOnly: true }));
  process.exit(0);
}

const chatId = values['fixture-id'];
const requestId = `${chatId}-request`;
if ((await db.doc(`chats/${chatId}`).get()).exists) throw Error('Fixture exists; no reset/overwrite allowed');
await commit([
  write(`connectionRequests/${requestId}`, { parentId: accounts.parent.uid, tutorId, chatId,
    learningGoal: 'Ôn tập Toán N03', area: 'TP.HCM', schedule: 'Tối thứ 3', note: '', status: 'submitted' }),
  write(`chats/${chatId}`, { parentId: accounts.parent.uid, tutorId, consultantQueue: true,
    participantRoles: ['parent', 'tutor', 'consultant'], connectionRequestId: requestId,
    onboardingStatus: 'connection_pending_consultant' }, ['createdAt', 'updatedAt']),
  write(`chats/${chatId}/messages/request_created`, { senderId: 'system', senderName: 'BeeWise',
    role: 'system', kind: 'system',
    body: 'Yêu cầu kết nối đã được gửi. Tư vấn viên BeeWise sẽ tham gia nhóm sau khi xác nhận.' }),
]);
const staff = (suffix, body = {}) => jsonRequest(`http://127.0.0.1:8787/v1/staff/chats/${chatId}/${suffix}`, consultantToken, body);
await staff('claim');
const trial = await staff('trial-proposals', { payload: { tutorName, subject: 'Toán', date: '12/11/2026',
  time: '19:00', mode: 'Trực tuyến', location: 'EMULATOR online', lessonContent: 'Ôn đại số', fee: 0 } });
let revision = null;
if (values.case === 'TC-22') {
  const proposalId = trial.proposalId;
  if (!proposalId) throw Error('Trusted proposal ID missing');
  await commit([write(`chats/${chatId}/responses/${proposalId}`, {
    parentId: accounts.parent.uid, proposalId, type: 'trial_accepted',
  })]);
  await staff(`responses/${proposalId}/process`);
  revision = await staff('class-revisions', { payload: { tutorName, subject: 'Toán', goal: 'Ôn đại số',
    schedule: 'Tối thứ 3 và thứ 5', time: '19:00', mode: 'Trực tuyến', location: 'EMULATOR online',
    startDate: '17/11/2026', lessonDuration: '60 phút', fee: 150000, totalFee: 1200000 } });
}
const chat = (await db.doc(`chats/${chatId}`).get()).data();
const invoices = await db.collection('invoices').where('chatId', '==', chatId).get();
console.log(JSON.stringify({ environment: 'EMULATOR', case: values.case, chatId,
  state: chat.onboardingStatus, trial, revision, invoiceCount: invoices.size,
  note: 'Prerequisite only; no Android assertion or payment success claimed' }));
process.exit(0);
