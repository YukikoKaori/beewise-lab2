/**
 * The invoice must charge what the app shows: the tutor's listed hourly fee.
 *
 * Given the consultant's class-revision JSON, fills `fee` and `totalFee`:
 *   fee      = payload.fee, or tutors/{chat.tutorId}.hourlyFee when omitted
 *   totalFee = fee x hoursPerSession x sessions
 * A payload that already carries both `fee` and `totalFee` is returned unchanged
 * (the server-side `classRevisionPayload` still checks it against any breakdown).
 */
export async function withTutorFee(db, chatId, payload) {
  if (payload.fee != null && payload.totalFee != null) return payload;
  if (payload.totalFee != null) {
    throw new Error('Set `fee` together with `totalFee`, or leave both out so they are derived.');
  }

  const { hoursPerSession, sessions } = payload;
  if (typeof hoursPerSession !== 'number' || !Number.isInteger(sessions)) {
    throw new Error('Set hoursPerSession (e.g. 1.5) and sessions (e.g. 8) in the JSON file.');
  }

  let fee = payload.fee;
  if (fee == null) {
    const chat = await db.collection('chats').doc(chatId).get();
    const tutorId = chat.data()?.tutorId;
    if (!tutorId) throw new Error(`Chat ${chatId} has no tutorId.`);
    const tutor = await db.collection('tutors').doc(tutorId).get();
    const hourlyFee = tutor.data()?.hourlyFee;
    if (!Number.isSafeInteger(hourlyFee) || hourlyFee <= 0) {
      throw new Error(`Tutor ${tutorId} has no hourlyFee.`);
    }
    fee = hourlyFee;
  }
  return { ...payload, fee, totalFee: Math.round(fee * hoursPerSession * sessions) };
}
