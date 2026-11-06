import assert from 'node:assert/strict';
import test from 'node:test';
import { classRevisionPayload } from '../../src/validation.js';

const base = {
  subject: 'Toán lớp 8',
  tutorName: 'Hoàng Quốc Bảo',
  schedule: 'Thứ 3, Thứ 5',
  time: '19:00 - 20:30',
  mode: 'Trực tuyến',
  location: 'Google Meet',
  startDate: '17/11/2026',
  lessonDuration: '90 phút',
};

test('billing breakdown is kept when totalFee = fee x hours x sessions', () => {
  const payload = classRevisionPayload({
    ...base,
    fee: 150000,
    hoursPerSession: 1.5,
    sessions: 8,
    totalFee: 1800000,
  });
  assert.equal(payload.hoursPerSession, 1.5);
  assert.equal(payload.sessions, 8);
  assert.equal(payload.totalFee, 1800000);
});

test('totalFee that disagrees with the breakdown is rejected', () => {
  assert.throws(
    () => classRevisionPayload({
      ...base,
      fee: 150000,
      hoursPerSession: 1.5,
      sessions: 8,
      totalFee: 2000,
    }),
    /totalFee phải bằng/,
  );
});

test('payload without a breakdown still validates (legacy shape)', () => {
  const payload = classRevisionPayload({ ...base, fee: 5000, totalFee: 5000 });
  assert.equal(payload.hoursPerSession, undefined);
  assert.equal(payload.totalFee, 5000);
});
