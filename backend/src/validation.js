import { badRequest } from './errors.js';

const ID = /^[A-Za-z0-9_-]{1,128}$/;

/** Accepts only plain Firestore document IDs (no slashes or path tricks). */
export function docId(value, field = 'id') {
  if (typeof value !== 'string' || !ID.test(value)) {
    throw badRequest('invalid_argument', `${field} không hợp lệ.`);
  }
  return value;
}

export function text(value, field, { max = 200, required = true } = {}) {
  if (value == null || value === '') {
    if (required) throw badRequest('invalid_argument', `Thiếu ${field}.`);
    return null;
  }
  if (typeof value !== 'string') throw badRequest('invalid_argument', `${field} phải là chuỗi.`);
  const trimmed = value.trim();
  if ((required && trimmed.length === 0) || trimmed.length > max) {
    throw badRequest('invalid_argument', `${field} phải có từ 1 đến ${max} ký tự.`);
  }
  return trimmed.length === 0 ? null : trimmed;
}

/** VND amounts are whole numbers; the cap keeps a typo from issuing a huge invoice. */
export function vnd(value, field, { max = 100_000_000 } = {}) {
  if (!Number.isSafeInteger(value) || value < 1000 || value > max) {
    throw badRequest('invalid_argument', `${field} phải là số nguyên VND từ 1.000 đến ${max.toLocaleString('vi-VN')}.`);
  }
  return value;
}

const MODES = new Set(['Trực tuyến', 'Tại nhà', 'Tại trung tâm']);

export function mode(value) {
  const parsed = text(value, 'mode', { max: 40 });
  if (!MODES.has(parsed)) {
    throw badRequest('invalid_argument', `mode phải là một trong: ${[...MODES].join(', ')}.`);
  }
  return parsed;
}

/** Fields the Flutter Trial screen renders (lib/screens/beewise_screens.dart). */
export function trialPayload(input = {}) {
  return {
    tutorName: text(input.tutorName, 'tutorName', { max: 120 }),
    subject: text(input.subject, 'subject', { max: 120 }),
    date: text(input.date, 'date', { max: 40 }),
    time: text(input.time, 'time', { max: 40 }),
    mode: mode(input.mode),
    location: text(input.location, 'location', { max: 200 }),
    lessonContent: text(input.lessonContent, 'lessonContent', { max: 500 }),
    fee: input.fee === 0 ? 0 : vnd(input.fee, 'fee'),
  };
}

/** Fields the Flutter Class confirmation screen renders; totalFee becomes the invoice amount. */
export function classRevisionPayload(input = {}) {
  return {
    subject: text(input.subject, 'subject', { max: 120 }),
    goal: text(input.goal, 'goal', { max: 200, required: false }),
    tutorName: text(input.tutorName, 'tutorName', { max: 120 }),
    schedule: text(input.schedule, 'schedule', { max: 120 }),
    time: text(input.time, 'time', { max: 40 }),
    mode: mode(input.mode),
    location: text(input.location, 'location', { max: 200 }),
    startDate: text(input.startDate, 'startDate', { max: 40 }),
    lessonDuration: text(input.lessonDuration, 'lessonDuration', { max: 40 }),
    fee: vnd(input.fee, 'fee'),
    totalFee: vnd(input.totalFee, 'totalFee'),
  };
}

export function ttlHours(value, fallback = 48) {
  if (value == null) return fallback;
  if (!Number.isInteger(value) || value < 1 || value > 24 * 14) {
    throw badRequest('invalid_argument', 'ttlHours phải là số nguyên từ 1 đến 336.');
  }
  return value;
}
