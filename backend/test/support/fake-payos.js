// EMULATOR-ONLY payOS stand-in. It is injected as the SDK's `fetch`, so the
// official @payos/node request signing, response signature checks and webhook
// verification run unchanged. It is NOT payOS and proves no live payment.
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { NodeCryptoProvider } = require('@payos/node/lib/crypto/index.js');

export const TEST_CHECKSUM_KEY = 'emulator-only-checksum-key';
const crypto = new NodeCryptoProvider();

const json = (status, body) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json' },
});

export class FakePayos {
  constructor({ checksumKey = TEST_CHECKSUM_KEY, checkoutBase = 'https://pay.payos.vn/web' } = {}) {
    this.checksumKey = checksumKey;
    this.checkoutBase = checkoutBase;
    this.links = new Map();
    this.calls = [];
    this.queue = []; // Scripted failures for the next calls: { op, kind }.
    this.fetch = this.fetch.bind(this);
  }

  /** Next matching call fails: kind = 'timeout' | 'http500' | 'reject' | 'notfound'. */
  failNext(op, kind) {
    this.queue.push({ op, kind });
  }

  /** Simulates the parent completing a bank transfer on the payOS page. */
  pay(orderCode, { amount, reference = `FT${orderCode}` } = {}) {
    const link = this.links.get(Number(orderCode));
    const paid = amount ?? link.amount;
    link.amountPaid += paid;
    link.amountRemaining = Math.max(0, link.amount - link.amountPaid);
    link.status = link.amountPaid >= link.amount ? 'PAID' : 'UNDERPAID';
    link.transactions.push({
      reference, amount: paid, accountNumber: '0000', description: link.description,
      transactionDateTime: '2026-11-04 10:00:00', virtualAccountName: null, virtualAccountNumber: null,
      counterAccountBankId: null, counterAccountBankName: null, counterAccountName: null, counterAccountNumber: null,
    });
    return link;
  }

  setStatus(orderCode, status) {
    this.links.get(Number(orderCode)).status = status;
  }

  /** Builds a webhook body signed exactly as payOS documents (sorted data, HMAC-SHA256). */
  async webhook(orderCode, overrides = {}, { key = this.checksumKey, top = {} } = {}) {
    const link = this.links.get(Number(orderCode));
    const data = {
      orderCode: Number(orderCode),
      amount: link?.amount ?? 3000,
      description: link?.description ?? 'VQRIO123',
      accountNumber: '12345678',
      reference: link?.transactions.at(-1)?.reference ?? 'TF230204212323',
      transactionDateTime: '2026-11-04 10:00:00',
      currency: 'VND',
      paymentLinkId: link?.id ?? '124c33293c43417ab7879e14c8d9eb18',
      code: '00',
      desc: 'Thành công',
      counterAccountBankId: '', counterAccountBankName: '', counterAccountName: '', counterAccountNumber: '',
      virtualAccountName: '', virtualAccountNumber: '',
      ...overrides,
    };
    const signature = await crypto.createSignatureFromObj(data, key);
    return { code: '00', desc: 'success', success: true, data, signature, ...top };
  }

  async #ok(data) {
    return json(200, { code: '00', desc: 'success', data, signature: await crypto.createSignatureFromObj(data, this.checksumKey) });
  }

  async fetch(url, init = {}) {
    const { pathname } = new URL(url);
    const method = (init.method ?? 'GET').toUpperCase();
    const body = init.body ? JSON.parse(init.body) : null;
    const op = method === 'POST' && pathname === '/v2/payment-requests' ? 'create'
      : method === 'POST' && pathname.endsWith('/cancel') ? 'cancel'
        : method === 'GET' ? 'get' : 'other';
    this.calls.push({ op, method, pathname, body });

    const scripted = this.queue.findIndex((item) => item.op === op);
    let failure = null;
    if (scripted >= 0) [failure] = this.queue.splice(scripted, 1);
    // A timeout AFTER payOS stored the link is the dangerous case we must reconcile.
    if (failure?.kind === 'timeout' && op !== 'create') throw new TypeError('fetch failed');
    if (failure?.kind === 'http500') return json(500, { code: '99', desc: 'internal error' });
    if (failure?.kind === 'reject') return json(200, { code: '20', desc: 'Thông tin không hợp lệ', data: null });
    if (failure?.kind === 'notfound') return json(200, { code: '101', desc: 'Không tìm thấy đơn thanh toán', data: null });

    if (op === 'create') {
      const expected = await crypto.createSignatureOfPaymentRequest(body, this.checksumKey);
      if (body.signature !== expected) return json(200, { code: '20', desc: 'Chữ ký không hợp lệ', data: null });
      if (this.links.has(body.orderCode)) return json(200, { code: '231', desc: 'Đơn thanh toán đã tồn tại', data: null });
      const id = `pl_${body.orderCode}`;
      this.links.set(body.orderCode, {
        id, orderCode: body.orderCode, amount: body.amount, amountPaid: 0, amountRemaining: body.amount,
        status: 'PENDING', createdAt: '2026-11-04T10:00:00+07:00', transactions: [],
        cancellationReason: null, canceledAt: null, description: body.description,
      });
      if (failure?.kind === 'timeout') throw new TypeError('fetch failed'); // stored, but caller never hears back
      return this.#ok({
        bin: '970422', accountNumber: '0000', accountName: 'BEEWISE TEST', amount: body.amount,
        description: body.description, orderCode: body.orderCode, currency: 'VND', paymentLinkId: id,
        status: 'PENDING', expiredAt: body.expiredAt, checkoutUrl: `${this.checkoutBase}/${body.orderCode}`, qrCode: 'EMULATOR',
      });
    }
    const code = Number(pathname.split('/')[3]);
    const link = this.links.get(code);
    if (!link) return json(200, { code: '101', desc: 'Không tìm thấy đơn thanh toán', data: null });
    if (op === 'cancel') {
      if (link.status === 'PAID') return json(200, { code: '20', desc: 'Đơn thanh toán không thể hủy', data: null });
      link.status = 'CANCELLED';
      link.cancellationReason = body?.cancellationReason ?? null;
    }
    const { description: _description, ...publicLink } = link;
    return this.#ok(publicLink);
  }
}
