// EMULATOR integration tests: HTTP authentication and routing.
import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, test } from 'node:test';
import { createApp } from '../src/app.js';
import { auth, createUser, idToken, issueInvoice, makeServices, resetEmulators, seedIntake, trialInput } from './support/harness.js';

let server; let base; let services; let parent; let consultant;

before(async () => {
  services = makeServices();
  const app = createApp({ auth, consultants: services.consultants, payments: services.payments, logger: { error() {} } });
  await new Promise((resolve) => { server = app.listen(0, resolve); });
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise((resolve) => server.close(resolve)));

beforeEach(async () => {
  await resetEmulators();
  services.payos.links.clear();
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true, displayName: 'Tư vấn viên A' });
});

const call = async (path, { token, body, method = 'POST' } = {}) => {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: response.status, body: await response.json().catch(() => null) };
};

describe('HTTP API', () => {
  test('payment routes require a valid Firebase ID token', async () => {
    assert.equal((await call('/v1/payments/checkout', { body: { invoiceId: 'x' } })).status, 401);
    assert.equal((await call('/v1/payments/checkout', { token: 'garbage', body: { invoiceId: 'x' } })).status, 401);
  });

  test('a signed-in parent gets a checkout URL for their own invoice only', async () => {
    const { invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant });
    const token = await idToken('parent@beewise.test');
    const ok = await call('/v1/payments/checkout', { token, body: { invoiceId } });
    assert.equal(ok.status, 200);
    assert.match(ok.body.checkoutUrl, /^https:\/\//);
    assert.equal(ok.body.parentId, undefined, 'no internal fields leak');

    await createUser('intruder@beewise.test');
    const denied = await call('/v1/payments/checkout', { token: await idToken('intruder@beewise.test'), body: { invoiceId } });
    assert.equal(denied.status, 404);
    assert.equal((await call('/v1/payments/checkout', { token, body: { invoiceId: '../x' } })).status, 400);
  });

  test('staff routes require the consultant claim, and revocation is immediate', async () => {
    await seedIntake({ parentUid: parent.uid });
    const parentToken = await idToken('parent@beewise.test');
    assert.equal((await call('/v1/staff/chats/chat_1/claim', { token: parentToken })).status, 403);

    const staffToken = await idToken('consultant@beewise.test');
    const claimed = await call('/v1/staff/chats/chat_1/claim', { token: staffToken });
    assert.equal(claimed.status, 200);
    const proposal = await call('/v1/staff/chats/chat_1/trial-proposals', { token: staffToken, body: { payload: trialInput } });
    assert.equal(proposal.status, 201);
    assert.equal((await call('/v1/staff/chats/chat_1/trial-proposals', { token: staffToken, body: { payload: { ...trialInput, fee: 'free' } } })).status, 400);

    // Revocation compares the token's issue second with validSince, so make
    // sure the revocation happens in a later second than the token was issued.
    await new Promise((resolve) => { setTimeout(resolve, 1100); });
    await auth.revokeRefreshTokens(consultant.uid);
    assert.equal((await call('/v1/staff/chats/chat_1/trial-proposals', { token: staffToken, body: { payload: trialInput } })).status, 401);
  });

  test('webhook route verifies signatures and redirect pages never change state', async () => {
    const forged = await call('/v1/payos/webhook', { body: { code: '00', data: { orderCode: 1 }, signature: 'nope' } });
    assert.equal(forged.status, 400);
    const sample = await call('/v1/payos/webhook', { body: await services.payos.webhook(123) });
    assert.equal(sample.status, 200);
    const page = await fetch(`${base}/v1/payos/return?code=00&status=PAID&orderCode=1`);
    assert.equal(page.status, 200);
    assert.match(await page.text(), /xác minh/);
  });

  test('malformed JSON and unknown routes return structured errors', async () => {
    const response = await fetch(`${base}/v1/payos/webhook`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{' });
    assert.equal(response.status, 400);
    assert.equal((await call('/nope', { method: 'GET' })).status, 404);
  });
});
