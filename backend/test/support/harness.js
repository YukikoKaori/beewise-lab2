// EMULATOR-ONLY test harness: Auth + Firestore emulators on demo-beewise-workflow.
import assert from 'node:assert/strict';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { CONSULTANT_CLAIM } from '../../src/auth.js';
import { ChatSummaryService } from '../../src/chat-summary-service.js';
import { ConsultantService } from '../../src/consultant-service.js';
import { createPayosGateway } from '../../src/payos-gateway.js';
import { PaymentService } from '../../src/payment-service.js';
import { TutorApplicationService } from '../../src/tutor-application-service.js';
import { FakePayos, TEST_CHECKSUM_KEY } from './fake-payos.js';

export const PROJECT_ID = 'demo-beewise-workflow';

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
assert.ok(firestoreHost && authHost, 'Run through `npm test` so the Firestore and Auth emulators are started.');

const app = getApps()[0] ?? initializeApp({ projectId: PROJECT_ID });
export const db = getFirestore(app);
export const auth = getAuth(app);

export async function resetEmulators() {
  await fetch(`http://${firestoreHost}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' });
}

let orderSeq = 1_000_000;

/** Fresh services wired to a fresh fake payOS for each test. */
export function makeServices({ now } = {}) {
  const payos = new FakePayos();
  const gateway = createPayosGateway({ clientId: 'emulator-client', apiKey: 'emulator-key', checksumKey: TEST_CHECKSUM_KEY, fetch: payos.fetch });
  const consultants = new ConsultantService({ db, now });
  const payments = new PaymentService({
    db, gateway, publicBaseUrl: 'https://beewise.test', now, nextOrderCode: () => ++orderSeq,
  });
  const tutorApplications = new TutorApplicationService({ db });
  const chatSummaries = new ChatSummaryService({ db });
  return { payos, gateway, consultants, payments, tutorApplications, chatSummaries };
}

export async function createUser(email, { consultant = false, displayName } = {}) {
  const user = await auth.createUser({ email, password: 'emulator-only-pass', displayName });
  if (consultant) await auth.setCustomUserClaims(user.uid, { [CONSULTANT_CLAIM]: true });
  return user;
}

/** ID token from the Auth emulator's REST endpoint (emulator accepts any API key). */
export async function idToken(email) {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'emulator-only-pass', returnSecureToken: true }),
  });
  const body = await response.json();
  assert.ok(body.idToken, `sign-in failed for ${email}`);
  return body.idToken;
}

/** Seeds what the Flutter client batch creates for a connection request (F-01). */
export async function seedIntake({ parentUid, tutorId = 'tutor_demo', chatId = 'chat_1', requestId = 'req_1', active = true } = {}) {
  await db.doc(`tutors/${tutorId}`).set({ name: 'Gia sư Demo', active, verified: false, demoOnly: true });
  await db.doc(`connectionRequests/${requestId}`).set({ parentId: parentUid, tutorId, chatId, status: 'pending', createdAt: FieldValue.serverTimestamp() });
  await db.doc(`chats/${chatId}`).set({
    parentId: parentUid, tutorId, consultantQueue: true, participantRoles: ['parent', 'tutor', 'consultant'],
    connectionRequestId: requestId, onboardingStatus: 'connection_pending_consultant',
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { chatId, tutorId, requestId };
}

/** Writes a parent response as the Rules-checked client would (createdAt = server time). */
export async function respond(chatId, proposalId, parentUid, type, extra = {}) {
  await db.doc(`chats/${chatId}/responses/${proposalId}`).create({
    parentId: parentUid, proposalId, type, ...extra, createdAt: FieldValue.serverTimestamp(),
  });
}

export const trialInput = {
  tutorName: 'Gia sư Demo', subject: 'Toán lớp 8', date: '10/11/2026', time: '19:00',
  mode: 'Trực tuyến', location: 'Google Meet', lessonContent: 'Ôn tập phương trình', fee: 0,
};

export const revisionInput = {
  subject: 'Toán lớp 8', goal: 'Lấy lại căn bản', tutorName: 'Gia sư Demo', schedule: 'Thứ 3, Thứ 5',
  time: '19:00 - 20:30', mode: 'Trực tuyến', location: 'Google Meet', startDate: '17/11/2026',
  lessonDuration: '90 phút', fee: 250_000, totalFee: 2_000_000,
};

export const staffOf = (user) => ({ uid: user.uid, displayName: 'Tư vấn viên A' });

/**
 * Runs the consultant flow up to an issued invoice. Returns ids for payment tests.
 */
export async function issueInvoice({ consultants, parent, consultant, chatId = 'chat_1', requestId = 'req_1', totalFee, revision: revisionOverrides = {} }) {
  await seedIntake({ parentUid: parent.uid, chatId, requestId });
  const staff = staffOf(consultant);
  await consultants.claimChat(staff, chatId);
  const trial = await consultants.proposeTrial(staff, chatId, trialInput);
  await respond(chatId, trial.proposalId, parent.uid, 'trial_accepted');
  await consultants.processResponse(staff, chatId, trial.proposalId);
  const revision = await consultants.proposeClassRevision(staff, chatId, { ...revisionInput, ...(totalFee ? { totalFee } : {}), ...revisionOverrides });
  await respond(chatId, revision.proposalId, parent.uid, 'class_revision_confirmed');
  const processed = await consultants.processResponse(staff, chatId, revision.proposalId);
  return { chatId, staff, revisionId: revision.proposalId, invoiceId: processed.invoiceId };
}

export { FieldValue, Timestamp };
