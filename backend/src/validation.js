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
    ...billing(input),
  };
}

/**
 * Optional billing breakdown (hourly fee x hours per session x sessions). When given,
 * totalFee MUST equal it, so the invoice amount is exactly the fee the parent sees.
 */
function billing(input) {
  const { hoursPerSession, sessions } = input;
  if (hoursPerSession == null && sessions == null) return {};
  if (typeof hoursPerSession !== 'number' || !(hoursPerSession > 0) || hoursPerSession > 12) {
    throw badRequest('invalid_argument', 'hoursPerSession phải là số giờ lớn hơn 0 và không quá 12.');
  }
  if (!Number.isInteger(sessions) || sessions < 1 || sessions > 100) {
    throw badRequest('invalid_argument', 'sessions phải là số nguyên từ 1 đến 100.');
  }
  const expected = Math.round(input.fee * hoursPerSession * sessions);
  if (input.totalFee !== expected) {
    throw badRequest('invalid_argument', `totalFee phải bằng fee x hoursPerSession x sessions (${expected}).`);
  }
  return { hoursPerSession, sessions };
}

const TEACHING_MODES = new Set(['online', 'in_person']);

/** Plain-string list: trimmed, non-empty, bounded, no duplicates. */
export function stringList(value, field, { min = 1, max = 10, itemMax = 100 } = {}) {
  if (!Array.isArray(value)) throw badRequest('invalid_argument', `${field} phải là danh sách.`);
  const items = value.map((item) => {
    if (typeof item !== 'string' || item.trim().length === 0 || item.trim().length > itemMax) {
      throw badRequest('invalid_argument', `${field} chứa giá trị không hợp lệ.`);
    }
    return item.trim();
  });
  const unique = [...new Set(items)];
  if (unique.length < min || unique.length > max) {
    throw badRequest('invalid_argument', `${field} phải có từ ${min} đến ${max} mục.`);
  }
  return unique;
}

const boundedText = (value, field, min, max) => {
  const parsed = text(value, field, { max });
  if (parsed.length < min) throw badRequest('invalid_argument', `${field} phải có từ ${min} đến ${max} ký tự.`);
  return parsed;
};

/**
 * Editable tutor application fields. Mirrors the limits in firebase/firestore.rules
 * (tutorApplications create) so a resubmission can never be looser than a first submission.
 * Email and status are deliberately NOT accepted: they are never client-controlled here.
 */
export function tutorApplicationPayload(input = {}) {
  if (!Number.isSafeInteger(input.hourlyFee) || input.hourlyFee < 1 || input.hourlyFee > 100_000_000) {
    throw badRequest('invalid_argument', 'hourlyFee phải là số nguyên VND hợp lệ.');
  }
  const teachingModes = stringList(input.teachingModes, 'teachingModes', { max: 2 });
  if (!teachingModes.every((item) => TEACHING_MODES.has(item))) {
    throw badRequest('invalid_argument', 'teachingModes chỉ nhận online hoặc in_person.');
  }
  return {
    name: boundedText(input.name, 'name', 2, 100),
    phone: boundedText(input.phone, 'phone', 9, 20),
    qualification: boundedText(input.qualification, 'qualification', 2, 300),
    introduction: boundedText(input.introduction, 'introduction', 20, 1000),
    subjects: stringList(input.subjects, 'subjects', { max: 10 }),
    grades: stringList(input.grades, 'grades', { max: 12 }),
    hourlyFee: input.hourlyFee,
    areas: stringList(input.areas, 'areas', { max: 10 }),
    teachingModes,
    availability: boundedText(input.availability, 'availability', 2, 500),
  };
}

export function ttlHours(value, fallback = 48) {
  if (value == null) return fallback;
  if (!Number.isInteger(value) || value < 1 || value > 24 * 14) {
    throw badRequest('invalid_argument', 'ttlHours phải là số nguyên từ 1 đến 336.');
  }
  return value;
}
