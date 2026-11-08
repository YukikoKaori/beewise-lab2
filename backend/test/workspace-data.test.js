// EMULATOR integration tests: the data the tutor workspace (T3/T4) reads must be complete.
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, test } from 'node:test';
import { startWorkflowWatcher } from '../src/watcher.js';
import { auth, createUser, db, issueInvoice, makeServices, resetEmulators, seedIntake, staffOf } from './support/harness.js';

const silent = { info() {}, warn() {}, error() {} };
const waitFor = async (check, label, timeoutMs = 10_000) => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await check()) return;
    await new Promise((resolve) => { setTimeout(resolve, 100); });
  }
  assert.fail(`timed out waiting for ${label}`);
};

let services; let parent; let consultant;
beforeEach(async () => {
  await resetEmulators();
  services = makeServices();
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true, displayName: 'Tư vấn viên A' });
  await db.doc(`parents/${parent.uid}`).set({ displayName: 'Chị Lan', email: 'parent@beewise.test' });
});

const billing = {
  fee: 250_000, hoursPerSession: 1.5, sessions: 4, totalFee: 1_500_000,
  schedule: 'Thứ 3, Thứ 5', time: '19:00 - 20:30', startDate: '17/11/2026',
};

describe('chat summary', () => {
  test('enrich fills parent name and request summary once and never overwrites', async () => {
    await seedIntake({ parentUid: parent.uid });
    await db.doc('connectionRequests/req_1').update({ learningGoal: 'Lấy lại căn bản Toán 8', area: 'Quận 7' });
    const first = await services.chatSummaries.enrich('chat_1');
    assert.deepEqual([...first.fields].sort(), ['areaSummary', 'parentName', 'subjectSummary']);
    const chat = (await db.doc('chats/chat_1').get()).data();
    assert.equal(chat.parentName, 'Chị Lan');
    assert.equal(chat.subjectSummary, 'Lấy lại căn bản Toán 8');
    assert.equal(chat.areaSummary, 'Quận 7');

    await db.doc(`parents/${parent.uid}`).update({ displayName: 'Tên mới' });
    assert.equal((await services.chatSummaries.enrich('chat_1')).changed, false);
    assert.equal((await db.doc('chats/chat_1').get()).data().parentName, 'Chị Lan');
  });

  test('claiming a chat stores the consultant name for the tutor view', async () => {
    await seedIntake({ parentUid: parent.uid });
    await services.consultants.claimChat(staffOf(consultant), 'chat_1');
    assert.equal((await db.doc('chats/chat_1').get()).data().consultantName, 'Tư vấn viên A');
  });

  test('only a strictly newer message becomes the preview; replays are ignored', async () => {
    await seedIntake({ parentUid: parent.uid });
    const at = (ms) => Timestamp.fromMillis(ms);
    const record = (body, createdAt) => services.chatSummaries.recordMessage('chat_1', { body, role: 'parent', createdAt });
    assert.equal((await record('Xin chào', at(2000))).changed, true);
    assert.equal((await record('Tin cũ hơn', at(1000))).changed, false);
    assert.equal((await record('Xin chào', at(2000))).changed, false);
    assert.equal((await record('   ', at(3000))).changed, false);
    assert.equal((await record('x'.repeat(500), at(4000))).changed, true);
    const chat = (await db.doc('chats/chat_1').get()).data();
    assert.equal(chat.lastMessageText.length, 120);
    assert.equal(chat.lastMessageBy, 'parent');
  });

  test('the watcher keeps parent name, summary and last message current on its own', async () => {
    const stop = startWorkflowWatcher({ db, auth, ...services, logger: silent });
    try {
      await seedIntake({ parentUid: parent.uid });
      await db.doc('connectionRequests/req_1').update({ learningGoal: 'Ôn thi vào 10', area: 'Cầu Giấy' });
      await waitFor(async () => (await db.doc('chats/chat_1').get()).data().parentName === 'Chị Lan', 'parent name');
      await db.collection('chats/chat_1/messages').add({ senderId: parent.uid, role: 'parent', kind: 'text', body: 'Em chào cô ạ', createdAt: new Date() });
      await waitFor(async () => (await db.doc('chats/chat_1').get()).data().lastMessageText === 'Em chào cô ạ', 'last message');
      await waitFor(async () => (await db.doc('chats/chat_1').get()).data().subjectSummary === 'Ôn thi vào 10', 'request summary');
      assert.equal((await db.doc('chats/chat_1').get()).data().areaSummary, 'Cầu Giấy');
    } finally { stop(); }
  });
});

describe('official class', () => {
  test('a verified payment creates a class carrying names, fees and dated sessions for the tutor', async () => {
    const { invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant, revision: billing });
    await services.chatSummaries.enrich('chat_1'); // the watcher does this as soon as the chat exists
    const { orderCode } = await services.payments.createCheckout(parent.uid, invoiceId);
    services.payos.pay(orderCode);
    await services.payments.handleWebhook(await services.payos.webhook(orderCode));

    const chat = (await db.doc('chats/chat_1').get()).data();
    const official = (await db.doc(`classes/${chat.classId}`).get()).data();
    assert.equal(chat.onboardingStatus, 'schedule_confirmed');
    assert.equal(chat.classId, `cls_${invoiceId}`);
    assert.equal(official.tutorId, 'tutor_demo');
    assert.equal(official.parentName, 'Chị Lan');
    assert.equal(official.consultantName, 'Tư vấn viên A');
    assert.equal(official.hourlyFee, 250_000);
    assert.equal(official.hoursPerSession, 1.5);
    assert.equal(official.totalSessions, 4);
    assert.equal(official.totalAmount, 1_500_000);
    assert.equal(official.sessions.length, 4);
    assert.deepEqual(official.sessions.map((s) => s.startTime.toDate().toISOString()), [
      '2026-11-17T12:00:00.000Z', '2026-11-19T12:00:00.000Z', '2026-11-24T12:00:00.000Z', '2026-11-26T12:00:00.000Z',
    ]);
    assert.ok(official.sessions.every((s) => s.tutorId === 'tutor_demo' && s.parentName === 'Chị Lan' && s.confirmed === true));
  });

  test('terms without a session count still verify the payment, with an empty (never invented) schedule', async () => {
    const { invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant });
    const { orderCode } = await services.payments.createCheckout(parent.uid, invoiceId);
    services.payos.pay(orderCode);
    const result = await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    assert.equal(result.httpStatus, 200);
    const invoice = (await db.doc(`invoices/${invoiceId}`).get()).data();
    assert.equal(invoice.status, 'verified');
    const official = (await db.doc(`classes/${invoice.classId}`).get()).data();
    assert.deepEqual(official.sessions, []);
    assert.equal(official.totalAmount, 2_000_000);
  });
});
