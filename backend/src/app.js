import express from 'express';
import { authenticate, requireConsultant } from './auth.js';
import { HttpError } from './errors.js';

const asyncRoute = (handler) => (req, res, next) => handler(req, res).catch(next);

const escapeHtml = (value) => String(value).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const INVOICE_ID = /^[A-Za-z0-9_-]{1,128}$/;
const APP_PACKAGE = 'com.beewise.beewise';

/**
 * Browser page shown after payOS. Its job is to bring the parent straight back into the app:
 * an Android intent link is tried automatically and a big button is the reliable fallback
 * (browsers may block automatic app launches without a tap).
 */
const returnPage = ({ title, message, invoiceId }) => {
  const path = INVOICE_ID.test(invoiceId ?? '') ? `/payment/${invoiceId}` : '/messages';
  const intent = `intent://app${path}#Intent;scheme=beewise;package=${APP_PACKAGE};end`;
  const scheme = `beewise://app${path}`;
  return `<!doctype html><html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)}</title></head>
<body style="font-family:sans-serif;max-width:480px;margin:48px auto;padding:0 16px;text-align:center">
<h1 style="font-size:22px">${escapeHtml(title)}</h1><p>${escapeHtml(message)}</p>
<p><a href="${intent}" style="display:inline-block;padding:14px 28px;background:#1e3ad6;color:#fff;border-radius:24px;text-decoration:none;font-weight:bold">Mở lại ứng dụng BeeWise</a></p>
<p style="font-size:13px;color:#555">Nếu ứng dụng không tự mở, bấm nút trên hoặc <a href="${scheme}">thử liên kết này</a>.</p>
<script>setTimeout(function(){ window.location.href = ${JSON.stringify(intent)}; }, 600);</script>
</body></html>`;
};

/**
 * HTTP surface. Parents and staff authenticate with Firebase ID tokens; the
 * webhook authenticates with the payOS signature. No route trusts client-sent
 * owner IDs, amounts or statuses.
 */
export function createApp({ auth, consultants, payments, tutorApplications, logger = console, extraRoutes }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '32kb' }));

  const parent = async (req) => {
    const token = await authenticate(auth, req.get('authorization'));
    if (token.firebase?.sign_in_provider === 'anonymous') {
      throw new HttpError(401, 'unauthenticated', 'Bạn cần đăng nhập để thanh toán.');
    }
    return token.uid;
  };
  const staff = async (req) => {
    const token = await authenticate(auth, req.get('authorization'));
    return requireConsultant(auth, token.uid);
  };

  const applicant = async (req) => {
    const token = await authenticate(auth, req.get('authorization'));
    if (token.firebase?.sign_in_provider === 'anonymous') {
      throw new HttpError(401, 'unauthenticated', 'Bạn cần đăng nhập để cập nhật hồ sơ.');
    }
    return token.uid;
  };

  app.get('/healthz', (_req, res) => res.json({ ok: true }));

  // The applicant is always the caller: the body never names an owner, status or email.
  app.post('/v1/tutor-applications/resubmit', asyncRoute(async (req, res) => {
    res.json(await tutorApplications.resubmit(await applicant(req), req.body));
  }));
  // Staff approve by hand in the console; this publishes the approved profile to the catalog.
  app.post('/v1/staff/tutor-applications/:uid/publish', asyncRoute(async (req, res) => {
    await staff(req);
    res.json(await tutorApplications.publish(req.params.uid));
  }));

  app.post('/v1/payments/checkout', asyncRoute(async (req, res) => {
    const uid = await parent(req);
    res.json(await payments.createCheckout(uid, req.body?.invoiceId));
  }));

  app.post('/v1/payments/reconcile', asyncRoute(async (req, res) => {
    const uid = await parent(req);
    res.json(await payments.reconcileInvoice(uid, req.body?.invoiceId));
  }));

  app.post('/v1/payos/webhook', asyncRoute(async (req, res) => {
    const { httpStatus, body } = await payments.handleWebhook(req.body ?? {});
    res.status(httpStatus).json(body);
  }));

  // Redirect targets after checkout. They never change payment state themselves: the return page
  // only asks payOS (see PaymentService.handleReturn) and then sends the parent back into the app.
  app.get('/v1/payos/return', asyncRoute(async (req, res) => {
    const info = await payments.handleReturn(req.query.orderCode).catch(() => null);
    const paid = info && ['paid', 'paid_duplicate'].includes(info.orderStatus);
    res.type('html').send(returnPage({
      invoiceId: info?.invoiceId,
      title: paid ? 'Thanh toán thành công' : 'Đang xác nhận thanh toán',
      message: paid
        ? 'BeeWise đã xác minh thanh toán với payOS. Lịch học chính thức đã được tạo.'
        : 'Hệ thống đang xác minh thanh toán với payOS. Lịch học chỉ được mở sau khi xác minh xong; ứng dụng sẽ tự cập nhật.',
    }));
  }));
  app.get('/v1/payos/cancel', asyncRoute(async (req, res) => {
    const info = await payments.handleReturn(req.query.orderCode).catch(() => null);
    res.type('html').send(returnPage({
      invoiceId: info?.invoiceId,
      title: 'Đã hủy thanh toán',
      message: 'Bạn có thể mở lại ứng dụng BeeWise và thanh toán lại khi sẵn sàng. Lịch học chỉ được mở sau khi hệ thống xác minh thanh toán.',
    }));
  }));

  app.post('/v1/staff/chats/:chatId/claim', asyncRoute(async (req, res) => {
    res.json(await consultants.claimChat(await staff(req), req.params.chatId));
  }));
  app.post('/v1/staff/chats/:chatId/trial-proposals', asyncRoute(async (req, res) => {
    const result = await consultants.proposeTrial(await staff(req), req.params.chatId, req.body?.payload, { ttl: req.body?.ttlHours });
    res.status(201).json(result);
  }));
  app.post('/v1/staff/chats/:chatId/class-revisions', asyncRoute(async (req, res) => {
    const result = await consultants.proposeClassRevision(await staff(req), req.params.chatId, req.body?.payload, { ttl: req.body?.ttlHours });
    res.status(201).json(result);
  }));
  app.post('/v1/staff/chats/:chatId/responses/:proposalId/process', asyncRoute(async (req, res) => {
    res.json(await consultants.processResponse(await staff(req), req.params.chatId, req.params.proposalId));
  }));

  extraRoutes?.(app);

  app.use((_req, res) => res.status(404).json({ error: { code: 'not_found', message: 'Not found' } }));
  // Express identifies error middleware by its four parameters.
  // eslint-disable-next-line no-unused-vars
  app.use((error, _req, res, _next) => {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ error: { code: error.code, message: error.message } });
    }
    if (error?.type === 'entity.parse.failed' || error?.type === 'entity.too.large') {
      return res.status(400).json({ error: { code: 'invalid_body', message: 'Nội dung yêu cầu không hợp lệ.' } });
    }
    logger.error?.('[beewise-backend] unhandled error', error?.name, error?.message);
    return res.status(500).json({ error: { code: 'internal', message: 'Lỗi máy chủ. Vui lòng thử lại.' } });
  });
  return app;
}
