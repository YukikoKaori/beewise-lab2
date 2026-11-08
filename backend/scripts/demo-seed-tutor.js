#!/usr/bin/env node
// EMULATOR DEMO ONLY: seeds an approved tutor plus realistic chats and a verified class so the
// tutor workspace (T3/T4/T5/T6/T7) can be reviewed. Everything is produced by the real backend
// services (claim -> trial -> revision -> invoice -> fake payOS -> verified class), so it also
// exercises the production code paths. Credentials exist only inside the local Auth emulator.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { CONSULTANT_CLAIM } from '../src/auth.js';
import { createPayosGateway } from '../src/payos-gateway.js';
import { createRuntime } from '../src/runtime.js';
import { FakePayos, TEST_CHECKSUM_KEY } from '../test/support/fake-payos.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Refusing to seed: emulator hosts are not set.');
  process.exit(2);
}

const PASSWORD = 'emulator-demo-123';
export const ACCOUNTS = {
  tutor: { email: 'demo-tutor@beewise.test', displayName: 'Hoàng Thu Trang' },
  parent: { email: 'demo-parent@beewise.test', displayName: 'Chị Lan' },
  consultant: { email: 'demo-consultant@beewise.test', displayName: 'Lan' },
};

const fake = new FakePayos();
const gateway = createPayosGateway({ clientId: 'emulator', apiKey: 'emulator', checksumKey: TEST_CHECKSUM_KEY, fetch: fake.fetch });
const { auth, db, consultants, payments, tutorApplications, chatSummaries } = createRuntime(process.env, { gateway });

const ensureUser = async ({ email, displayName }) => {
  try {
    return await auth.getUserByEmail(email);
  } catch {
    return auth.createUser({ email, password: PASSWORD, displayName, emailVerified: true });
  }
};

const tutor = await ensureUser(ACCOUNTS.tutor);
const parent = await ensureUser(ACCOUNTS.parent);
const consultantUser = await ensureUser(ACCOUNTS.consultant);
await auth.setCustomUserClaims(consultantUser.uid, { [CONSULTANT_CLAIM]: true });
const staff = { uid: consultantUser.uid, displayName: ACCOUNTS.consultant.displayName };

// Tutor: approved by hand (as staff would in the console), then published to the catalog.
await db.doc(`tutorApplications/${tutor.uid}`).set({
  name: ACCOUNTS.tutor.displayName, email: ACCOUNTS.tutor.email, phone: '0387871708',
  qualification: 'Thạc sĩ Sư phạm Toán · 6 năm ôn thi vào 10',
  introduction: 'Dạy Toán 8, 9 đại số và hình học hướng chuyên, báo cáo tiến độ hằng buổi cho phụ huynh.',
  subjects: ['Toán', 'Hình học'], grades: ['8', '9'], hourlyFee: 250_000, areas: ['Cầu Giấy', 'Đống Đa'],
  teachingModes: ['online', 'in_person'], availability: 'T3 tối, T5 tối, T6 tối', consentAccepted: true,
  status: 'approved', verified: true, active: true, createdAt: FieldValue.serverTimestamp(),
});
await tutorApplications.publish(tutor.uid);
await db.doc(`tutors/${tutor.uid}`).update({ rating: 4.9, reviewCount: 24, experienceYears: 6 });

await db.doc(`parents/${parent.uid}`).set({ displayName: ACCOUNTS.parent.displayName, email: ACCOUNTS.parent.email, createdAt: FieldValue.serverTimestamp() });

const intake = async (chatId, requestId, { learningGoal, area }) => {
  await db.doc(`connectionRequests/${requestId}`).set({
    parentId: parent.uid, tutorId: tutor.uid, chatId, learningGoal, area, schedule: 'Tối thứ 3, 5', status: 'submitted',
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.doc(`chats/${chatId}`).set({
    parentId: parent.uid, tutorId: tutor.uid, consultantQueue: true, participantRoles: ['parent', 'tutor', 'consultant'],
    connectionRequestId: requestId, onboardingStatus: 'connection_pending_consultant',
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection(`chats/${chatId}/messages`).doc('request_created').set({
    senderId: 'system', senderName: 'BeeWise', role: 'system', kind: 'system',
    body: 'Yêu cầu kết nối đã được gửi. Tư vấn viên BeeWise sẽ tham gia nhóm sau khi xác nhận.', createdAt: FieldValue.serverTimestamp(),
  });
};
const parentSays = (chatId, body) => db.collection(`chats/${chatId}/messages`).add({
  senderId: parent.uid, senderName: ACCOUNTS.parent.displayName, role: 'parent', kind: 'text', body, delivery: 'delivered',
  createdAt: FieldValue.serverTimestamp(),
});
const respond = (chatId, proposalId, type) => db.doc(`chats/${chatId}/responses/${proposalId}`).create({
  parentId: parent.uid, proposalId, type, createdAt: FieldValue.serverTimestamp(),
});
const syncPreview = async (chatId) => {
  await chatSummaries.enrich(chatId);
  const newest = await db.collection(`chats/${chatId}/messages`).orderBy('createdAt', 'desc').limit(1).get();
  if (!newest.empty) await chatSummaries.recordMessage(chatId, newest.docs[0].data());
};

// Chat A: a brand-new request still waiting for a consultant.
await intake('demo_chat_new', 'demo_req_new', { learningGoal: 'Ôn thi vào lớp 10 môn Toán', area: 'Cầu Giấy' });
await parentSays('demo_chat_new', 'Em chào cô ạ, con em đang lớp 9 và cần ôn Toán thi vào 10.');
await syncPreview('demo_chat_new');

// Chat B: the complete journey, ending in a paid class with dated lessons this week and next.
await intake('demo_chat_class', 'demo_req_class', { learningGoal: 'Lấy lại căn bản Toán 8', area: 'Đống Đa' });
await parentSays('demo_chat_class', 'Chào tư vấn viên, mình muốn con học thử trước ạ.');
await consultants.claimChat(staff, 'demo_chat_class');
const trial = await consultants.proposeTrial(staff, 'demo_chat_class', {
  tutorName: ACCOUNTS.tutor.displayName, subject: 'Toán lớp 8', date: '10/11/2026', time: '19:00',
  mode: 'Trực tuyến', location: 'Google Meet', lessonContent: 'Ôn phương trình bậc nhất', fee: 0,
});
await respond('demo_chat_class', trial.proposalId, 'trial_accepted');
await consultants.processResponse(staff, 'demo_chat_class', trial.proposalId);
const revision = await consultants.proposeClassRevision(staff, 'demo_chat_class', {
  subject: 'Toán lớp 8', goal: 'Lấy lại căn bản', tutorName: ACCOUNTS.tutor.displayName, schedule: 'Thứ 3, Thứ 5',
  time: '19:00 - 20:30', mode: 'Trực tuyến', location: 'Google Meet', startDate: '10/11/2026', lessonDuration: '90 phút',
  fee: 250_000, hoursPerSession: 1.5, sessions: 8, totalFee: 3_000_000,
});
await respond('demo_chat_class', revision.proposalId, 'class_revision_confirmed');
const processed = await consultants.processResponse(staff, 'demo_chat_class', revision.proposalId);
await chatSummaries.enrich('demo_chat_class');
const { orderCode } = await payments.createCheckout(parent.uid, processed.invoiceId);
fake.pay(orderCode);
await payments.handleWebhook(await fake.webhook(orderCode));
await syncPreview('demo_chat_class');

const chat = (await db.doc('chats/demo_chat_class').get()).data();
const official = (await db.doc(`classes/${chat.classId}`).get()).data();
console.log(JSON.stringify({
  login: { tutor: ACCOUNTS.tutor.email, parent: ACCOUNTS.parent.email, password: PASSWORD },
  tutorUid: tutor.uid, chats: ['demo_chat_new', 'demo_chat_class'], classId: chat.classId,
  sessions: official.sessions.map((s) => s.startTime.toDate().toISOString()),
  chatPreview: { parentName: chat.parentName, consultantName: chat.consultantName, lastMessageText: chat.lastMessageText },
}, null, 2));
void Timestamp;
process.exit(0);
