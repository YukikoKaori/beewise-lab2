#!/usr/bin/env node
// EMULATOR DEMO ONLY: creates one parent, one consultant and one demo tutor.
// Credentials below exist only inside the local Auth emulator.
import { FieldValue } from 'firebase-admin/firestore';
import { CONSULTANT_CLAIM } from '../src/auth.js';
import { createRuntime } from '../src/runtime.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Refusing to seed: emulator hosts are not set.');
  process.exit(2);
}

export const DEMO_ACCOUNTS = {
  parent: { email: 'demo-parent@beewise.test', password: 'emulator-demo-123', displayName: 'Phụ huynh Demo' },
  consultant: { email: 'demo-consultant@beewise.test', password: 'emulator-demo-123', displayName: 'Tư vấn viên Lan' },
};

const { auth, db } = createRuntime();
const ensureUser = async ({ email, password, displayName }) => {
  try {
    return await auth.getUserByEmail(email);
  } catch {
    return auth.createUser({ email, password, displayName, emailVerified: true });
  }
};

const parent = await ensureUser(DEMO_ACCOUNTS.parent);
const consultant = await ensureUser(DEMO_ACCOUNTS.consultant);
await auth.setCustomUserClaims(consultant.uid, { [CONSULTANT_CLAIM]: true });
await db.doc('tutors/tutor_emulator_demo').set({
  name: 'Gia sư Demo (EMULATOR)',
  credential: 'Cử nhân Sư phạm Toán',
  introduction: 'Hồ sơ giả lập chỉ dùng cho video demo trên Firebase emulator.',
  subjects: ['Toán'],
  grades: ['8', '9'],
  hourlyFee: 250000,
  areas: ['TP.HCM'],
  teachingModes: ['online'],
  availability: 'Tối thứ 3, 5, 7',
  active: true,
  verified: true,
  rating: 4.8,
  reviewCount: 12,
  createdAt: FieldValue.serverTimestamp(),
});
console.log(JSON.stringify({ parentUid: parent.uid, consultantUid: consultant.uid, tutorId: 'tutor_emulator_demo' }, null, 2));
process.exit(0);
