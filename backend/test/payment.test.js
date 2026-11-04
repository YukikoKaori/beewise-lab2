// EMULATOR integration tests: payOS checkout, webhook and settlement (F-03 part B).
// The payOS side is FakePayos behind the official SDK — not live payOS.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { PaymentService } from '../src/payment-service.js';
import { createUnconfiguredGateway } from '../src/payos-gateway.js';
import { createUser, db, issueInvoice, makeServices, resetEmulators } from './support/harness.js';

let parent; let consultant; let services; let invoiceId;

beforeEach(async () => {
  await resetEmulators();
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true });
  services = makeServices();
  ({ invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant }));
});

const rejectsCode = (promise, code) => assert.rejects(promise, (error) => {
  assert.equal(error.code, code);
  return true;
});
const invoice = async () => (await db.doc(`invoices/${invoiceId}`).get()).data();
const order = async (code) => (await db.doc(`paymentOrders/${code}`).get()).data();
const classes = async () => (await db.collection('classes').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

describe('checkout', () => {
  test('creates one signed payOS link bound to the invoice and reuses it', async () => {
    const first = await services.payments.createCheckout(parent.uid, invoiceId);
    assert.match(first.checkoutUrl, /^https:\/\/pay\.payos\.vn\/web\//);
    const created = services.payos.calls.filter((c) => c.op === 'create');
    assert.equal(created.length, 1);
    assert.equal(created[0].body.amount, 2_000_000);
    assert.ok(created[0].body.description.length <= 9);
    assert.equal(created[0].body.returnUrl, 'https://beewise.test/v1/payos/return');

    const stored = await order(first.orderCode);
    assert.equal(stored.status, 'pending');
    assert.equal(stored.parentId, parent.uid);
    assert.equal((await invoice()).activeOrderCode, first.orderCode);

    const again = await services.payments.createCheckout(parent.uid, invoiceId);
    assert.equal(again.reused, true);
    assert.equal(again.orderCode, first.orderCode);
    assert.equal(services.payos.calls.filter((c) => c.op === 'create').length, 1);
  });

  test('another parent cannot see or pay the invoice', async () => {
    const intruder = await createUser('intruder@beewise.test');
    await rejectsCode(services.payments.createCheckout(intruder.uid, invoiceId), 'invoice_not_found');
    await rejectsCode(services.payments.reconcileInvoice(intruder.uid, invoiceId), 'invoice_not_found');
  });

  test('two simultaneous taps create at most one payOS link', async () => {
    const results = await Promise.allSettled([
      services.payments.createCheckout(parent.uid, invoiceId),
      services.payments.createCheckout(parent.uid, invoiceId),
    ]);
    assert.ok(results.some((r) => r.status === 'fulfilled'));
    for (const r of results.filter((x) => x.status === 'rejected')) assert.equal(r.reason.code, 'checkout_in_progress');
    assert.equal(services.payos.calls.filter((c) => c.op === 'create').length, 1);
  });

  test('a definitive payOS rejection releases the invoice for retry', async () => {
    services.payos.failNext('create', 'reject');
    await rejectsCode(services.payments.createCheckout(parent.uid, invoiceId), 'payos_rejected');
    assert.equal((await invoice()).activeOrderCode, null);
    const retry = await services.payments.createCheckout(parent.uid, invoiceId);
    assert.equal((await order(retry.orderCode)).status, 'pending');
  });

  test('a timeout after payOS stored the link is reconciled, never duplicated', async () => {
    services.payos.failNext('create', 'timeout');
    await rejectsCode(services.payments.createCheckout(parent.uid, invoiceId), 'checkout_uncertain');
    const [lost] = [...services.payos.links.keys()];
    assert.equal((await order(lost)).status, 'uncertain');

    const fresh = await services.payments.createCheckout(parent.uid, invoiceId);
    assert.notEqual(fresh.orderCode, lost);
    assert.equal(services.payos.links.get(lost).status, 'CANCELLED', 'old link must be cancelled at payOS');
    assert.equal((await order(lost)).status, 'cancelled');
  });

  test('if the uncertain link was actually paid, reconciliation verifies it', async () => {
    services.payos.failNext('create', 'timeout');
    await rejectsCode(services.payments.createCheckout(parent.uid, invoiceId), 'checkout_uncertain');
    const [lost] = [...services.payos.links.keys()];
    services.payos.pay(lost);
    await rejectsCode(services.payments.createCheckout(parent.uid, invoiceId), 'already_paid');
    assert.equal((await invoice()).status, 'verified');
  });

  test('a server without payOS credentials fails closed', async () => {
    const offline = new PaymentService({ db, gateway: createUnconfiguredGateway(), publicBaseUrl: 'https://beewise.test' });
    await rejectsCode(offline.createCheckout(parent.uid, invoiceId), 'payos_not_configured');
    assert.equal((await offline.handleWebhook({ data: {}, signature: 'x' })).httpStatus, 503);
  });
});

describe('webhook and settlement', () => {
  const checkout = () => services.payments.createCheckout(parent.uid, invoiceId);

  test('signed webhook + provider PAID verifies invoice and creates one official class', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode);
    const result = await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    assert.deepEqual(result, { httpStatus: 200, body: { ok: true, result: 'paid' } });

    const paid = await invoice();
    assert.equal(paid.status, 'verified');
    assert.equal(paid.paidOrderCode, orderCode);
    const [official] = await classes();
    assert.equal(official.id, paid.classId);
    assert.equal(official.paymentStatus, 'verified');
    assert.equal(official.parentId, parent.uid);
    assert.equal(official.subject, 'Toán lớp 8');
    assert.equal(official.date, '17/11/2026');
    assert.equal((await db.doc('chats/chat_1').get()).data().onboardingStatus, 'schedule_confirmed');
  });

  test('forged or tampered webhooks are refused without any write to the invoice', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode);
    const forged = await services.payos.webhook(orderCode, {}, { key: 'attacker-key' });
    assert.equal((await services.payments.handleWebhook(forged)).httpStatus, 400);
    const tampered = await services.payos.webhook(orderCode);
    tampered.data.amount = 1;
    assert.equal((await services.payments.handleWebhook(tampered)).httpStatus, 400);
    assert.equal((await services.payments.handleWebhook({})).httpStatus, 400);
    assert.equal((await invoice()).status, 'pending');
  });

  test('a validly signed "paid" webhook is not proof while payOS still says PENDING', async () => {
    const { orderCode } = await checkout();
    const result = await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    assert.equal(result.httpStatus, 503, 'ask payOS to retry');
    assert.equal((await invoice()).status, 'pending');
    assert.equal((await classes()).length, 0);
  });

  test('webhook fields that disagree with the stored order never verify', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode);
    const wrongAmount = await services.payos.webhook(orderCode, { amount: 1000 });
    assert.equal((await services.payments.handleWebhook(wrongAmount)).body.result, 'webhook_mismatch');
    const wrongLink = await services.payos.webhook(orderCode, { paymentLinkId: 'pl_other' });
    assert.equal((await services.payments.handleWebhook(wrongLink)).body.result, 'webhook_mismatch');
    const wrongCurrency = await services.payos.webhook(orderCode, { currency: 'USD' });
    assert.equal((await services.payments.handleWebhook(wrongCurrency)).body.result, 'webhook_mismatch');
    assert.equal((await invoice()).status, 'pending');
  });

  test('underpayment does not verify', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode, { amount: 500_000 });
    await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    assert.equal((await invoice()).status, 'pending');
    assert.equal((await classes()).length, 0);
  });

  test('replayed and concurrent webhooks settle exactly once', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode);
    const body = await services.payos.webhook(orderCode);
    const results = await Promise.all(Array.from({ length: 5 }, () => services.payments.handleWebhook(structuredClone(body))));
    assert.ok(results.every((r) => r.httpStatus === 200));
    assert.equal((await classes()).length, 1);
    const messages = await db.collection('chats/chat_1/messages').where('body', '==', 'Thanh toán đã được xác minh. Lịch học chính thức đã được tạo.').get();
    assert.equal(messages.size, 1);
    assert.equal((await services.payments.handleWebhook(body)).body.result, 'duplicate');
  });

  test('a bank reference reused for another invoice is flagged, not accepted', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode, { reference: 'FT-SHARED' });
    await services.payments.handleWebhook(await services.payos.webhook(orderCode));

    const second = await issueInvoice({ consultants: services.consultants, parent, consultant, chatId: 'chat_2', requestId: 'req_2' });
    const other = await services.payments.createCheckout(parent.uid, second.invoiceId);
    services.payos.pay(other.orderCode, { reference: 'FT-SHARED' });
    await services.payments.handleWebhook(await services.payos.webhook(other.orderCode));
    assert.equal((await order(other.orderCode)).mismatchReason, 'reference_reused');
    assert.equal((await db.doc(`invoices/${second.invoiceId}`).get()).data().status, 'pending');
  });

  test('missed webhook: parent reconciliation verifies from provider truth', async () => {
    const { orderCode } = await checkout();
    assert.equal((await services.payments.reconcileInvoice(parent.uid, invoiceId)).orderStatus, 'pending');
    services.payos.pay(orderCode);
    const result = await services.payments.reconcileInvoice(parent.uid, invoiceId);
    assert.equal(result.invoiceStatus, 'verified');
    assert.ok(result.classId);
  });

  test('provider outage during settlement leaves state unchanged and asks for retry', async () => {
    const { orderCode } = await checkout();
    services.payos.pay(orderCode);
    services.payos.failNext('get', 'timeout');
    const result = await services.payments.handleWebhook(await services.payos.webhook(orderCode));
    assert.equal(result.httpStatus, 503);
    assert.equal((await invoice()).status, 'pending');
    // The retry from payOS succeeds once the provider is reachable again.
    assert.equal((await services.payments.handleWebhook(await services.payos.webhook(orderCode))).body.result, 'paid');
  });

  test('cancelled or expired links release the invoice; paying twice is flagged for refund', async () => {
    const first = await checkout();
    services.payos.setStatus(first.orderCode, 'EXPIRED');
    assert.equal((await services.payments.reconcileInvoice(parent.uid, invoiceId)).orderStatus, 'expired');
    assert.equal((await invoice()).activeOrderCode, null);

    const second = await checkout();
    services.payos.pay(second.orderCode);
    await services.payments.handleWebhook(await services.payos.webhook(second.orderCode));
    // The expired link somehow gets paid later (bank delay): keep one class, flag refund.
    services.payos.pay(first.orderCode);
    await services.payments.settleOrder(first.orderCode, { source: 'test' });
    assert.equal((await order(first.orderCode)).status, 'paid_duplicate');
    assert.equal((await classes()).length, 1);
  });

  test('payOS webhook-URL confirmation sample (unknown orderCode 123) is acknowledged', async () => {
    const result = await services.payments.handleWebhook(await services.payos.webhook(123));
    assert.deepEqual(result, { httpStatus: 200, body: { ok: true, result: 'unknown_order' } });
  });

  test('a parent "I paid" request alone never unlocks the schedule', async () => {
    await checkout();
    await db.collection('paymentVerificationRequests').add({ invoiceId, parentId: parent.uid, status: 'pending', requestedAt: new Date() });
    await services.payments.reconcileInvoice(parent.uid, invoiceId);
    assert.equal((await invoice()).status, 'pending');
    assert.equal((await classes()).length, 0);
  });
});
