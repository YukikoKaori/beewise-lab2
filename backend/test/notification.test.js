// EMULATOR integration tests: the server-written notification inbox.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { startWorkflowWatcher } from '../src/watcher.js';
import { applicationNotice, chatNotices } from '../src/notification-service.js';
import { auth, createUser, db, issueInvoice, makeServices, resetEmulators, seedIntake } from './support/harness.js';

const silent = { info() {}, warn() {}, error() {} };
const waitFor = async (check, label, timeoutMs = 10_000) => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await check()) return;
    await new Promise((resolve) => { setTimeout(resolve, 100); });
  }
  assert.fail(`timed out waiting for ${label}`);
};
const inbox = async (uid) => (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) => ({ id: d.id, ...d.data() }));

let services; let tutor; let parent; let consultant;
beforeEach(async () => {
  await resetEmulators();
  services = makeServices();
  tutor = await createUser('tutor@beewise.test');
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true, displayName: 'Lan' });
});

const application = (patch = {}) => ({ name: 'Dan', status: 'pending', verified: false, active: false, ...patch });

describe('pure notice rules', () => {
  test('application notices cover every review decision and skip plain pending', () => {
    assert.equal(applicationNotice(application()), null);
    assert.equal(applicationNotice(application({ status: 'approved', verified: true, active: true })).key, 'approved');
    assert.equal(applicationNotice(application({ status: 'approved' })).key, 'approved_pending');
    const needs = applicationNotice(application({ status: 'needs_info', rejectionReason: 'Bổ sung bằng cấp' }));
    assert.equal(needs.body, 'Bổ sung bằng cấp');
    assert.equal(needs.route, '/tutor/pending');
    assert.match(applicationNotice(application({ status: 'rejected' })).body, /chưa đáp ứng/);
  });

  test('chat notices address the right person with canonical routes', () => {
    const chat = { parentId: 'p1', tutorId: 't1', parentName: 'Chị Lan', onboardingStatus: 'schedule_confirmed', classId: 'cls_9' };
    const notices = chatNotices(chat, 'c1');
    assert.deepEqual(notices.map((n) => [n.audience, n.uid, n.route]), [
      ['parent', 'p1', '/chats/c1'],
      ['tutor', 't1', '/tutor/class/cls_9'],
    ]);
    assert.deepEqual(chatNotices({ ...chat, onboardingStatus: 'trial_accepted' }, 'c1').map((n) => n.audience), ['tutor']);
    assert.deepEqual(chatNotices({ ...chat, onboardingStatus: 'invoice_issued' }, 'c1').map((n) => n.audience), ['parent']);
    assert.deepEqual(chatNotices({ ...chat, onboardingStatus: 'unknown_state' }, 'c1'), []);
    assert.ok(chatNotices({ ...chat, onboardingStatus: 'connection_pending_consultant' }, 'c1')[0].body.includes('Chị Lan'));
  });
});

describe('application notices', () => {
  test('a decision notifies once, restarts do not repeat it and a new state notifies again', async () => {
    const ref = db.doc(`tutorApplications/${tutor.uid}`);
    await ref.set(application({ status: 'needs_info', rejectionReason: 'Thiếu bằng cấp' }));
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, true);
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, false);
    let items = await inbox(tutor.uid);
    assert.equal(items.length, 1);
    assert.equal(items[0].title, 'Hồ sơ cần bổ sung');
    assert.equal(items[0].body, 'Thiếu bằng cấp');
    assert.equal(items[0].recipientUid, tutor.uid);
    assert.equal(items[0].read, false);

    await ref.update({ status: 'pending', rejectionReason: null });
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, false, 'plain pending is silent');
    await ref.update({ status: 'needs_info', rejectionReason: 'Thiếu bằng cấp' });
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, true, 'the same request again is a new event');
    await ref.update({ status: 'approved', verified: true, active: true });
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, true);
    items = await inbox(tutor.uid);
    assert.equal(items.length, 3);
    assert.ok(items.some((n) => n.title === 'Hồ sơ gia sư đã được duyệt' && n.route === '/tutor/home'));
  });

  test('a missing application is a quiet no-op', async () => {
    assert.equal((await services.notifications.notifyApplication(tutor.uid)).notified, false);
    assert.equal((await inbox(tutor.uid)).length, 0);
  });
});

describe('chat notices', () => {
  test('each onboarding step tells the right people exactly once', async () => {
    await db.doc(`parents/${parent.uid}`).set({ displayName: 'Chị Lan' });
    await seedIntake({ parentUid: parent.uid, tutorId: tutor.uid });
    await services.chatSummaries.enrich('chat_1');

    assert.equal((await services.notifications.notifyChat('chat_1')).notified, 1);
    assert.equal((await services.notifications.notifyChat('chat_1')).notified, 0, 'same status is not repeated');
    let tutorItems = await inbox(tutor.uid);
    assert.equal(tutorItems.length, 1);
    assert.match(tutorItems[0].body, /Chị Lan/);
    assert.equal(tutorItems[0].route, '/tutor/chats/chat_1');
    assert.equal((await inbox(parent.uid)).length, 0, 'the parent is not told about their own request');

    await db.doc('chats/chat_1').update({ onboardingStatus: 'consultant_assigned' });
    assert.equal((await services.notifications.notifyChat('chat_1')).notified, 2);
    assert.equal((await inbox(parent.uid)).length, 1);
    assert.equal((await inbox(tutor.uid)).length, 2);

    await db.doc('chats/chat_1').update({ onboardingStatus: 'schedule_confirmed', classId: 'cls_x' });
    await services.notifications.notifyChat('chat_1');
    tutorItems = await inbox(tutor.uid);
    assert.ok(tutorItems.some((n) => n.route === '/tutor/class/cls_x'));
    assert.ok((await inbox(parent.uid)).some((n) => n.title === 'Thanh toán đã được xác minh'));
  });

  test('a verified payment tells the tutor about the new class', async () => {
    await db.doc(`parents/${parent.uid}`).set({ displayName: 'Chị Lan' });
    const { invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant, revision: { fee: 1000, hoursPerSession: 1, sessions: 2, totalFee: 2000 } });
    await db.doc('chats/chat_1').update({ tutorId: tutor.uid });
    const { orderCode } = await services.payments.createCheckout(parent.uid, invoiceId);
    services.payos.pay(orderCode);
    await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    await services.notifications.notifyChat('chat_1');
    const items = await inbox(tutor.uid);
    assert.ok(items.some((n) => n.title === 'Lớp mới đã thanh toán' && n.route.startsWith('/tutor/class/cls_')));
  });
});

describe('watcher', () => {
  test('approving an application and creating a chat produce notifications on their own', async () => {
    const stop = startWorkflowWatcher({ db, auth, ...services, logger: silent });
    try {
      await db.doc(`tutorApplications/${tutor.uid}`).set({
        name: 'Dan', email: 'tutor@beewise.test', phone: '0387871708', qualification: 'Cử nhân', introduction: 'Ba năm dạy học cấp hai.',
        subjects: ['Toán'], grades: ['6'], hourlyFee: 180_000, areas: ['Q7'], teachingModes: ['online'], availability: 'Tối',
        status: 'pending', verified: false, active: false,
      });
      await db.doc(`tutorApplications/${tutor.uid}`).update({ status: 'approved', verified: true, active: true });
      await waitFor(async () => (await inbox(tutor.uid)).some((n) => n.title === 'Hồ sơ gia sư đã được duyệt'), 'approval notice');

      await db.doc(`parents/${parent.uid}`).set({ displayName: 'Chị Lan' });
      await seedIntake({ parentUid: parent.uid, tutorId: tutor.uid });
      await waitFor(async () => (await inbox(tutor.uid)).some((n) => n.title === 'Có phụ huynh muốn kết nối'), 'new chat notice');
      const before = (await inbox(tutor.uid)).length;
      await new Promise((resolve) => { setTimeout(resolve, 600); });
      assert.equal((await inbox(tutor.uid)).length, before, 'no repeats while idle');
    } finally { stop(); }
  });
});
