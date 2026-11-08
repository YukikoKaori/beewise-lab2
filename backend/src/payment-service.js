import { createHash, randomInt } from 'node:crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { CHAT_STATUS } from './consultant-service.js';
import { HttpError, badRequest, conflict, notFound, unavailable } from './errors.js';
import { buildSessions } from './schedule.js';
import { docId } from './validation.js';

export const ORDER_STATUS = Object.freeze({
  creating: 'creating',     // Reserved locally; payOS call in flight.
  uncertain: 'uncertain',   // payOS outcome unknown (timeout/5xx); must reconcile before reuse.
  pending: 'pending',       // payOS link exists and awaits payment.
  paid: 'paid',             // Verified PAID with exact amount; invoice verified by this order.
  paidDuplicate: 'paid_duplicate', // Verified PAID but invoice was already paid: needs manual refund.
  mismatch: 'mismatch',     // Provider data disagrees with our order: never verifies anything.
  cancelled: 'cancelled',
  expired: 'expired',
  failed: 'failed',
});

const TERMINAL = new Set([ORDER_STATUS.paid, ORDER_STATUS.paidDuplicate, ORDER_STATUS.mismatch,
  ORDER_STATUS.cancelled, ORDER_STATUS.expired, ORDER_STATUS.failed]);

const CREATING_LEASE_MS = 60_000;

const RETRYABLE = new Set([401, 403, 408, 429]);

/**
 * payOS answered and refused (4xx, or HTTP 200 with a non-"00" code — the SDK
 * raises both as APIError). Auth/timeout/rate-limit answers are NOT definitive.
 */
const isDefinitiveRejection = (error) =>
  typeof error?.status === 'number' && error.status < 500 && !RETRYABLE.has(error.status)
  && (error.status >= 400 || (typeof error.code === 'string' && error.code !== '00'));

/**
 * Provider says the order does not exist. Only trusted for orders whose
 * creation we never saw confirmed; a late PAID for such an order is still
 * caught by settlement and flagged, so no payment can be silently lost.
 */
const isProviderNotFound = (error, order) => !order.paymentLinkId
  && (error?.status === 404 || isDefinitiveRejection(error));

export const classIdFor = (invoiceId) => `cls_${invoiceId}`;
const sha256 = (value) => createHash('sha256').update(value).digest('hex');

/**
 * Trusted payment state machine (F-03 part B).
 *
 * Proof of payment is ONLY a payOS `GET /v2/payment-requests/{orderCode}`
 * answer with status PAID and an exact amount, fetched by this server with
 * server-held credentials. A signed webhook triggers that check; a return URL,
 * client UI or parent "I paid" request never verifies anything on its own.
 */
export class PaymentService {
  constructor({ db, gateway, publicBaseUrl, checkoutTtlMinutes = 15, now = () => new Date(), nextOrderCode, checkoutUrlPrefix = 'https://' }) {
    this.db = db;
    this.gateway = gateway;
    this.publicBaseUrl = publicBaseUrl;
    this.checkoutTtlMinutes = checkoutTtlMinutes;
    // Only the EMULATOR demo server overrides this (to its own local page).
    this.checkoutUrlPrefix = checkoutUrlPrefix;
    this.now = now;
    // 13–14 digit codes fit payOS's integer orderCode and JS safe integers.
    this.nextOrderCode = nextOrderCode ?? (() => Number(`${Date.now() % 1e10}${randomInt(1000, 9999)}`));
  }

  /** Returns a payOS checkout URL for the parent's own pending invoice (idempotent). */
  async createCheckout(parentUid, invoiceId, { attempt = 0 } = {}) {
    docId(invoiceId, 'invoiceId');
    const reservation = await this.#reserveOrder(parentUid, invoiceId);
    if (reservation.reuse) return reservation.reuse;
    if (reservation.reconcileFirst) {
      if (attempt > 0) throw unavailable('checkout_uncertain', 'Chưa xác nhận được giao dịch trước đó. Vui lòng thử lại sau.');
      await this.#retireOrder(reservation.reconcileFirst);
      return this.createCheckout(parentUid, invoiceId, { attempt: attempt + 1 });
    }

    const { orderCode, amount, expiresAtSec } = reservation;
    const request = {
      orderCode,
      amount,
      // payOS limits description to 9 characters for non-linked bank accounts.
      description: `BW${String(orderCode).slice(-7)}`,
      items: [{ name: 'Hoc phi BeeWise', quantity: 1, price: amount }],
      returnUrl: `${this.publicBaseUrl}/v1/payos/return`,
      cancelUrl: `${this.publicBaseUrl}/v1/payos/cancel`,
      expiredAt: expiresAtSec,
    };
    let link;
    try {
      link = await this.gateway.createPaymentLink(request);
    } catch (error) {
      if (error?.code === 'payos_not_configured') {
        await this.#closeOrder(orderCode, invoiceId, ORDER_STATUS.failed, 'not_configured');
        throw unavailable('payos_not_configured', 'Cổng thanh toán chưa được cấu hình trên máy chủ.');
      }
      if (isDefinitiveRejection(error)) {
        await this.#closeOrder(orderCode, invoiceId, ORDER_STATUS.failed, `rejected_${error.status}`);
        throw new HttpError(502, 'payos_rejected', 'Cổng thanh toán từ chối tạo giao dịch. Vui lòng thử lại sau.');
      }
      // Timeout / connection / 5xx: payOS may or may not have created the link.
      await this.db.collection('paymentOrders').doc(String(orderCode))
        .update({ status: ORDER_STATUS.uncertain, updatedAt: FieldValue.serverTimestamp() });
      await this.settleOrder(orderCode, { source: 'create_uncertain' }).catch(() => undefined);
      throw unavailable('checkout_uncertain', 'Chưa xác nhận được giao dịch với cổng thanh toán. Vui lòng thử lại.');
    }

    if (link.orderCode !== orderCode || link.amount !== amount || (link.currency && link.currency !== 'VND')
        || typeof link.checkoutUrl !== 'string' || !link.checkoutUrl.startsWith(this.checkoutUrlPrefix)) {
      await this.#closeOrder(orderCode, invoiceId, ORDER_STATUS.mismatch, 'create_response_mismatch');
      throw new HttpError(502, 'payos_mismatch', 'Phản hồi từ cổng thanh toán không khớp hóa đơn.');
    }
    await this.db.collection('paymentOrders').doc(String(orderCode)).update({
      status: ORDER_STATUS.pending,
      paymentLinkId: link.paymentLinkId,
      checkoutUrl: link.checkoutUrl,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { invoiceId, orderCode, checkoutUrl: link.checkoutUrl, expiresAt: new Date(expiresAtSec * 1000).toISOString() };
  }

  /**
   * Settles an order whose link cannot be reused (uncertain, stale or about to
   * expire). If payOS still shows it payable, cancel it there first so the
   * parent can never hold two live links for one invoice.
   */
  async #retireOrder(orderCode) {
    let settled = await this.settleOrder(orderCode, { source: 'checkout_reconcile' });
    if (settled.invoiceStatus === 'verified') throw conflict('already_paid', 'Hóa đơn đã được thanh toán.');
    if (settled.orderStatus === ORDER_STATUS.pending || settled.orderStatus === ORDER_STATUS.uncertain) {
      try {
        await this.gateway.cancelPaymentLink(Number(orderCode), 'Superseded by a new BeeWise checkout');
      } catch {
        throw unavailable('checkout_uncertain', 'Chưa hủy được giao dịch cũ với cổng thanh toán. Vui lòng thử lại.');
      }
      settled = await this.settleOrder(orderCode, { source: 'checkout_cancel' });
      if (settled.invoiceStatus === 'verified') throw conflict('already_paid', 'Hóa đơn đã được thanh toán.');
      if (settled.orderStatus === ORDER_STATUS.pending || settled.orderStatus === ORDER_STATUS.uncertain) {
        throw unavailable('checkout_uncertain', 'Giao dịch cũ vẫn đang xử lý. Vui lòng thử lại sau.');
      }
    }
  }

  /** Parent-triggered reconciliation for missed webhooks ("Kiểm tra lại"). */
  async reconcileInvoice(parentUid, invoiceId) {
    docId(invoiceId, 'invoiceId');
    const invoice = await this.#ownInvoice(parentUid, invoiceId);
    if (invoice.status === 'verified') return { invoiceId, invoiceStatus: 'verified', classId: invoice.classId };
    if (!invoice.activeOrderCode) return { invoiceId, invoiceStatus: invoice.status, orderStatus: null };
    const result = await this.settleOrder(invoice.activeOrderCode, { source: 'parent_reconcile' });
    return { invoiceId, ...result };
  }

  /**
   * Handles a payOS webhook. Signature verification uses the official SDK and
   * the server-held checksum key. Returns `{ httpStatus, body }`.
   * Non-2xx is returned only when a retry could help (our DB/provider failure).
   */
  async handleWebhook(body) {
    let data;
    try {
      data = await this.gateway.verifyWebhook(body);
    } catch (error) {
      if (error?.code === 'payos_not_configured') return { httpStatus: 503, body: { ok: false, error: 'not_configured' } };
      return { httpStatus: 400, body: { ok: false, error: 'invalid_signature' } };
    }
    const eventRef = this.db.collection('payosWebhookEvents').doc(sha256(String(body.signature)));
    const previous = await eventRef.get();
    if (previous.exists && previous.data().status === 'processed') {
      return { httpStatus: 200, body: { ok: true, result: 'duplicate' } };
    }
    // Privacy: store only what reconciliation needs; no account numbers or names.
    await eventRef.set({
      orderCode: Number.isSafeInteger(data.orderCode) ? data.orderCode : null,
      paymentLinkId: typeof data.paymentLinkId === 'string' ? data.paymentLinkId : null,
      amount: Number.isSafeInteger(data.amount) ? data.amount : null,
      currency: typeof data.currency === 'string' ? data.currency : null,
      reference: typeof data.reference === 'string' ? data.reference.slice(0, 100) : null,
      code: String(body.code ?? ''),
      dataCode: String(data.code ?? ''),
      status: 'received',
      receivedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    const finish = async (result, httpStatus = 200) => {
      await eventRef.update({ status: httpStatus === 200 ? 'processed' : 'retry', result, updatedAt: FieldValue.serverTimestamp() });
      return { httpStatus, body: { ok: httpStatus === 200, result } };
    };
    if (body.code !== '00' || body.success !== true || data.code !== '00') return finish('not_success');
    if (!Number.isSafeInteger(data.orderCode)) return finish('invalid_order_code');

    const orderRef = this.db.collection('paymentOrders').doc(String(data.orderCode));
    const order = (await orderRef.get()).data();
    // payOS sends a sample (orderCode 123) when the webhook URL is confirmed.
    if (!order) return finish('unknown_order');
    if (data.paymentLinkId !== order.paymentLinkId || data.amount !== order.amount || data.currency !== 'VND') {
      await orderRef.update({ webhookMismatch: true, updatedAt: FieldValue.serverTimestamp() });
      return finish('webhook_mismatch');
    }
    try {
      const settled = await this.settleOrder(data.orderCode, { source: 'webhook' });
      // Signed "paid" webhook but provider GET not PAID yet: let payOS retry later.
      if (settled.orderStatus === ORDER_STATUS.pending || settled.orderStatus === ORDER_STATUS.uncertain) {
        return finish('provider_not_paid_yet', 503);
      }
      return finish(settled.orderStatus);
    } catch (error) {
      // Provider or database unavailable: ask payOS to retry; nothing was committed as paid.
      return finish(error?.code ?? 'settle_failed', 503);
    }
  }

  /**
   * Single settlement path used by webhook, reconciliation and create recovery.
   * Fetches provider truth, then verifies invoice + creates the official class
   * in ONE transaction with idempotency and cross-invoice reference checks.
   */
  async settleOrder(orderCode, { source }) {
    const orderRef = this.db.collection('paymentOrders').doc(String(orderCode));
    const order = (await orderRef.get()).data();
    if (!order) throw notFound('order_not_found', 'Không tìm thấy giao dịch.');

    let link;
    try {
      link = await this.gateway.getPaymentLink(Number(orderCode));
    } catch (error) {
      if (isProviderNotFound(error, order)) {
        // payOS never created it: safe to release the invoice for a new attempt.
        await this.#closeOrder(orderCode, order.invoiceId, ORDER_STATUS.failed, 'not_found_at_provider');
        return { orderStatus: ORDER_STATUS.failed, invoiceStatus: 'pending' };
      }
      throw unavailable('provider_unavailable', 'Không kiểm tra được trạng thái với cổng thanh toán.');
    }

    const references = Array.isArray(link.transactions)
      ? [...new Set(link.transactions.map((t) => t?.reference).filter((r) => typeof r === 'string' && r.length > 0))]
      : [];
    const invoiceRef = this.db.collection('invoices').doc(order.invoiceId);
    return this.db.runTransaction(async (tx) => {
      const current = (await tx.get(orderRef)).data();
      const invoice = (await tx.get(invoiceRef)).data();
      const referenceRefs = references.map((r) => this.db.collection('payosTransactions').doc(sha256(r)));
      const referenceSnaps = await Promise.all(referenceRefs.map((ref) => tx.get(ref)));
      const chatRef = invoice ? this.db.collection('chats').doc(invoice.chatId) : null;
      const revision = invoice
        ? (await tx.get(chatRef.collection('messages').doc(invoice.revisionId))).data()
        : null;
      const chat = chatRef ? (await tx.get(chatRef)).data() : null;
      const stamp = { lastCheckedAt: FieldValue.serverTimestamp(), lastCheckSource: source, providerStatus: link.status };

      if (current.status === ORDER_STATUS.paid) {
        return { orderStatus: ORDER_STATUS.paid, invoiceStatus: invoice?.status, classId: invoice?.classId ?? null };
      }
      if (current.status === ORDER_STATUS.mismatch || current.status === ORDER_STATUS.paidDuplicate) {
        // Sticky: these need a human (refund / investigation), never automatic verification.
        return { orderStatus: current.status, invoiceStatus: invoice?.status ?? null };
      }
      if (TERMINAL.has(current.status) && current.status !== ORDER_STATUS.failed && link.status !== 'PAID') {
        return { orderStatus: current.status, invoiceStatus: invoice?.status };
      }
      const mismatch = (reason) => {
        tx.update(orderRef, { ...stamp, status: ORDER_STATUS.mismatch, mismatchReason: reason });
        if (invoice?.activeOrderCode === current.orderCode) tx.update(invoiceRef, { activeOrderCode: null });
        return { orderStatus: ORDER_STATUS.mismatch, invoiceStatus: invoice?.status ?? null, reason };
      };

      if (link.status !== 'PAID') {
        const closed = { CANCELLED: ORDER_STATUS.cancelled, EXPIRED: ORDER_STATUS.expired, FAILED: ORDER_STATUS.failed }[link.status];
        if (closed) {
          tx.update(orderRef, { ...stamp, status: closed });
          if (invoice?.activeOrderCode === current.orderCode) tx.update(invoiceRef, { activeOrderCode: null });
          return { orderStatus: closed, invoiceStatus: invoice?.status ?? null };
        }
        // PENDING / PROCESSING / UNDERPAID: still not proof of payment.
        tx.update(orderRef, { ...stamp, status: current.status === ORDER_STATUS.uncertain ? ORDER_STATUS.uncertain : ORDER_STATUS.pending });
        return { orderStatus: ORDER_STATUS.pending, providerStatus: link.status, invoiceStatus: invoice?.status ?? null };
      }

      // PAID: verify every binding before trusting it.
      if (link.orderCode !== current.orderCode) return mismatch('order_code');
      if (current.paymentLinkId && link.id && link.id !== current.paymentLinkId) return mismatch('payment_link');
      if (link.amount !== current.amount || link.amountPaid !== current.amount) return mismatch('amount');
      if (current.currency !== 'VND') return mismatch('currency');
      if (!invoice || invoice.parentId !== current.parentId || invoice.amount !== current.amount || invoice.currency !== 'VND') {
        return mismatch('invoice_binding');
      }
      if (references.length === 0) return mismatch('no_transaction_reference');
      for (const snap of referenceSnaps) {
        if (snap.exists && snap.data().orderCode !== current.orderCode) return mismatch('reference_reused');
      }
      if (invoice.status === 'verified') {
        // Paid twice (e.g. two links): keep the first, flag this one for refund.
        tx.update(orderRef, { ...stamp, status: ORDER_STATUS.paidDuplicate, paidAt: FieldValue.serverTimestamp() });
        referenceRefs.forEach((ref) => tx.set(ref, { orderCode: current.orderCode, invoiceId: order.invoiceId }));
        return { orderStatus: ORDER_STATUS.paidDuplicate, invoiceStatus: 'verified', classId: invoice.classId };
      }
      if (!revision || revision.kind !== 'class_revision' || revision.payload?.status !== 'confirmed') {
        return mismatch('revision_not_confirmed');
      }

      const classId = classIdFor(order.invoiceId);
      const terms = invoice.terms ?? {};
      referenceRefs.forEach((ref) => tx.set(ref, { orderCode: current.orderCode, invoiceId: order.invoiceId }));
      tx.update(orderRef, { ...stamp, status: ORDER_STATUS.paid, paidAt: FieldValue.serverTimestamp() });
      tx.update(invoiceRef, {
        status: 'verified',
        paidOrderCode: current.orderCode,
        paidAt: FieldValue.serverTimestamp(),
        activeOrderCode: null,
        classId,
      });
      const classSessions = buildSessions({
        classId,
        tutorId: invoice.tutorId,
        parentName: chat?.parentName,
        subject: terms.subject,
        location: terms.location,
        startDate: terms.startDate,
        schedule: terms.schedule,
        time: terms.time,
        lessonDuration: terms.lessonDuration,
        sessions: terms.sessions,
      });
      tx.set(this.db.collection('classes').doc(classId), {
        parentId: invoice.parentId,
        tutorId: invoice.tutorId,
        chatId: invoice.chatId,
        invoiceId: order.invoiceId,
        revisionId: invoice.revisionId,
        paymentStatus: 'verified',
        subject: terms.subject ?? null,
        goal: terms.goal ?? null,
        tutorName: terms.tutorName ?? null,
        date: terms.startDate ?? null,
        time: terms.time ?? terms.schedule ?? null,
        schedule: terms.schedule ?? null,
        mode: terms.mode ?? null,
        location: terms.location ?? null,
        lessonDuration: terms.lessonDuration ?? null,
        totalFee: invoice.amount,
        totalAmount: invoice.amount,
        hourlyFee: terms.fee ?? null,
        hoursPerSession: terms.hoursPerSession ?? null,
        totalSessions: terms.sessions ?? null,
        parentName: chat?.parentName ?? null,
        consultantName: chat?.consultantName ?? null,
        sessions: classSessions,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(chatRef, { onboardingStatus: CHAT_STATUS.scheduleConfirmed, classId, updatedAt: FieldValue.serverTimestamp() });
      tx.set(chatRef.collection('messages').doc(), {
        senderId: 'system', senderName: 'BeeWise', role: 'system', kind: 'system',
        body: 'Thanh toán đã được xác minh. Lịch học chính thức đã được tạo.',
        payload: { classId },
        createdAt: FieldValue.serverTimestamp(),
      });
      return { orderStatus: ORDER_STATUS.paid, invoiceStatus: 'verified', classId };
    });
  }

  /**
   * Reserves a unique order for the invoice, or returns the live one.
   * The `creating` lease stops two taps from creating two payOS links.
   */
  async #reserveOrder(parentUid, invoiceId) {
    const invoiceRef = this.db.collection('invoices').doc(invoiceId);
    return this.db.runTransaction(async (tx) => {
      const invoice = (await tx.get(invoiceRef)).data();
      if (!invoice || invoice.parentId !== parentUid) throw notFound('invoice_not_found', 'Không tìm thấy hóa đơn.');
      if (invoice.status === 'verified') throw conflict('already_paid', 'Hóa đơn đã được thanh toán.');
      if (invoice.status !== 'pending') throw conflict('invoice_not_payable', 'Hóa đơn không còn hiệu lực thanh toán.');
      if (!Number.isSafeInteger(invoice.amount) || invoice.amount < 1000 || invoice.currency !== 'VND') {
        throw conflict('invoice_invalid', 'Hóa đơn không hợp lệ.');
      }
      const nowMs = this.now().getTime();
      if (invoice.activeOrderCode) {
        const active = (await tx.get(this.db.collection('paymentOrders').doc(String(invoice.activeOrderCode)))).data();
        if (active?.status === ORDER_STATUS.pending && active.checkoutUrl && active.expiresAt?.toMillis() > nowMs + 60_000) {
          return { reuse: { invoiceId, orderCode: active.orderCode, checkoutUrl: active.checkoutUrl, expiresAt: active.expiresAt.toDate().toISOString(), reused: true } };
        }
        if (active?.status === ORDER_STATUS.creating && active.createdAt?.toMillis() > nowMs - CREATING_LEASE_MS) {
          throw conflict('checkout_in_progress', 'Đang tạo giao dịch, vui lòng đợi vài giây.');
        }
        if (active && !TERMINAL.has(active.status)) {
          // pending-but-expiring, uncertain or stale creating: provider truth first.
          return { reconcileFirst: active.orderCode };
        }
      }
      const orderCode = this.nextOrderCode();
      if (!Number.isSafeInteger(orderCode) || orderCode <= 0) throw badRequest('internal', 'orderCode không hợp lệ.');
      const expiresAtSec = Math.floor(nowMs / 1000) + this.checkoutTtlMinutes * 60;
      // create() fails if the code was ever used: orderCodes are globally unique.
      tx.create(this.db.collection('paymentOrders').doc(String(orderCode)), {
        orderCode,
        invoiceId,
        parentId: invoice.parentId,
        amount: invoice.amount,
        currency: 'VND',
        status: ORDER_STATUS.creating,
        paymentLinkId: null,
        checkoutUrl: null,
        expiresAt: Timestamp.fromMillis(expiresAtSec * 1000),
        createdAt: Timestamp.fromMillis(nowMs),
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.update(invoiceRef, { activeOrderCode: orderCode });
      return { orderCode, amount: invoice.amount, expiresAtSec };
    });
  }

  async #closeOrder(orderCode, invoiceId, status, reason) {
    const orderRef = this.db.collection('paymentOrders').doc(String(orderCode));
    const invoiceRef = this.db.collection('invoices').doc(invoiceId);
    await this.db.runTransaction(async (tx) => {
      const invoice = (await tx.get(invoiceRef)).data();
      tx.update(orderRef, { status, closeReason: reason, updatedAt: FieldValue.serverTimestamp() });
      if (invoice?.activeOrderCode === Number(orderCode)) tx.update(invoiceRef, { activeOrderCode: null });
    });
  }

  async #ownInvoice(parentUid, invoiceId) {
    const invoice = (await this.db.collection('invoices').doc(invoiceId).get()).data();
    if (!invoice || invoice.parentId !== parentUid) throw notFound('invoice_not_found', 'Không tìm thấy hóa đơn.');
    return invoice;
  }
}
