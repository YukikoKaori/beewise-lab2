import { Timestamp } from 'firebase-admin/firestore';

const VN_OFFSET = '+07:00';
const MAX_SESSIONS = 100;
const MAX_SCAN_DAYS = 400;

/** "Thứ 3, Thứ 5" / "T2-T4-T6" / "Thứ hai, Chủ nhật" -> Set of JS weekdays (Sun=0). */
export function parseWeekdays(schedule) {
  const days = new Set();
  const text = String(schedule ?? '').toLowerCase();
  for (const match of text.matchAll(/(?:th[ứư]|t)\s*([2-7])/g)) days.add(Number(match[1]) - 1);
  const words = { hai: 1, ba: 2, 'tư': 3, 'tu': 3, 'năm': 4, nam: 4, 'sáu': 5, sau: 5, 'bảy': 6, bay: 6 };
  for (const match of text.matchAll(/th[ứư]\s*(hai|ba|tư|tu|năm|nam|sáu|sau|bảy|bay)/g)) days.add(words[match[1]]);
  if (/ch[ủu]\s*nh[ậa]t|\bcn\b/.test(text)) days.add(0);
  return days;
}

/** "17/11/2026" -> { year, month, day } or null. */
export function parseDate(value) {
  const match = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(String(value ?? '').trim());
  if (!match) return null;
  const [day, month, year] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const check = new Date(Date.UTC(year, month - 1, day));
  if (check.getUTCFullYear() !== year || check.getUTCMonth() !== month - 1 || check.getUTCDate() !== day) return null;
  return { year, month, day };
}

const minutesOf = (hours, minutes) => Number(hours) * 60 + Number(minutes ?? 0);

/** "19:00 - 20:30" or "19:00" + "90 phút" -> { start, end } in minutes from midnight, or null. */
export function parseTimeRange(time, lessonDuration) {
  const range = /(\d{1,2})\s*[:h]\s*(\d{2})?\s*(?:-|–|đến)\s*(\d{1,2})\s*[:h]\s*(\d{2})?/i.exec(String(time ?? ''));
  if (range) {
    const start = minutesOf(range[1], range[2]);
    const end = minutesOf(range[3], range[4]);
    if (start < 24 * 60 && end > start && end <= 24 * 60) return { start, end };
    return null;
  }
  const single = /(\d{1,2})\s*[:h]\s*(\d{2})?/i.exec(String(time ?? ''));
  const duration = /(\d+(?:[.,]\d+)?)\s*(phút|giờ|h)/i.exec(String(lessonDuration ?? ''));
  if (!single || !duration) return null;
  const amount = Number(duration[1].replace(',', '.'));
  const length = Math.round(duration[2].toLowerCase() === 'phút' ? amount : amount * 60);
  const start = minutesOf(single[1], single[2]);
  return start < 24 * 60 && length > 0 && start + length <= 24 * 60 ? { start, end: start + length } : null;
}

const two = (value) => String(value).padStart(2, '0');
const at = ({ year, month, day }, minutes) =>
  new Date(`${year}-${two(month)}-${two(day)}T${two(Math.floor(minutes / 60))}:${two(minutes % 60)}:00${VN_OFFSET}`);

/**
 * Official lesson sessions for a verified class, derived from the confirmed class revision.
 * Returns [] (never throws) when the terms cannot be turned into dates reliably: a missing
 * schedule must never block or fail a verified payment, and sessions are never invented.
 */
export function buildSessions({ classId, tutorId, parentName, subject, location, startDate, schedule, time, lessonDuration, sessions }) {
  try {
    if (!Number.isInteger(sessions) || sessions < 1 || sessions > MAX_SESSIONS) return [];
    const start = parseDate(startDate);
    const weekdays = parseWeekdays(schedule);
    const range = parseTimeRange(time, lessonDuration);
    if (!start || weekdays.size === 0 || !range) return [];

    const out = [];
    const cursor = new Date(Date.UTC(start.year, start.month - 1, start.day));
    for (let scanned = 0; scanned < MAX_SCAN_DAYS && out.length < sessions; scanned += 1) {
      if (weekdays.has(cursor.getUTCDay())) {
        const day = { year: cursor.getUTCFullYear(), month: cursor.getUTCMonth() + 1, day: cursor.getUTCDate() };
        out.push({
          id: `${classId}_s${out.length + 1}`,
          classId,
          tutorId,
          subjectTitle: subject ?? '',
          parentName: parentName ?? '',
          locationSummary: location ?? '',
          startTime: Timestamp.fromDate(at(day, range.start)),
          endTime: Timestamp.fromDate(at(day, range.end)),
          sessionNumber: out.length + 1,
          totalSessions: sessions,
          confirmed: true,
        });
      }
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
    return out.length === sessions ? out : [];
  } catch {
    return [];
  }
}
