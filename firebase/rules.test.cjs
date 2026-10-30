const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp} = require('firebase/firestore');
const {ref, uploadBytes, getBytes, deleteObject} = require('firebase/storage');

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
    storage: {rules: readFileSync('storage.rules', 'utf8')},
  });
});
beforeEach(async () => { await env.clearFirestore(); await env.clearStorage(); });
after(async () => { await env?.cleanup(); });

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
test('Storage PDF reports enforce owner, extension, content type and strict size limit', async () => {
  const own = env.authenticatedContext('alice').storage();
  const report = ref(own, 'reports/alice/report.pdf');
  await assertSucceeds(uploadBytes(report, Buffer.from('%PDF-1.4\n'), {contentType: 'application/pdf'}));
  await assertSucceeds(getBytes(report));
  const other = ref(env.authenticatedContext('bob').storage(), 'reports/alice/report.pdf');
  await assertFails(getBytes(other));
  await assertFails(uploadBytes(other, Buffer.from('x'), {contentType: 'application/pdf'}));
  await assertFails(deleteObject(other));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), 'reports/alice/report.pdf')));
  await assertFails(uploadBytes(ref(own, 'reports/alice/wrong.txt'), Buffer.from('x'), {contentType: 'application/pdf'}));
  await assertFails(uploadBytes(ref(own, 'reports/alice/wrong.pdf'), Buffer.from('x'), {contentType: 'text/plain'}));
  await assertFails(uploadBytes(ref(own, 'reports/alice/large.pdf'), Buffer.alloc(10 * 1024 * 1024), {contentType: 'application/pdf'}));
  await assertSucceeds(deleteObject(report));
});
