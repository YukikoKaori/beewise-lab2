// EMULATOR integration test: the optional automatic consumer.
import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';
import { startWorkflowWatcher } from '../src/watcher.js';
import { auth, createUser, db, makeServices, resetEmulators, respond, revisionInput, seedIntake, staffOf, trialInput } from './support/harness.js';

let stop;
afterEach(() => stop?.());
beforeEach(resetEmulators);

const waitFor = async (check, label, timeoutMs = 10_000) => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await check()) return;
    await new Promise((resolve) => { setTimeout(resolve, 100); });
  }
  assert.fail(`timed out waiting for ${label}`);
};

test('watcher consumes responses as the assigned consultant and only reconciles "I paid" requests', async () => {
  const parent = await createUser('parent@beewise.test');
  const consultant = await createUser('consultant@beewise.test', { consultant: true });
  const services = makeServices();
  stop = startWorkflowWatcher({ db, auth, ...services, logger: { info() {}, warn() {}, error() {} } });
  const staff = staffOf(consultant);

  await seedIntake({ parentUid: parent.uid });
  await services.consultants.claimChat(staff, 'chat_1');
  const trial = await services.consultants.proposeTrial(staff, 'chat_1', trialInput);
  await respond('chat_1', trial.proposalId, parent.uid, 'trial_accepted');
  await waitFor(async () => (await db.doc('chats/chat_1').get()).data().onboardingStatus === 'trial_accepted', 'trial consumption');

  const revision = await services.consultants.proposeClassRevision(staff, 'chat_1', revisionInput);
  await respond('chat_1', revision.proposalId, parent.uid, 'class_revision_confirmed');
  const invoiceId = `inv_chat_1_${revision.proposalId}`;
  await waitFor(async () => (await db.doc(`invoices/${invoiceId}`).get()).exists, 'invoice issuance');

  const { orderCode } = await services.payments.createCheckout(parent.uid, invoiceId);
  const request = await db.collection('paymentVerificationRequests').add({ invoiceId, parentId: parent.uid, status: 'pending', requestedAt: new Date() });
  await waitFor(async () => (await request.get()).data().status === 'checked', 'request check');
  assert.equal((await db.doc(`invoices/${invoiceId}`).get()).data().status, 'pending', 'request alone is not proof');

  services.payos.pay(orderCode);
  const second = await db.collection('paymentVerificationRequests').add({ invoiceId, parentId: parent.uid, status: 'pending', requestedAt: new Date() });
  await waitFor(async () => (await second.get()).data().status === 'checked', 'second request check');
  assert.equal((await db.doc(`invoices/${invoiceId}`).get()).data().status, 'verified', 'provider PAID verifies');

  // A demoted consultant's chats are no longer processed automatically.
  await auth.setCustomUserClaims(consultant.uid, {});
  await seedIntake({ parentUid: parent.uid, chatId: 'chat_2', requestId: 'req_2' });
  await db.doc('chats/chat_2').update({ consultantId: consultant.uid, onboardingStatus: 'trial_proposed', currentProposalId: 'p1' });
  await respond('chat_2', 'p1', parent.uid, 'trial_accepted');
  await new Promise((resolve) => { setTimeout(resolve, 800); });
  assert.equal((await db.doc('workflowReceipts/chat_2__p1').get()).exists, false);
});
