// EMULATOR integration tests: consultant state machine (F-03 part A).
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { requireConsultant } from '../src/auth.js';
import {
  auth, createUser, db, issueInvoice, makeServices, resetEmulators, respond, revisionInput, seedIntake,
  staffOf, trialInput,
} from './support/harness.js';

let parent; let consultant; let other; let services;

beforeEach(async () => {
  await resetEmulators();
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true });
  other = await createUser('other-consultant@beewise.test', { consultant: true });
  services = makeServices();
});

const rejectsCode = (promise, code) => assert.rejects(promise, (error) => {
  assert.equal(error.code, code);
  return true;
});

describe('staff authorization', () => {
  test('only users with the Admin-set consultant claim are staff', async () => {
    assert.equal((await requireConsultant(auth, consultant.uid)).uid, consultant.uid);
    await rejectsCode(requireConsultant(auth, parent.uid), 'permission_denied');
    await rejectsCode(requireConsultant(auth, 'missing-user'), 'permission_denied');
  });

  test('revoking the claim or disabling the account removes authority immediately', async () => {
    await auth.setCustomUserClaims(consultant.uid, {});
    await rejectsCode(requireConsultant(auth, consultant.uid), 'permission_denied');
    await auth.setCustomUserClaims(other.uid, { beewiseConsultant: true });
    await auth.updateUser(other.uid, { disabled: true });
    await rejectsCode(requireConsultant(auth, other.uid), 'permission_denied');
  });
});

describe('claiming an intake', () => {
  test('a valid reciprocal intake is assigned once', async () => {
    await seedIntake({ parentUid: parent.uid });
    const result = await services.consultants.claimChat(staffOf(consultant), 'chat_1');
    assert.equal(result.status, 'consultant_assigned');
    const chat = (await db.doc('chats/chat_1').get()).data();
    assert.equal(chat.consultantId, consultant.uid);
    assert.equal(chat.consultantQueue, false);
    assert.equal((await services.consultants.claimChat(staffOf(consultant), 'chat_1')).alreadyAssigned, true);
    await rejectsCode(services.consultants.claimChat(staffOf(other), 'chat_1'), 'already_assigned');
  });

  test('non-reciprocal or inactive intakes are refused', async () => {
    await seedIntake({ parentUid: parent.uid });
    await db.doc('connectionRequests/req_1').update({ chatId: 'some_other_chat' });
    await rejectsCode(services.consultants.claimChat(staffOf(consultant), 'chat_1'), 'invalid_intake');

    await seedIntake({ parentUid: parent.uid, chatId: 'chat_2', requestId: 'req_2', active: false });
    await rejectsCode(services.consultants.claimChat(staffOf(consultant), 'chat_2'), 'tutor_inactive');
  });

  test('path-like ids are rejected before any read', async () => {
    await rejectsCode(services.consultants.claimChat(staffOf(consultant), 'chats/../x'), 'invalid_argument');
  });
});

describe('trial proposals', () => {
  const setup = async () => {
    await seedIntake({ parentUid: parent.uid });
    await services.consultants.claimChat(staffOf(consultant), 'chat_1');
  };

  test('publishing sets the current pointer, pending status and expiry', async () => {
    await setup();
    const { proposalId } = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    const chat = (await db.doc('chats/chat_1').get()).data();
    assert.equal(chat.currentProposalId, proposalId);
    assert.equal(chat.onboardingStatus, 'trial_proposed');
    const message = (await db.doc(`chats/chat_1/messages/${proposalId}`).get()).data();
    assert.equal(message.role, 'consultant');
    assert.equal(message.kind, 'trial_proposal');
    assert.equal(message.payload.status, 'pending');
    assert.ok(message.payload.expiresAt.toMillis() > Date.now());
  });

  test('only the assigned consultant can publish', async () => {
    await setup();
    await rejectsCode(services.consultants.proposeTrial(staffOf(other), 'chat_1', trialInput), 'permission_denied');
  });

  test('invalid payloads are refused', async () => {
    await setup();
    await rejectsCode(services.consultants.proposeTrial(staffOf(consultant), 'chat_1', { ...trialInput, mode: 'bay' }), 'invalid_argument');
    await rejectsCode(services.consultants.proposeTrial(staffOf(consultant), 'chat_1', { ...trialInput, fee: 12.5 }), 'invalid_argument');
  });

  test('acceptance is consumed exactly once', async () => {
    await setup();
    const { proposalId } = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    await respond('chat_1', proposalId, parent.uid, 'trial_accepted');
    const first = await services.consultants.processResponse(staffOf(consultant), 'chat_1', proposalId);
    assert.equal(first.outcome, 'trial_accepted');
    const again = await services.consultants.processResponse(staffOf(consultant), 'chat_1', proposalId);
    assert.equal(again.alreadyProcessed, true);
    assert.equal((await db.doc('chats/chat_1').get()).data().onboardingStatus, 'trial_accepted');
    assert.equal((await db.doc(`chats/chat_1/messages/${proposalId}`).get()).data().payload.status, 'accepted');
  });

  test('concurrent processing of one response still applies once', async () => {
    await setup();
    const { proposalId } = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    await respond('chat_1', proposalId, parent.uid, 'trial_accepted');
    const results = await Promise.all(Array.from({ length: 4 }, () => services.consultants.processResponse(staffOf(consultant), 'chat_1', proposalId)));
    assert.equal(results.filter((r) => !r.alreadyProcessed).length, 1);
    const systemMessages = await db.collection('chats/chat_1/messages').where('kind', '==', 'system').get();
    assert.equal(systemMessages.size, 1);
  });

  test('alternate time leads to a new proposal that supersedes the old one', async () => {
    await setup();
    const first = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    await respond('chat_1', first.proposalId, parent.uid, 'trial_alternate_time', { alternateTime: 'Thứ 7 sáng' });
    assert.equal((await services.consultants.processResponse(staffOf(consultant), 'chat_1', first.proposalId)).outcome, 'trial_reschedule_requested');
    const second = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', { ...trialInput, date: '15/11/2026' });
    assert.notEqual(second.proposalId, first.proposalId);
    assert.equal((await db.doc('chats/chat_1').get()).data().currentProposalId, second.proposalId);
  });

  test('a response to a replaced proposal is rejected as stale', async () => {
    await setup();
    const first = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    const second = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    assert.equal((await db.doc(`chats/chat_1/messages/${first.proposalId}`).get()).data().payload.status, 'superseded');
    await respond('chat_1', first.proposalId, parent.uid, 'trial_accepted');
    assert.deepEqual(await services.consultants.processResponse(staffOf(consultant), 'chat_1', first.proposalId), { outcome: 'rejected', reason: 'stale' });
    assert.equal((await db.doc('chats/chat_1').get()).data().currentProposalId, second.proposalId);
  });

  test('a response written after expiry is rejected', async () => {
    const past = makeServices({ now: () => new Date(Date.now() - 3 * 3_600_000) });
    await setup();
    const { proposalId } = await past.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput, { ttl: 1 });
    await respond('chat_1', proposalId, parent.uid, 'trial_accepted');
    assert.equal((await services.consultants.processResponse(staffOf(consultant), 'chat_1', proposalId)).reason, 'expired');
  });

  test('a response claiming another parent is rejected', async () => {
    await setup();
    const { proposalId } = await services.consultants.proposeTrial(staffOf(consultant), 'chat_1', trialInput);
    await respond('chat_1', proposalId, 'intruder-uid', 'trial_accepted');
    assert.equal((await services.consultants.processResponse(staffOf(consultant), 'chat_1', proposalId)).reason, 'owner_mismatch');
  });
});

describe('class revisions and invoice issuance', () => {
  test('adjustment then new revision then confirmation issues one invoice from current terms', async () => {
    await seedIntake({ parentUid: parent.uid });
    const staff = staffOf(consultant);
    await services.consultants.claimChat(staff, 'chat_1');
    await rejectsCode(services.consultants.proposeClassRevision(staff, 'chat_1', revisionInput), 'invalid_state');
    const trial = await services.consultants.proposeTrial(staff, 'chat_1', trialInput);
    await respond('chat_1', trial.proposalId, parent.uid, 'trial_accepted');
    await services.consultants.processResponse(staff, 'chat_1', trial.proposalId);

    const r1 = await services.consultants.proposeClassRevision(staff, 'chat_1', revisionInput);
    await respond('chat_1', r1.proposalId, parent.uid, 'class_adjustment_requested', { reason: 'Đổi sang tối thứ 6' });
    assert.equal((await services.consultants.processResponse(staff, 'chat_1', r1.proposalId)).outcome, 'class_adjustment_requested');

    const r2 = await services.consultants.proposeClassRevision(staff, 'chat_1', { ...revisionInput, schedule: 'Thứ 6', totalFee: 1_800_000 });
    assert.notEqual(r2.proposalId, r1.proposalId);
    await respond('chat_1', r2.proposalId, parent.uid, 'class_revision_confirmed');
    const issued = await services.consultants.processResponse(staff, 'chat_1', r2.proposalId);
    assert.equal(issued.outcome, 'invoice_issued');
    assert.equal(issued.invoiceId, `inv_chat_1_${r2.proposalId}`);

    const invoice = (await db.doc(`invoices/${issued.invoiceId}`).get()).data();
    assert.equal(invoice.parentId, parent.uid);
    assert.equal(invoice.amount, 1_800_000);
    assert.equal(invoice.currency, 'VND');
    assert.equal(invoice.status, 'pending');
    assert.equal(invoice.terms.schedule, 'Thứ 6');
    const requests = await db.collection('chats/chat_1/messages').where('kind', '==', 'payment_request').get();
    assert.equal(requests.size, 1);
    assert.equal(requests.docs[0].data().payload.invoiceId, issued.invoiceId);

    // Re-delivery does not issue twice.
    assert.equal((await services.consultants.processResponse(staff, 'chat_1', r2.proposalId)).alreadyProcessed, true);
    assert.equal((await db.collection('invoices').get()).size, 1);
    // A class is never created before payment.
    assert.equal((await db.collection('classes').get()).size, 0);
  });

  test('issueInvoice helper reaches invoice_issued', async () => {
    const { invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant });
    assert.equal((await db.doc('chats/chat_1').get()).data().onboardingStatus, 'invoice_issued');
    assert.ok((await db.doc(`invoices/${invoiceId}`).get()).exists);
  });
});
