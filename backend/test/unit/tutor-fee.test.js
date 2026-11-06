import assert from 'node:assert/strict';
import test from 'node:test';
import { withTutorFee } from '../../src/tutor-fee.js';

/** Minimal Firestore stand-in: collection(name).doc(id).get() -> { data() }. */
const fakeDb = (docs) => ({
  collection: (name) => ({
    doc: (id) => ({ get: async () => ({ data: () => docs[name]?.[id] }) }),
  }),
});

const db = fakeDb({
  chats: { chat1: { tutorId: 'tutor1' }, orphan: {} },
  tutors: { tutor1: { hourlyFee: 150000 }, free: {} },
});

test('fee defaults to the tutor hourly fee and totalFee follows the breakdown', async () => {
  const out = await withTutorFee(db, 'chat1', { hoursPerSession: 1.5, sessions: 8 });
  assert.equal(out.fee, 150000);
  assert.equal(out.totalFee, 1_800_000);
});

test('an explicit fee (test override) is used instead of the tutor fee', async () => {
  const out = await withTutorFee(db, 'chat1', { fee: 2000, hoursPerSession: 1, sessions: 1 });
  assert.equal(out.fee, 2000);
  assert.equal(out.totalFee, 2000);
});

test('a payload that already has fee and totalFee is returned unchanged', async () => {
  const payload = { fee: 5000, totalFee: 5000 };
  assert.deepEqual(await withTutorFee(db, 'chat1', payload), payload);
});

test('totalFee without fee is rejected instead of being silently overwritten', async () => {
  await assert.rejects(
    withTutorFee(db, 'chat1', { totalFee: 99000, hoursPerSession: 1, sessions: 1 }),
    /together with/,
  );
});

test('missing breakdown, chat or hourly fee fail with a clear message', async () => {
  await assert.rejects(withTutorFee(db, 'chat1', {}), /hoursPerSession/);
  await assert.rejects(
    withTutorFee(db, 'orphan', { hoursPerSession: 1, sessions: 1 }),
    /no tutorId/,
  );
  const noFee = fakeDb({ chats: { c: { tutorId: 'free' } }, tutors: { free: {} } });
  await assert.rejects(
    withTutorFee(noFee, 'c', { hoursPerSession: 1, sessions: 1 }),
    /no hourlyFee/,
  );
});
