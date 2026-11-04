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
