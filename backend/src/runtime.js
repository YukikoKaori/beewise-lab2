import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { loadConfig, payosConfigured } from './config.js';
import { ChatSummaryService } from './chat-summary-service.js';
import { ConsultantService } from './consultant-service.js';
import { createPayosGateway, createUnconfiguredGateway } from './payos-gateway.js';
import { NotificationService } from './notification-service.js';
import { PaymentService } from './payment-service.js';
import { TutorApplicationService } from './tutor-application-service.js';

/** Wires Admin SDK + services from the environment (credentials via ADC). */
export function createRuntime(env = process.env, overrides = {}) {
  const config = loadConfig(env);
  const app = getApps()[0] ?? initializeApp({ projectId: env.FIREBASE_PROJECT_ID ?? env.GCLOUD_PROJECT });
  const db = getFirestore(app);
  const auth = getAuth(app);
  const gateway = overrides.gateway
    ?? (payosConfigured(config) ? createPayosGateway(config.payos) : createUnconfiguredGateway());
  const consultants = new ConsultantService({ db, invoiceDueDays: config.invoiceDueDays, now: overrides.now });
  const payments = new PaymentService({
    db,
    gateway,
    publicBaseUrl: config.publicBaseUrl,
    checkoutTtlMinutes: config.checkoutTtlMinutes,
    now: overrides.now,
    nextOrderCode: overrides.nextOrderCode,
  });
  const tutorApplications = new TutorApplicationService({ db });
  const chatSummaries = new ChatSummaryService({ db });
  const notifications = new NotificationService({ db });
  return { config, db, auth, gateway, consultants, payments, tutorApplications, chatSummaries, notifications };
}
