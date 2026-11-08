import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildSessions, parseDate, parseTimeRange, parseWeekdays } from '../../src/schedule.js';

const terms = {
  classId: 'cls_1', tutorId: 'tutor_1', parentName: 'Chị Lan', subject: 'Toán lớp 8', location: 'Google Meet',
  startDate: '17/11/2026', schedule: 'Thứ 3, Thứ 5', time: '19:00 - 20:30', lessonDuration: '90 phút', sessions: 4,
};

test('weekday, date and time parsing accept the formats staff actually type', () => {
  assert.deepEqual([...parseWeekdays('Thứ 3, Thứ 5')].sort(), [2, 4]);
  assert.deepEqual([...parseWeekdays('T2-T4-T6, Chủ nhật')].sort(), [0, 1, 3, 5]);
  assert.deepEqual([...parseWeekdays('thứ hai và thứ bảy')].sort(), [1, 6]);
  assert.equal(parseWeekdays('hằng ngày').size, 0);
  assert.deepEqual(parseDate('17/11/2026'), { year: 2026, month: 11, day: 17 });
  for (const bad of ['31/02/2026', '2026-11-17', '', null, '1/1/26']) assert.equal(parseDate(bad), null);
  assert.deepEqual(parseTimeRange('19:00 - 20:30'), { start: 1140, end: 1230 });
  assert.deepEqual(parseTimeRange('19h30', '90 phút'), { start: 1170, end: 1260 });
  assert.deepEqual(parseTimeRange('19:00', '1,5 giờ'), { start: 1140, end: 1230 });
  for (const bad of [['20:00 - 19:00'], ['25:00 - 26:00'], ['19:00'], ['sáng']]) assert.equal(parseTimeRange(...bad), null);
});

test('sessions follow the chosen weekdays from the start date, in Vietnam time', () => {
  const sessions = buildSessions(terms);
  assert.equal(sessions.length, 4);
  assert.deepEqual(sessions.map((s) => s.startTime.toDate().toISOString()), [
    '2026-11-17T12:00:00.000Z', '2026-11-19T12:00:00.000Z', '2026-11-24T12:00:00.000Z', '2026-11-26T12:00:00.000Z',
  ]);
  assert.equal(sessions[0].endTime.toDate().toISOString(), '2026-11-17T13:30:00.000Z');
  assert.deepEqual(sessions.map((s) => s.sessionNumber), [1, 2, 3, 4]);
  assert.ok(sessions.every((s) => s.totalSessions === 4 && s.tutorId === 'tutor_1' && s.classId === 'cls_1' && s.confirmed === true));
  assert.equal(sessions[0].id, 'cls_1_s1');
  assert.equal(sessions[0].parentName, 'Chị Lan');
});

test('a start date that is not a class weekday begins on the next class day', () => {
  const [first] = buildSessions({ ...terms, startDate: '18/11/2026', sessions: 1 });
  assert.equal(first.startTime.toDate().toISOString(), '2026-11-19T12:00:00.000Z');
});

test('unreliable terms yield no sessions instead of invented ones', () => {
  for (const patch of [
    { sessions: undefined }, { sessions: 0 }, { sessions: 101 }, { sessions: 2.5 }, { startDate: '31/02/2026' },
    { schedule: 'linh hoạt' }, { time: 'buổi tối', lessonDuration: '' },
  ]) assert.deepEqual(buildSessions({ ...terms, ...patch }), [], JSON.stringify(patch));
});
