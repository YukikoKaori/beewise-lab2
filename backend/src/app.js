import express from 'express';
import { authenticate, requireConsultant } from './auth.js';
import { HttpError } from './errors.js';

const asyncRoute = (handler) => (req, res, next) => handler(req, res).catch(next);

const page = (title, message) => `<!doctype html><html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title></head>
<body style="font-family:sans-serif;max-width:480px;margin:48px auto;padding:0 16px;text-align:center">
<h1 style="font-size:22px">${title}</h1><p>${message}</p></body></html>`;

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

  // Redirect targets after checkout. Informational only: they never change state.
  app.get('/v1/payos/return', (_req, res) => res.type('html').send(page(
    'Đã quay lại từ trang thanh toán',
    'Hãy mở lại ứng dụng BeeWise. Lịch học chỉ được mở sau khi hệ thống xác minh thanh toán với payOS.',
  )));
  app.get('/v1/payos/cancel', (_req, res) => res.type('html').send(page(
    'Đã hủy thanh toán',
    'Bạn có thể mở lại ứng dụng BeeWise và tạo lại liên kết thanh toán khi sẵn sàng.',
  )));

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
