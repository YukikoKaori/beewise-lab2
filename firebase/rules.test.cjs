const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, getDocFromServer, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp} = require('firebase/firestore');

let env;
const db = (uid = 'alice') => env.authenticatedContext(uid, {
  email: `${uid}@example.test`, firebase: {sign_in_provider: 'password'},
}).firestore();
const parent = (uid = 'alice') => ({displayName: 'Parent', email: `${uid}@example.test`, phone: '0900000000', createdAt: serverTimestamp()});
const application = (uid = 'alice') => ({name: 'Test Tutor', email: `${uid}@example.test`, phone: '0900000000', qualification: 'Degree', introduction: 'Teaching secondary school mathematics.', subjects: ['Toán'], grades: ['8'], hourlyFee: 300000, areas: ['Hà Nội'], teachingModes: ['online'], availability: 'Evenings', status: 'pending', verified: false, active: false, consentAccepted: true, createdAt: serverTimestamp()});
async function seed(records) {
  await env.withSecurityRulesDisabled(async context => {
    for (const [path, data] of Object.entries(records)) await setDoc(doc(context.firestore(), path), data);
  });
}
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-beewise',
    firestore: {rules: readFileSync('firestore.rules', 'utf8')},
  });
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

test('parent bootstrap can read its missing application without exposing another UID', async () => {
  const absent = await assertSucceeds(getDoc(doc(db(), 'tutorApplications/alice')));
  if (absent.exists()) throw Error('Expected an absent application before parent bootstrap.');
  await assertFails(getDoc(doc(db('bob'), 'tutorApplications/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'tutorApplications/alice')));
  await assertSucceeds(setDoc(doc(db(), 'parents/alice'), parent()));
  await assertSucceeds(getDoc(doc(db(), 'parents/alice')));
  await assertFails(getDoc(doc(db('bob'), 'parents/alice')));
});

test('tutor application is private, pending, immutable and never self-approves', async () => {
  const own = doc(db(), 'tutorApplications/alice');
  await assertSucceeds(setDoc(own, application()));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('bob'), 'tutorApplications/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'tutorApplications/alice')));
  await assertFails(updateDoc(own, {status: 'approved', verified: true}));
  await assertFails(deleteDoc(own));
  await assertFails(setDoc(doc(db(), 'parents/alice'), parent()));
  await assertFails(setDoc(doc(db(), 'tutors/alice'), {active: true}));
});
for (const [label, patch] of Object.entries({approved: {status: 'approved'}, verified: {verified: true}, active: {active: true}, consent: {consentAccepted: false}, fee: {hourlyFee: -1}, malformed: {subjects: 'math'}, name: {name: ''}, email: {email: 'bob@example.test'}, time: {createdAt: Timestamp.fromMillis(1)}, extra: {admin: true}})) {
  test(`tutor application rejects ${label}`, async () => {
    await assertFails(setDoc(doc(db(), 'tutorApplications/alice'), {...application(), ...patch}));
  });
}
test('parent and applicant roles cannot be created together in a batch', async () => {
  const store = db(); const batch = writeBatch(store);
  batch.set(doc(store, 'parents/alice'), parent());
  batch.set(doc(store, 'tutorApplications/alice'), application());
  await assertFails(batch.commit());
  // No parent-side write may piggyback on an application-creation batch.
  const deviceBatch = writeBatch(store);
  deviceBatch.set(doc(store, 'tutorApplications/alice'), application());
  deviceBatch.set(doc(store, 'parents/alice/devices/install'), {installationId: 'install', platform: 'android'});
  await assertFails(deviceBatch.commit());
  await seed({'tutors/tutor': {active: true}});
  const connectionBatch = connection(store);
  connectionBatch.set(doc(store, 'tutorApplications/alice'), application());
  await assertFails(connectionBatch.commit());
  await proposal();
  await seed({'invoices/invoice': {parentId: 'alice', status: 'issued'}});
  for (const [path, data] of [
    ['chats/chat/messages/text', {senderId: 'alice', role: 'parent', kind: 'text', body: 'Hello', createdAt: serverTimestamp()}],
    ['chats/chat/responses/proposal', response()],
    ['paymentVerificationRequests/request', {invoiceId: 'invoice', parentId: 'alice', status: 'pending', requestedAt: serverTimestamp()}],
  ]) {
    const mixed = writeBatch(store);
    mixed.set(doc(store, 'tutorApplications/alice'), application());
    mixed.set(doc(store, path), data);
    await assertFails(mixed.commit());
  }
});
test('applicant can detach only their own pre-application device registration', async () => {
  await seed({'parents/alice/devices/install': {installationId: 'install', platform: 'android'}, 'tutorApplications/alice': {status: 'pending'}});
  await assertFails(deleteDoc(doc(db('bob'), 'parents/alice/devices/install')));
  await assertSucceeds(deleteDoc(doc(db(), 'parents/alice/devices/install')));
  await assertFails(setDoc(doc(db(), 'parents/alice/devices/install'), {installationId: 'install', platform: 'android'}));
});
test('parent profile and devices enforce UID, email, fields and platform', async () => {
  const own = doc(db(), 'parents/alice');
  await assertSucceeds(setDoc(own, parent()));
  await assertSucceeds(updateDoc(own, {displayName: 'Updated'}));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('bob'), 'parents/alice')));
  await assertFails(setDoc(own, {...parent(), email: 'bob@example.test'}));
  await assertFails(updateDoc(own, {admin: true}));
  await assertFails(deleteDoc(own));
  await assertFails(setDoc(doc(db(), 'tutorApplications/alice'), application()));
  const device = doc(db(), 'parents/alice/devices/install');
  await assertSucceeds(setDoc(device, {installationId: 'install', platform: 'android', updatedAt: serverTimestamp()}));
  await assertSucceeds(getDoc(device));
  await assertFails(getDoc(doc(db('bob'), 'parents/alice/devices/install')));
  await assertFails(setDoc(device, {installationId: 'other', platform: 'android'}));
  await assertFails(setDoc(device, {installationId: 'install', platform: 'ios'}));
  await assertSucceeds(deleteDoc(device));
});
test('anonymous identity cannot write parent data', async () => {
  const anonymous = env.authenticatedContext('alice', {email: 'alice@example.test', firebase: {sign_in_provider: 'anonymous'}}).firestore();
  await assertFails(setDoc(doc(anonymous, 'parents/alice'), parent()));
  await assertFails(setDoc(doc(anonymous, 'tutorApplications/alice'), application()));
});
test('catalog exposes only active records and prohibits all client writes', async () => {
  await seed({'tutors/active': {active: true}, 'tutors/inactive': {active: false}});
  const guest = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(guest, 'tutors/active')));
  await assertFails(getDoc(doc(guest, 'tutors/inactive')));
  await assertFails(updateDoc(doc(db(), 'tutors/active'), {verified: true}));
  await assertFails(deleteDoc(doc(db(), 'tutors/active')));
});
function connection(store, overrides = {}, chatOverrides = {}) {
  const batch = writeBatch(store);
  batch.set(doc(store, 'connectionRequests/request'), {parentId: 'alice', tutorId: 'tutor', chatId: 'chat', learningGoal: 'Math', area: 'Hanoi', schedule: 'Evening', note: '', status: 'submitted', createdAt: serverTimestamp(), ...overrides});
  batch.set(doc(store, 'chats/chat'), {parentId: 'alice', tutorId: 'tutor', consultantQueue: true, participantRoles: ['parent', 'tutor', 'consultant'], connectionRequestId: 'request', onboardingStatus: 'connection_pending_consultant', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...chatOverrides});
  return batch;
}
test('connection and chat require reciprocal atomic getAfter links', async () => {
  await seed({'tutors/tutor': {active: true}});
  await assertFails(connection(db(), {chatId: 'other'}).commit());
  await assertFails(connection(db(), {}, {tutorId: 'other'}).commit());
  await assertFails(connection(db(), {learningGoal: ''}).commit());
  await assertFails(connection(db('bob')).commit());
  await assertSucceeds(connection(db()).commit());
  await assertSucceeds(getDoc(doc(db(), 'connectionRequests/request')));
  await assertFails(getDoc(doc(db('bob'), 'connectionRequests/request')));
  await assertFails(updateDoc(doc(db(), 'chats/chat'), {onboardingStatus: 'paid'}));
  await assertFails(updateDoc(doc(db(), 'connectionRequests/request'), {status: 'approved'}));
});
test('request without corresponding chat is denied', async () => {
  await seed({'tutors/tutor': {active: true}});
  await assertFails(setDoc(doc(db(), 'connectionRequests/request'), {parentId: 'alice', tutorId: 'tutor', chatId: 'missing', learningGoal: 'Math', area: 'Hanoi', schedule: 'Evening', status: 'submitted', createdAt: serverTimestamp()}));
});
test('parent messages cannot impersonate consultant, change or read another chat', async () => {
  await seed({'chats/chat': {parentId: 'alice'}});
  const own = doc(db(), 'chats/chat/messages/text');
  const message = {senderId: 'alice', senderName: 'Parent', role: 'parent', kind: 'text', body: 'Hello', createdAt: serverTimestamp(), delivery: 'sent'};
  await assertSucceeds(setDoc(own, message));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('bob'), 'chats/chat/messages/text')));
  await assertFails(setDoc(doc(db(), 'chats/chat/messages/fake'), {...message, role: 'consultant', kind: 'trial_proposal'}));
  await assertFails(setDoc(doc(db(), 'chats/chat/messages/empty'), {...message, body: ''}));
  await assertFails(updateDoc(own, {body: 'edited'}));
  await assertFails(deleteDoc(own));
});
const future = () => Timestamp.fromMillis(Date.now() + 3600000);
async function proposal(kind = 'trial_proposal', status = 'pending', expiresAt = future()) {
  await seed({'chats/chat': {parentId: 'alice', onboardingStatus: kind === 'trial_proposal' ? 'trial_proposed' : 'class_revision_pending', currentProposalId: 'proposal', currentRevisionId: 'proposal'}, 'chats/chat/messages/proposal': {role: 'consultant', kind, payload: {status, expiresAt}}});
}
const response = (type = 'trial_accepted', patch = {}) => ({parentId: 'alice', proposalId: 'proposal', type, createdAt: serverTimestamp(), ...patch});
for (const type of ['trial_accepted', 'trial_alternate_time', 'class_adjustment_requested', 'class_revision_confirmed']) {
  test(`eligible ${type} is owner-only, one-time, immutable`, async () => {
    await proposal(type.startsWith('trial_') ? 'trial_proposal' : 'class_revision');
    const data = response(type, {alternateTime: 'Tomorrow', reason: 'Later time'});
    await assertFails(setDoc(doc(db('bob'), 'chats/chat/responses/proposal'), data));
    await assertSucceeds(setDoc(doc(db(), 'chats/chat/responses/proposal'), data));
    await assertSucceeds(getDoc(doc(db(), 'chats/chat/responses/proposal')));
    await assertFails(getDoc(doc(db('bob'), 'chats/chat/responses/proposal')));
    await assertFails(setDoc(doc(db(), 'chats/chat/responses/proposal'), data));
    await assertFails(deleteDoc(doc(db(), 'chats/chat/responses/proposal')));
  });
}
test('responses reject missing, other-chat, stale, expired, wrong-kind and malformed proposals', async () => {
  const target = doc(db(), 'chats/chat/responses/proposal');
  await seed({'chats/chat': {parentId: 'alice'}, 'chats/other/messages/proposal': {role: 'consultant', kind: 'trial_proposal', payload: {status: 'pending', expiresAt: future()}}});
  await assertFails(setDoc(target, response()));
  await proposal('trial_proposal', 'accepted');
  await assertFails(setDoc(target, response()));
  await proposal('trial_proposal', 'pending', Timestamp.fromMillis(1));
  await assertFails(setDoc(target, response()));
  await proposal('class_revision');
  await assertFails(setDoc(target, response()));
  await proposal();
  await assertFails(setDoc(target, response('trial_alternate_time', {alternateTime: ''})));
  await assertFails(setDoc(target, response('paid')));
  await assertFails(setDoc(doc(db(), 'chats/chat/responses/random'), response()));
  await seed({'chats/chat': {parentId: 'alice', onboardingStatus: 'trial_proposed', currentProposalId: 'new-proposal'}});
  await assertFails(setDoc(target, response()));
});

test('concurrent duplicate responses admit one immutable response only', async () => {
  await proposal();
  const results = await Promise.allSettled([
    setDoc(doc(db(), 'chats/chat/responses/proposal'), response()),
    setDoc(doc(db(), 'chats/chat/responses/proposal'), response()),
  ]);
  require('node:assert/strict').equal(results.filter(result => result.status === 'fulfilled').length, 1);
  const rejected = results.find(result => result.status === 'rejected');
  require('node:assert/strict').equal(rejected.reason.code, 'permission-denied');
  const stored = await assertSucceeds(getDoc(doc(db(), 'chats/chat/responses/proposal')));
  require('node:assert/strict').equal(stored.data().type, 'trial_accepted');
});
test('invoice verification and official schedule are trusted backend only', async () => {
  await seed({'invoices/invoice': {parentId: 'alice', status: 'issued'}, 'classes/verified': {parentId: 'alice', paymentStatus: 'verified'}, 'classes/unverified': {parentId: 'alice', paymentStatus: 'pending'}});
  await assertSucceeds(getDoc(doc(db(), 'invoices/invoice')));
  await assertFails(getDoc(doc(db('bob'), 'invoices/invoice')));
  await assertFails(updateDoc(doc(db(), 'invoices/invoice'), {status: 'paid'}));
  await assertFails(setDoc(doc(db(), 'invoices/new'), {parentId: 'alice'}));
  const data = {invoiceId: 'invoice', parentId: 'alice', status: 'pending', requestedAt: serverTimestamp()};
  await assertSucceeds(setDoc(doc(db(), 'paymentVerificationRequests/request'), data));
  await assertSucceeds(getDoc(doc(db(), 'paymentVerificationRequests/request')));
  await assertFails(getDoc(doc(db('bob'), 'paymentVerificationRequests/request')));
  await assertFails(setDoc(doc(db('bob'), 'paymentVerificationRequests/other'), {...data, parentId: 'bob'}));
  await assertFails(setDoc(doc(db(), 'paymentVerificationRequests/paid'), {...data, status: 'verified'}));
  await assertFails(updateDoc(doc(db(), 'paymentVerificationRequests/request'), {status: 'verified'}));
  await assertSucceeds(getDoc(doc(db(), 'classes/verified')));
  await assertFails(getDoc(doc(db(), 'classes/unverified')));
  await assertFails(getDoc(doc(db('bob'), 'classes/verified')));
  await assertFails(updateDoc(doc(db(), 'classes/unverified'), {paymentStatus: 'verified'}));
});

test('F-03 backend ledgers (payOS orders, webhooks, references, receipts) are server-only', async () => {
  const ledgers = {
    'paymentOrders/1000001': {parentId: 'alice', invoiceId: 'invoice', amount: 2000000, status: 'pending', checkoutUrl: 'https://pay.payos.vn/web/x'},
    'payosWebhookEvents/evt': {orderCode: 1000001, status: 'processed'},
    'payosTransactions/ref': {orderCode: 1000001, invoiceId: 'invoice'},
    'workflowReceipts/chat__proposal': {chatId: 'chat', proposalId: 'proposal', result: {outcome: 'trial_accepted'}},
  };
  await seed(ledgers);
  for (const path of Object.keys(ledgers)) {
    await assertFails(getDoc(doc(db(), path)));
    await assertFails(setDoc(doc(db(), path), {parentId: 'alice', status: 'paid'}));
    await assertFails(setDoc(doc(db(), `${path}-new`), {parentId: 'alice'}));
    await assertFails(deleteDoc(doc(db(), path)));
  }
  // A parent cannot forge a verified invoice or schedule for itself either.
  await assertFails(setDoc(doc(db(), 'invoices/inv_forged'), {parentId: 'alice', status: 'verified', amount: 1}));
  await assertFails(setDoc(doc(db(), 'classes/cls_forged'), {parentId: 'alice', paymentStatus: 'verified'}));
});

// The obsolete Storage terminal/ownership cases are replaced by the actual
// Firestore persistence contract; all existing Firestore regressions remain.
const reportId = 'abcdefghijklmnopqrst';
const reportPath = (uid = 'alice', id = reportId) => `reports/${uid}/files/${id}`;
const report = (uid = 'alice', patch = {}) => ({
  ownerUid: uid, reportId, tutorId: 'tutor', fileName: 'beewise-tutor-tutor.pdf',
  contentType: 'application/pdf', encoding: 'base64', sizeBytes: 9,
  base64Data: Buffer.from('%PDF-1.4\n').toString('base64'), createdAt: serverTimestamp(), ...patch,
});
async function permittedTutor() { await seed({'tutors/tutor': {active: true, verified: true}}); }
for (const uid of ['alice', 'bob']) {
  test(`parent ${uid} creates, server-reads and lists own immutable report`, async () => {
    await permittedTutor();
    const store=db(uid), target=doc(store, reportPath(uid));
    await assertSucceeds(setDoc(target, report(uid)));
    const saved=await assertSucceeds(getDocFromServer(target));
    require('node:assert/strict').deepEqual(Buffer.from(saved.data().base64Data,'base64'), Buffer.from('%PDF-1.4\n'));
    const {getDocsFromServer, collection}=require('firebase/firestore');
    await assertSucceeds(getDocsFromServer(collection(store,`reports/${uid}/files`)));
    await assertFails(updateDoc(target,{fileName:'other.pdf'}));
    await assertFails(setDoc(target,report(uid)));
    await assertFails(deleteDoc(target));
  });
}
test('guest, anonymous and cross-UID reports are denied in both directions', async () => {
  await permittedTutor();
  await assertSucceeds(setDoc(doc(db(),reportPath()),report()));
  await assertSucceeds(setDoc(doc(db('bob'),reportPath('bob')),report('bob')));
  const anonymous=env.authenticatedContext('alice',{firebase:{sign_in_provider:'anonymous'}}).firestore();
  for (const store of [env.unauthenticatedContext().firestore(),anonymous,db('bob')]) {
    await assertFails(getDocFromServer(doc(store,reportPath())));
    await assertFails(setDoc(doc(store,reportPath('alice','12345678901234567890')),report('alice',{reportId:'12345678901234567890'})));
    await assertFails(updateDoc(doc(store,reportPath()),{sizeBytes:1}));
    await assertFails(deleteDoc(doc(store,reportPath())));
  }
  await assertFails(getDocFromServer(doc(db(),reportPath('bob'))));
  await assertFails(setDoc(doc(db(),reportPath('bob','12345678901234567890')),report('bob',{reportId:'12345678901234567890'})));
  await assertFails(updateDoc(doc(db(),reportPath('bob')),{sizeBytes:1}));
  await assertFails(deleteDoc(doc(db(),reportPath('bob'))));
});
test('applicants cannot access parent reports or piggyback creation in a batch', async () => {
  await permittedTutor();
  await seed({'tutorApplications/alice': {status:'pending'}});
  await assertFails(setDoc(doc(db(),reportPath()),report()));
  await assertFails(getDocFromServer(doc(db(),reportPath())));
  const store=db('bob'), batch=writeBatch(store);
  batch.set(doc(store,'tutorApplications/bob'),application('bob'));
  batch.set(doc(store,reportPath('bob')),report('bob'));
  await assertFails(batch.commit());
});
const invalidReports = {
  'oversized bytes': {sizeBytes:512001},
  'oversized Base64': {base64Data:'JVBERi0'+'A'.repeat(682669)},
  'zero bytes':{sizeBytes:0}, 'negative bytes':{sizeBytes:-1}, 'fractional bytes':{sizeBytes:9.5},
  'wrong MIME':{contentType:'text/plain'}, 'wrong encoding':{encoding:'raw'},
  'wrong owner':{ownerUid:'bob'}, 'wrong report ID':{reportId:'other'},
  'unexpected field':{email:'not-allowed@example.test'}, 'stale timestamp':{createdAt:Timestamp.fromMillis(1)},
  'missing timestamp':{createdAt:null}, 'empty Base64':{base64Data:''},
  'bad PDF header':{base64Data:Buffer.from('not a pdf').toString('base64')},
  'invalid Base64 alphabet':{base64Data:'JVBERi0!!!!!'},
  'inconsistent byte length':{sizeBytes:500},
  'filename traversal':{fileName:'../../x.pdf'}, 'filename mismatch':{fileName:'other.pdf'},
  'invalid filename type':{fileName:42}, 'invalid tutor type':{tutorId:[]},
  'invalid tutor length':{tutorId:'a'.repeat(129)}, 'invalid tutor path':{tutorId:'../tutor'},
};
for(const [label,patch] of Object.entries(invalidReports)) {
  test(`report rejects ${label}`,async()=>{
    await permittedTutor();
    await assertFails(setDoc(doc(db(),reportPath()),report('alice',patch)));
  });
}
test('report requires every field and a valid document ID',async()=>{
  await permittedTutor();
  for(const field of Object.keys(report())) {
    const data=report(); delete data[field];
    await assertFails(setDoc(doc(db(),reportPath()),data));
  }
  await assertFails(setDoc(doc(db(),reportPath('alice','bad')),report('alice',{reportId:'bad'})));
});
test('500 KiB PDF bound succeeds and content is byte-exact',async()=>{
  await permittedTutor();
  const bytes=Buffer.alloc(512000,32); bytes.write('%PDF-1.4\n');
  await assertSucceeds(setDoc(doc(db(),reportPath()),report('alice',{sizeBytes:bytes.length,base64Data:bytes.toString('base64')})));
  const saved=await assertSucceeds(getDocFromServer(doc(db(),reportPath())));
  require('node:assert/strict').deepEqual(Buffer.from(saved.data().base64Data,'base64'),bytes);
});
test('unverified, inactive and synthetic tutor reports are denied',async()=>{
  for(const tutor of [{active:true,verified:false},{active:false,verified:true},{active:true,verified:true,syntheticTestFixture:true},{active:true,verified:true,fixtureNamespace:'test'}]) {
    await seed({'tutors/tutor':tutor});
    await assertFails(setDoc(doc(db(),reportPath()),report()));
  }
  await seed({'tutors/bao-lab3-test':{active:true,verified:true}});
  await assertFails(setDoc(doc(db(),reportPath()),report('alice',{tutorId:'bao-lab3-test',fileName:'beewise-tutor-bao-lab3-test.pdf'})));
});
test('concurrent duplicate IDs admit one creation only',async()=>{
  await permittedTutor();
  const results=await Promise.allSettled([setDoc(doc(db(),reportPath()),report()),setDoc(doc(db(),reportPath()),report())]);
  require('node:assert/strict').equal(results.filter(r=>r.status==='fulfilled').length,1);
});

test('exact consented demo remains unverified and owner-private; no general demo bypass', async()=>{
  const id='tutor_acd3824aa8734c63ac8827df';
  const allowed={active:true,verified:false,demoOnly:true};
  const data=report('alice',{tutorId:id,fileName:`beewise-tutor-${id}.pdf`});
  // Reject every variant before creating one report at the existing target.
  for(const patch of [{active:false},{verified:true},{demoOnly:false},{demoOnly:'true'},{syntheticTestFixture:true},{fixtureNamespace:'fixture'},{fixtureNamespace:' '}]) {
    await seed({[`tutors/${id}`]:{...allowed,...patch}});
    await assertFails(setDoc(doc(db(),reportPath()),data));
  }
  await seed({'tutors/other-demo':allowed});
  await assertFails(setDoc(doc(db(),reportPath()),report('alice',{tutorId:'other-demo',fileName:'beewise-tutor-other-demo.pdf'})));
  await seed({[`tutors/${id}`]:allowed});
  await assertFails(updateDoc(doc(db(),`tutors/${id}`),{demoOnly:true,verified:true}));
  await assertFails(setDoc(doc(db('bob'),reportPath()),data));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(),reportPath()),data));
  await assertSucceeds(setDoc(doc(db(),reportPath()),data));
  await assertSucceeds(getDocFromServer(doc(db(),reportPath())));
  await assertFails(getDocFromServer(doc(db('bob'),reportPath())));
  await assertFails(updateDoc(doc(db(),reportPath()),{sizeBytes:10}));
  await assertFails(deleteDoc(doc(db(),reportPath())));
});

const approvedTutor = (extra = {}) => ({...{name: 'Tutor', status: 'approved', verified: true, active: true}, ...extra});
test('approved tutor reads only their own chats, messages and classes', async () => {
  await seed({
    'tutorApplications/tutor1': approvedTutor(),
    'tutorApplications/tutor2': approvedTutor(),
    'chats/c1': {parentId: 'alice', tutorId: 'tutor1'},
    'chats/c1/messages/m1': {senderId: 'alice', role: 'parent', kind: 'text', body: 'hi'},
    'chats/c2': {parentId: 'bob', tutorId: 'tutor2'},
    'classes/k1': {parentId: 'alice', tutorId: 'tutor1', paymentStatus: 'pending'},
    'classes/k2': {parentId: 'bob', tutorId: 'tutor2', paymentStatus: 'verified'},
  });
  await assertSucceeds(getDoc(doc(db('tutor1'), 'chats/c1')));
  await assertSucceeds(getDoc(doc(db('tutor1'), 'chats/c1/messages/m1')));
  await assertSucceeds(getDoc(doc(db('tutor1'), 'classes/k1')));
  await assertFails(getDoc(doc(db('tutor1'), 'chats/c2')));
  await assertFails(getDoc(doc(db('tutor1'), 'classes/k2')));
  await assertFails(getDoc(doc(db('tutor2'), 'chats/c1/messages/m1')));
});
test('tutor workspace queries by own tutorId are allowed, other UIDs denied', async () => {
  const {collection, query, where, getDocs} = require('firebase/firestore');
  await seed({
    'tutorApplications/tutor1': approvedTutor(),
    'chats/c1': {parentId: 'alice', tutorId: 'tutor1'},
    'classes/k1': {parentId: 'alice', tutorId: 'tutor1', paymentStatus: 'pending'},
  });
  await assertSucceeds(getDocs(query(collection(db('tutor1'), 'chats'), where('tutorId', '==', 'tutor1'))));
  await assertSucceeds(getDocs(query(collection(db('tutor1'), 'classes'), where('tutorId', '==', 'tutor1'))));
  await assertFails(getDocs(query(collection(db('tutor1'), 'chats'), where('tutorId', '==', 'tutor2'))));
});
test('pending, unverified, inactive, rejected tutors and non-tutors get no workspace access', async () => {
  await seed({
    'tutorApplications/pend': approvedTutor({status: 'pending'}),
    'tutorApplications/unver': approvedTutor({verified: false}),
    'tutorApplications/inact': approvedTutor({active: false}),
    'tutorApplications/rej': approvedTutor({status: 'rejected'}),
    'chats/cp': {parentId: 'alice', tutorId: 'pend'},
    'chats/cu': {parentId: 'alice', tutorId: 'unver'},
    'chats/ci': {parentId: 'alice', tutorId: 'inact'},
    'chats/cr': {parentId: 'alice', tutorId: 'rej'},
    'chats/cx': {parentId: 'alice', tutorId: 'nobody'},
    'classes/kp': {parentId: 'alice', tutorId: 'pend', paymentStatus: 'verified'},
  });
  for (const [uid, chat] of [['pend', 'cp'], ['unver', 'cu'], ['inact', 'ci'], ['rej', 'cr'], ['nobody', 'cx']]) {
    await assertFails(getDoc(doc(db(uid), `chats/${chat}`)));
  }
  await assertFails(getDoc(doc(db('pend'), 'classes/kp')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'chats/cp')));
});
test('tutors remain read-only: no writes to chats, messages, classes or own approval', async () => {
  await seed({
    'tutorApplications/tutor1': approvedTutor(),
    'chats/c1': {parentId: 'alice', tutorId: 'tutor1'},
    'classes/k1': {parentId: 'alice', tutorId: 'tutor1', paymentStatus: 'pending'},
  });
  await assertFails(setDoc(doc(db('tutor1'), 'chats/c1/messages/m9'), {senderId: 'tutor1', role: 'tutor', kind: 'text', body: 'x', createdAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(db('tutor1'), 'classes/k1'), {paymentStatus: 'verified'}));
  await assertFails(updateDoc(doc(db('tutor1'), 'chats/c1'), {tutorId: 'tutor1', parentId: 'tutor1'}));
  await assertFails(updateDoc(doc(db('tutor1'), 'tutorApplications/tutor1'), {active: true}));
});
test('parent access to chats and classes is unchanged', async () => {
  await seed({
    'chats/c1': {parentId: 'alice', tutorId: 'tutor1'},
    'classes/ok': {parentId: 'alice', tutorId: 'tutor1', paymentStatus: 'verified'},
    'classes/no': {parentId: 'alice', tutorId: 'tutor1', paymentStatus: 'pending'},
  });
  await assertSucceeds(getDoc(doc(db('alice'), 'chats/c1')));
  await assertSucceeds(getDoc(doc(db('alice'), 'classes/ok')));
  await assertFails(getDoc(doc(db('alice'), 'classes/no')));
  await assertFails(getDoc(doc(db('bob'), 'chats/c1')));
});

test('notification inbox is owner-read-only and never client-writable', async () => {
  const {collection, query, orderBy, getDocs, addDoc} = require('firebase/firestore');
  await seed({
    'users/alice/notifications/n1': {recipientUid: 'alice', title: 'Xin chào', body: 'x', route: '/home', read: false},
    'users/bob/notifications/n2': {recipientUid: 'bob', title: 'Của Bob', body: 'x', route: '/home', read: false},
  });
  await assertSucceeds(getDoc(doc(db('alice'), 'users/alice/notifications/n1')));
  await assertSucceeds(getDocs(query(collection(db('alice'), 'users/alice/notifications'), orderBy('createdAt', 'desc'))).catch(() => getDocs(collection(db('alice'), 'users/alice/notifications'))));
  await assertFails(getDoc(doc(db('alice'), 'users/bob/notifications/n2')));
  await assertFails(getDoc(doc(db('bob'), 'users/alice/notifications/n1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice/notifications/n1')));
  await assertFails(setDoc(doc(db('alice'), 'users/alice/notifications/forged'), {recipientUid: 'alice', title: 'Giả', body: 'x', route: '/home', read: false}));
  await assertFails(addDoc(collection(db('alice'), 'users/alice/notifications'), {title: 'Giả'}));
  await assertFails(updateDoc(doc(db('alice'), 'users/alice/notifications/n1'), {read: true}));
  await assertFails(deleteDoc(doc(db('alice'), 'users/alice/notifications/n1')));
  await assertFails(setDoc(doc(db('alice'), 'users/bob/notifications/forged'), {title: 'Giả'}));
});

// Final uses the Google sign-in provider and a verified ID-token email as well
// as the role document; legacy consultant claims cannot confer reviewer access.
const staffDb = (uid = 'staff', provider = 'google.com', verified = true) =>
  env.authenticatedContext(uid, {
    email: `${uid}@example.test`, email_verified: verified,
    firebase: {sign_in_provider: provider},
  }).firestore();
const staffRoles = {'users/staff': {role: 'staff'}, 'users/admin': {role: 'admin'}};
function reviewBatch(store, reviewer, status, reason, id = 'reviewReceipt0000001') {
  const batch = writeBatch(store);
  batch.update(doc(store, 'tutorApplications/alice'), {
    status, verified: status === 'approved', active: status === 'approved',
    reviewedBy: reviewer, reviewedAt: serverTimestamp(), reviewReason: reason, latestReviewId: id,
  });
  batch.set(doc(store, `tutorApplications/alice/reviews/${id}`), {
    status, reviewerUid: reviewer, reason, createdAt: serverTimestamp(),
  });
  return batch;
}

test('Final roles: safe bootstrap, admin grant/revoke, no self promotion, wrong provider denied', async () => {
  await seed(staffRoles);
  const own = doc(db(), 'users/alice');
  await assertFails(setDoc(own, {role: 'staff', displayName: 'Applicant'}));
  await assertSucceeds(setDoc(own, {role: 'user', displayName: 'Applicant'}));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('bob'), 'users/alice')));
  const rolePatch = {role: 'staff', roleChangedAt: serverTimestamp(), roleChangedBy: 'admin'};
  await assertFails(updateDoc(own, rolePatch));
  await assertFails(updateDoc(doc(staffDb('staff'), 'users/alice'), rolePatch));
  await assertFails(updateDoc(doc(staffDb('admin'), 'users/admin'), {...rolePatch, role: 'user'}));
  await assertFails(updateDoc(doc(staffDb('admin', 'password'), 'users/alice'), rolePatch));
  await assertFails(updateDoc(doc(staffDb('admin', 'google.com', false), 'users/alice'), rolePatch));
  await assertSucceeds(updateDoc(doc(staffDb('admin'), 'users/alice'), rolePatch));
  await assertSucceeds(updateDoc(doc(staffDb('admin'), 'users/alice'), {...rolePatch, role: 'user'}));
});

test('Final review: only valid atomic review, one competing writer wins, receipt is owner-private and immutable', async () => {
  await seed(staffRoles);
  await assertSucceeds(setDoc(doc(db(), 'tutorApplications/alice'), application()));
  await assertSucceeds(getDoc(doc(staffDb(), 'tutorApplications/alice')));
  await assertFails(getDoc(doc(db('bob'), 'tutorApplications/alice')));
  await assertFails(updateDoc(doc(staffDb(), 'tutorApplications/alice'), {status: 'approved', verified: true, active: true}));
  await assertFails(reviewBatch(staffDb(), 'staff', 'rejected', '   ').commit());
  await assertFails(reviewBatch(db(), 'alice', 'approved', 'Credentials checked').commit());
  await assertFails(reviewBatch(staffDb('staff','password'), 'staff', 'approved', 'Credentials checked').commit());
  const results = await Promise.allSettled([
    reviewBatch(staffDb(), 'staff', 'approved', 'Credentials checked').commit(),
    reviewBatch(staffDb('admin'), 'admin', 'rejected', 'Missing credential', 'reviewReceipt0000002').commit(),
  ]);
  if (results.filter(r => r.status === 'fulfilled').length !== 1) throw Error('Expected one committed review');
  const app = await getDocFromServer(doc(db(), 'tutorApplications/alice'));
  const path = `tutorApplications/alice/reviews/${app.data().latestReviewId}`;
  await assertSucceeds(getDoc(doc(db(), path)));
  await assertFails(getDoc(doc(db('bob'), path)));
  await assertFails(deleteDoc(doc(staffDb(), path)));
});

test('Final resubmission: correct only needs-info using the same UID, retaining reviewer data', async () => {
  await seed(staffRoles);
  const own = doc(db(), 'tutorApplications/alice');
  await assertSucceeds(setDoc(own, application()));
  await assertSucceeds(reviewBatch(staffDb(), 'staff', 'needs_info', 'Clarify availability').commit());
  const patch = {status: 'pending', updatedAt: serverTimestamp(), availability: 'Weekends'};
  await assertFails(updateDoc(own, {...patch, reviewedBy: 'alice'}));
  await assertFails(updateDoc(own, {...patch, email: 'bob@example.test'}));
  await assertFails(updateDoc(own, {...patch, grades: [7]}));
  await assertFails(updateDoc(doc(db('bob'), 'tutorApplications/alice'), patch));
  await assertSucceeds(updateDoc(own, patch));
  await assertSucceeds(reviewBatch(staffDb(), 'staff', 'approved', 'Credentials checked', 'reviewReceipt0000002').commit());
});

test('Final catalog: only approved UID, guarded archive and no privileged field or legacy demo edit', async () => {
  await seed({...staffRoles, 'tutors/tutor_acd3824aa8734c63ac8827df': {active: true, verified: false, demoOnly: true}});
  const managed = doc(staffDb(), 'tutors/alice');
  const listing = {applicationUid: 'alice', managedByFinal: true, name: 'Test Tutor',
    credential: 'Degree', introduction: 'Teaching secondary school mathematics.',
    subjects: ['Toán'], grades: ['8'], hourlyFee: 300000, areas: ['Hà Nội'],
    teachingModes: ['online'], availability: 'Evenings', active: true, verified: true,
    publishedAt: serverTimestamp(), updatedAt: serverTimestamp()};
  await assertFails(setDoc(managed, listing));
  await assertSucceeds(setDoc(doc(db(), 'tutorApplications/alice'), application()));
  await assertFails(setDoc(managed, listing));
  await assertSucceeds(reviewBatch(staffDb(), 'staff', 'approved', 'Credentials checked').commit());
  await assertFails(setDoc(managed, {...listing, applicationUid: 'bob'}));
  await assertFails(setDoc(managed, {...listing, reviewCount: 100}));
  await assertFails(setDoc(managed, {...listing, subjects: [{unexpected: true}]}));
  await assertFails(setDoc(doc(db(), 'tutors/alice'), listing));
  await assertSucceeds(setDoc(managed, listing));
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'tutors/alice')));
  await assertFails(updateDoc(managed, {verified: false, updatedAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(staffDb(), 'tutors/tutor_acd3824aa8734c63ac8827df'), {active: false, updatedAt: serverTimestamp()}));
  await assertSucceeds(updateDoc(managed, {active: false, updatedAt: serverTimestamp()}));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'tutors/alice')));
  await assertSucceeds(getDoc(doc(db(), 'tutors/alice')));
});

test('Final announcements: signed-in published query, staff author and timestamp, revocation and immutable record', async () => {
  await seed({...staffRoles, 'announcements/draft': {status: 'draft', title: 'Hidden'}});
  const data = {status: 'published', title: 'Schedule update', body: 'Support hours changed.',
    authorUid: 'staff', createdAt: serverTimestamp()};
  const notice = doc(staffDb(), 'announcements/notice');
  await assertFails(setDoc(doc(db(), 'announcements/notice'), {...data, authorUid: 'alice'}));
  await assertFails(setDoc(notice, {...data, authorUid: 'admin'}));
  await assertFails(setDoc(notice, {...data, body: ''}));
  await assertSucceeds(setDoc(notice, data));
  await assertSucceeds(getDoc(doc(db(), 'announcements/notice')));
  await assertFails(getDoc(doc(db(), 'announcements/draft')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'announcements/notice')));
  await assertFails(updateDoc(notice, {body: 'Changed'}));
  await seed({'users/staff': {role: 'user'}});
  await assertFails(setDoc(doc(staffDb(), 'announcements/revoked'), data));
});

const localReportPath = (uid = 'alice') => `reports/${uid}/localFiles/${reportId}`;
const localReport = (uid = 'alice', patch = {}) => ({
  ownerUid: uid, reportId, tutorId: 'tutor',
  fileName: `beewise-report-${reportId}.pdf`, contentType: 'application/pdf',
  sizeBytes: 19356, createdAt: serverTimestamp(), ...patch,
});
test('Final PDF sync writes metadata only, isolated and immutable; legacy PDF remains readable', async () => {
  await permittedTutor();
  const alice = db(), bob = db('bob');
  await assertSucceeds(setDoc(doc(alice,reportPath()),report()));
  const target = doc(alice,localReportPath());
  await assertSucceeds(setDoc(target, localReport()));
  const saved = await assertSucceeds(getDocFromServer(target));
  require('node:assert/strict').deepEqual(Object.keys(saved.data()).sort(),
    ['contentType','createdAt','fileName','ownerUid','reportId','sizeBytes','tutorId']);
  await assertSucceeds(getDocFromServer(doc(alice,reportPath())));
  await assertFails(getDocFromServer(doc(bob,localReportPath())));
  await assertFails(setDoc(doc(bob,localReportPath()), localReport()));
  await assertFails(updateDoc(target,{sizeBytes:123}));
  await assertFails(deleteDoc(target));
  const guest = env.unauthenticatedContext().firestore();
  const anonymous = env.authenticatedContext('alice',{firebase:{sign_in_provider:'anonymous'}}).firestore();
  for (const store of [guest, anonymous]) {
    await assertFails(getDocFromServer(doc(store,localReportPath())));
    await assertFails(setDoc(doc(store,localReportPath('bob')),localReport('bob')));
  }
});

test('Final PDF metadata denies bytes, path injection, foreign owners and applicant writes', async () => {
  await permittedTutor();
  const target = doc(db(),localReportPath());
  for (const patch of [
    {base64Data:'JVBERi0='}, {encoding:'base64'}, {localPath:'/data/file.pdf'},
    {fileName:'../file.pdf'}, {ownerUid:'bob'}, {tutorId:'../tutor'},
    {sizeBytes:512001}, {sizeBytes:0}, {createdAt:null},
  ]) await assertFails(setDoc(target, localReport('alice',patch)));
  await seed({'tutorApplications/alice':{status:'pending'}});
  await assertFails(setDoc(target, localReport()));
});

const manualChatA = 'FinalChatCase0000001';
const manualChatB = 'FinalChatCase0000002';
const manualClaimA = 'ManualClaim000000001';
const manualClaimB = 'ManualClaim000000002';
const manualRefA = 'BWTESTREFERENCE001';
const manualRefB = 'BWTESTREFERENCE002';
const testRecipient = {bankBin:'000000', accountNumber:'000000000', accountHolder:'EMULATOR ONLY', instructions:''};
const manualPath = (id=manualChatA) => `finalPayments/${id}`;
const manualClass = (id=manualChatA) => `classes/vietqr_${id}`;
const manualAudit = (id=manualChatA, claim=manualClaimA) => `${manualPath(id)}/reviews/${claim}`;

async function seedManual() {
  const chat = (parentId) => ({parentId,tutorId:'tutor',paymentMode:'manual_vietqr',onboardingStatus:'final_waiting_class_offer',consultantQueue:false});
  await seed({
    'users/staff':{role:'staff'}, 'users/admin':{role:'admin'}, 'users/revoked':{role:'user'},
    'tutorApplications/tutor':{status:'approved',active:true,verified:true},
    'tutors/tutor':{name:'Emulator Tutor',active:true,verified:true},
    'settings/paymentRecipient':testRecipient,
    [`chats/${manualChatA}`]:chat('alice'), [`chats/${manualChatB}`]:chat('bob'),
    'invoices/legacy-verified':{parentId:'alice',status:'verified',classId:'legacy-class'},
    'classes/legacy-class':{parentId:'alice',tutorId:'tutor',paymentStatus:'verified'},
  });
}

function offerBatch(store, {id=manualChatA, reference=manualRefA, parentId='alice', staff='staff', patch={}, reserve=true}={}) {
  const b=writeBatch(store);
  b.set(doc(store,manualPath(id)),{
    invoiceId:id,chatId:id,parentId,tutorId:'tutor',subject:'Mathematics',tutorName:'Emulator Tutor',
    date:'2030-02-14',time:'18:30',location:'Online',amount:150000,currency:'VND',
    recipient:testRecipient,transferReference:reference,
    expiresAt:Timestamp.fromMillis(Date.now()+86400000),
    createdAt:serverTimestamp(),offeredBy:staff,status:'offered',...patch,
  });
  if (reserve) b.set(doc(store,`finalTransferReferences/${reference}`),{invoiceId:id});
  return b;
}

const acceptManual = (store, id=manualChatA) =>
  updateDoc(doc(store,manualPath(id)),{status:'awaiting_transfer',acceptedAt:serverTimestamp()});
const claimManual = (store, id=manualChatA, claim=manualClaimA) =>
  updateDoc(doc(store,manualPath(id)),{status:'awaiting_verification',claimId:claim,
    claimedAt:serverTimestamp(),rejectedReason:require('firebase/firestore').deleteField()});

function decideManual(store, {id=manualChatA, claim=manualClaimA, staff='staff', parent='alice',
  ref=manualRefA, receipt='000000_FIXTURE00001', verify=true, withClass=true,
  withAudit=true, amount=150000, reviewer=staff, reason='No matching bank entry',}={}) {
  const b=writeBatch(store);
  const audit={invoiceId:id,claimId:claim,status:verify?'verified':'rejected',
    reviewedBy:reviewer,reviewedAt:serverTimestamp()};
  if (verify) {
    b.update(doc(store,manualPath(id)),{
      status:'verified',classId:`vietqr_${id}`,verifiedBy:staff,verifiedAt:serverTimestamp(),
      verificationMethod:'manual_bank_transfer',
    });
    Object.assign(audit,{bankReceiptId:receipt,matchedAmount:amount,matchedReference:ref});
    b.set(doc(store,`finalBankReceipts/${receipt}`),{invoiceId:id,claimId:claim});
    if(withClass) b.set(doc(store,manualClass(id)),{
      invoiceId:id,chatId:id,parentId:parent,tutorId:'tutor',paymentStatus:'verified',
      subject:'Mathematics',tutorName:'Emulator Tutor',date:'2030-02-14',
      time:'18:30',location:'Online',totalFee:150000,createdAt:serverTimestamp(),
    });
  } else {
    b.update(doc(store,manualPath(id)),{status:'rejected',rejectedReason:reason});
    audit.reason=reason;
  }
  if (withAudit) b.set(doc(store,manualAudit(id,claim)),audit);
  return b;
}

test('VietQR issuance: trusted chat-bound offer and unique immutable reference', async () => {
  await seedManual();
  const staff=staffDb(), alice=db(), bob=db('bob');
  await assertSucceeds(getDocFromServer(doc(alice,manualPath())));
  await assertFails(getDocFromServer(doc(bob,manualPath())));
  await assertFails(getDocFromServer(doc(alice,'settings/paymentRecipient')));
  await assertFails(setDoc(doc(staff,'settings/paymentRecipient'),testRecipient));
  await assertFails(offerBatch(alice).commit());
  await assertFails(offerBatch(staff,{parentId:'bob'}).commit());
  await assertFails(offerBatch(staff,{reserve:false}).commit());
  await assertFails(offerBatch(staff,{patch:{recipient:{...testRecipient,accountNumber:'999999'}}}).commit());
  await assertSucceeds(offerBatch(staff).commit());
  await assertFails(offerBatch(staff,{id:manualChatB,parentId:'bob'}).commit());
  await assertFails(acceptManual(bob));
  await assertFails(claimManual(alice));
  await assertSucceeds(acceptManual(alice));
  await assertFails(updateDoc(doc(alice,manualPath()),{amount:1}));
  await assertFails(updateDoc(doc(alice,manualPath()),{recipient:{...testRecipient,accountNumber:'999999'}}));
  await assertFails(updateDoc(doc(alice,manualPath()),{status:'verified',verifiedBy:'alice'}));
  await assertFails(updateDoc(doc(staff,manualPath()),{amount:1}));
});

test('VietQR approval atomically creates one canonical class; parent/tutor/revoked writes denied', async () => {
  await seedManual();
  await assertSucceeds(offerBatch(staffDb()).commit());
  await assertSucceeds(acceptManual(db()));
  await assertSucceeds(claimManual(db()));
  await assertFails(getDocFromServer(doc(db(),manualClass())));
  await assertFails(decideManual(db(),{staff:'alice'}).commit());
  await assertFails(decideManual(db('tutor'),{staff:'tutor'}).commit());
  await assertFails(decideManual(staffDb('revoked'),{staff:'revoked'}).commit());
  await assertFails(decideManual(staffDb(),{withClass:false}).commit());
  await assertFails(decideManual(staffDb(),{withAudit:false}).commit());
  await assertFails(decideManual(staffDb(),{amount:1}).commit());
  await assertFails(decideManual(staffDb(),{reviewer:'admin'}).commit());
  await assertFails(setDoc(doc(db(),manualClass()),{parentId:'alice',paymentStatus:'verified'}));
  const results = await Promise.allSettled([
    decideManual(staffDb()).commit(),
    decideManual(staffDb('admin'),{staff:'admin',receipt:'000000_FIXTURE00002'}).commit(),
  ]);
  require('node:assert/strict').equal(results.filter(r=>r.status==='fulfilled').length,1);
  await assertSucceeds(getDocFromServer(doc(db(),manualClass())));
  await assertSucceeds(getDocFromServer(doc(db('tutor'),manualClass())));
  await assertFails(getDocFromServer(doc(db('bob'),manualClass())));
  await assertFails(getDocFromServer(doc(db(),manualAudit())));
  await assertSucceeds(getDocFromServer(doc(staffDb(),manualAudit())));
  await assertFails(decideManual(staffDb(),{receipt:'000000_FIXTURE00003'}).commit());
});

test('VietQR rejection, same-invoice retry, cancellation and replay protection', async () => {
  await seedManual();
  await assertSucceeds(offerBatch(staffDb()).commit());
  await assertSucceeds(offerBatch(staffDb(),{id:manualChatB,reference:manualRefB,parentId:'bob'}).commit());
  await assertSucceeds(acceptManual(db()));
  await assertSucceeds(claimManual(db()));
  await assertFails(decideManual(staffDb(),{verify:false,reason:'  '}).commit());
  await assertSucceeds(decideManual(staffDb(),{verify:false}).commit());
  await assertFails(getDocFromServer(doc(db(),manualClass())));
  await assertFails(claimManual(db()));
  await assertSucceeds(claimManual(db(),manualChatA,manualClaimB));
  await assertFails(decideManual(staffDb()).commit());
  await assertSucceeds(decideManual(staffDb(),{claim:manualClaimB}).commit());
  await assertSucceeds(acceptManual(db('bob'),manualChatB));
  await assertSucceeds(claimManual(db('bob'),manualChatB));
  await assertFails(decideManual(staffDb(),{id:manualChatB,parent:'bob',ref:manualRefB}).commit());
  await assertSucceeds(decideManual(staffDb(),{id:manualChatB,parent:'bob',verify:false}).commit());
  await assertSucceeds(updateDoc(doc(staffDb(),manualPath(manualChatB)),{
    status:'cancelled',cancelledBy:'staff',cancelledAt:serverTimestamp(),cancelReason:'Expired request',
  }));
  await assertFails(claimManual(db('bob'),manualChatB,manualClaimB));
  await assertFails(decideManual(staffDb(),{id:manualChatB,parent:'bob',ref:manualRefB,receipt:'000000_FIXTURE00003'}).commit());
  await assertFails(getDocFromServer(doc(db('bob'),manualClass(manualChatB))));
  await assertSucceeds(getDocFromServer(doc(db(),'invoices/legacy-verified')));
  await assertSucceeds(getDocFromServer(doc(db(),'classes/legacy-class')));
});
