#!/usr/bin/env node
// EMULATOR DEMO ONLY. Runs the real backend services against the Firebase Auth
// and Firestore emulators, with FakePayos behind the official payOS SDK and a
// local "checkout page" that simulates the parent's bank transfer.
// Nothing here talks to payOS or to a real Firebase project.
import { createApp } from '../src/app.js';
import { createPayosGateway } from '../src/payos-gateway.js';
import { createRuntime } from '../src/runtime.js';
import { startWorkflowWatcher } from '../src/watcher.js';
import { FakePayos, TEST_CHECKSUM_KEY } from '../test/support/fake-payos.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Refusing to start: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST must point at emulators.');
  process.exit(2);
}

const port = Number(process.env.PORT ?? 8787);
// What the Android emulator uses to reach this machine.
const publicBaseUrl = process.env.PUBLIC_BASE_URL ?? `http://10.0.2.2:${port}`;
const env = { ...process.env, PORT: String(port), PUBLIC_BASE_URL: publicBaseUrl };
const demoCheckout = `${publicBaseUrl}/demo/payos`;

const fake = new FakePayos({ checkoutBase: demoCheckout });
const gateway = createPayosGateway({ clientId: 'emulator', apiKey: 'emulator', checksumKey: TEST_CHECKSUM_KEY, fetch: fake.fetch });
const runtime = createRuntime(env, { gateway });
runtime.payments.checkoutUrlPrefix = `${demoCheckout}/`;

const vnd = (amount) => `${Number(amount).toLocaleString('vi-VN')} đ`;
const page = (body) => `<!doctype html><html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>payOS (giả lập)</title></head>
<body style="font-family:sans-serif;max-width:440px;margin:24px auto;padding:0 16px">
<p style="background:#fde68a;padding:8px 12px;border-radius:8px;font-weight:bold">EMULATOR — trang thanh toán giả lập, không phải payOS thật</p>
${body}</body></html>`;

const extraRoutes = (app) => {
  app.get('/demo/payos/:orderCode', (req, res) => {
    const link = fake.links.get(Number(req.params.orderCode));
    if (!link) return res.status(404).type('html').send(page('<h1>Không tìm thấy giao dịch</h1>'));
    return res.type('html').send(page(`
      <h1 style="font-size:22px">Thanh toán học phí BeeWise</h1>
      <p>Mã đơn: <b>${link.orderCode}</b><br>Nội dung CK: <b>${link.description}</b><br>
      Trạng thái: <b>${link.status}</b></p>
      <p style="font-size:28px;font-weight:bold;color:#1e3ad6">${vnd(link.amount)}</p>
      <form method="post" action="/demo/payos/${link.orderCode}/pay">
        <button style="width:100%;padding:14px;font-size:16px;background:#1e3ad6;color:#fff;border:0;border-radius:24px">
          Xác nhận đã chuyển khoản (giả lập)</button></form>
      <form method="post" action="/demo/payos/${link.orderCode}/cancel" style="margin-top:12px">
        <button style="width:100%;padding:12px;font-size:15px;background:#fff;border:1px solid #888;border-radius:24px">
          Hủy thanh toán</button></form>`));
  });
  app.post('/demo/payos/:orderCode/pay', async (req, res, next) => {
    try {
      const orderCode = Number(req.params.orderCode);
      if (!fake.links.has(orderCode)) return res.status(404).end();
      if (fake.links.get(orderCode).status === 'PENDING') fake.pay(orderCode);
      // payOS would now POST a signed webhook to our server; do exactly that.
      const result = await runtime.payments.handleWebhook(await fake.webhook(orderCode));
      console.info('[demo] webhook ->', result.httpStatus, result.body.result);
      return res.redirect(303, '/v1/payos/return');
    } catch (error) {
      return next(error);
    }
  });
  app.post('/demo/payos/:orderCode/cancel', (req, res) => {
    const orderCode = Number(req.params.orderCode);
    if (fake.links.get(orderCode)?.status === 'PENDING') fake.setStatus(orderCode, 'CANCELLED');
    return res.redirect(303, '/v1/payos/cancel');
  });
};

const app = createApp({ ...runtime, extraRoutes });
app.listen(port, '0.0.0.0', () => {
  console.info(`[demo] EMULATOR backend on :${port}, public ${publicBaseUrl}, project ${process.env.GCLOUD_PROJECT ?? process.env.FIREBASE_PROJECT_ID}`);
});
startWorkflowWatcher(runtime);
console.info('[demo] workflow watcher enabled');
