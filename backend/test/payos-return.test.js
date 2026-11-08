// EMULATOR integration tests: the browser page payOS sends the parent to after paying.
import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, test } from 'node:test';
import { createApp } from '../src/app.js';
import { auth, createUser, db, issueInvoice, makeServices, resetEmulators } from './support/harness.js';

let server; let base; let services; let parent; let consultant; let invoiceId; let orderCode;

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
  services.payments.returnChecks.clear();
  parent = await createUser('parent@beewise.test');
  consultant = await createUser('consultant@beewise.test', { consultant: true });
  ({ invoiceId } = await issueInvoice({ consultants: services.consultants, parent, consultant }));
  ({ orderCode } = await services.payments.createCheckout(parent.uid, invoiceId));
});

const get = async (path) => {
  const response = await fetch(`${base}${path}`);
  return { status: response.status, html: await response.text() };
};
const invoiceStatus = async () => (await db.doc(`invoices/${invoiceId}`).get()).data().status;

describe('return page', () => {
  test('after a real payment it verifies with payOS and sends the parent back to that invoice in the app', async () => {
    services.payos.pay(orderCode);
    const page = await get(`/v1/payos/return?code=00&status=PAID&orderCode=${orderCode}`);
    assert.equal(page.status, 200);
    assert.match(page.html, /Thanh toán thành công/);
    assert.ok(page.html.includes(`intent://app/payment/${invoiceId}#Intent;scheme=beewise;package=com.beewise.beewise;end`));
    assert.ok(page.html.includes(`beewise://app/payment/${invoiceId}`));
    assert.equal(await invoiceStatus(), 'verified', 'the page asked payOS, and payOS said PAID');
  });

  test('the page itself is never proof: a "PAID" query without a real payment verifies nothing', async () => {
    const page = await get(`/v1/payos/return?code=00&status=PAID&orderCode=${orderCode}`);
    assert.match(page.html, /Đang xác nhận thanh toán/);
    assert.match(page.html, /xác minh/);
    assert.equal(await invoiceStatus(), 'pending');
    assert.ok(page.html.includes(`/payment/${invoiceId}`), 'still returns to the invoice so the app can keep checking');
  });

  test('provider checks are throttled per order so the page cannot hammer payOS', async () => {
    const before = services.payos.calls.length;
    await get(`/v1/payos/return?orderCode=${orderCode}`);
    const afterFirst = services.payos.calls.length;
    await get(`/v1/payos/return?orderCode=${orderCode}`);
    await get(`/v1/payos/cancel?orderCode=${orderCode}`);
    assert.ok(afterFirst > before, 'first visit checks payOS');
    assert.equal(services.payos.calls.length, afterFirst, 'repeat visits inside the window do not');
  });

  test('cancel page explains the cancellation and still returns to the app', async () => {
    services.payos.setStatus(orderCode, 'CANCELLED');
    const page = await get(`/v1/payos/cancel?orderCode=${orderCode}`);
    assert.equal(page.status, 200);
    assert.match(page.html, /Đã hủy thanh toán/);
    assert.ok(page.html.includes(`/payment/${invoiceId}`));
    assert.equal(await invoiceStatus(), 'pending', 'cancelling never marks anything paid');
  });

  test('unknown or malformed order codes get a neutral page and reveal nothing', async () => {
    for (const code of ['', 'abc', '1;DROP', '9'.repeat(30), '0000000000000000x', '99999999999']) {
      const page = await get(`/v1/payos/return?orderCode=${encodeURIComponent(code)}`);
      assert.equal(page.status, 200, code);
      assert.ok(page.html.includes('intent://app/messages#Intent;'), `falls back to the message list for "${code}"`);
      assert.ok(!page.html.includes(invoiceId));
    }
    const none = await get('/v1/payos/return');
    assert.equal(none.status, 200);
  });
});
