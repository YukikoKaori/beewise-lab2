import { forbidden, unauthorized } from './errors.js';

export const CONSULTANT_CLAIM = 'beewiseConsultant';

/**
 * Verifies a Firebase ID token from `Authorization: Bearer <token>`.
 * `checkRevoked` makes staff revocation (revokeRefreshTokens) effective at once.
 */
export async function authenticate(auth, header) {
  const match = /^Bearer\s+(.+)$/i.exec(header ?? '');
  if (!match) throw unauthorized();
  try {
    return await auth.verifyIdToken(match[1], true);
  } catch {
    throw unauthorized('Phiên đăng nhập không hợp lệ hoặc đã hết hạn.');
  }
}

/**
 * Staff authority comes only from an Admin-set custom claim, re-checked against
 * the live user record so a disabled or demoted consultant is denied at once.
 * Client-written Firestore fields never grant this role.
 */
export async function requireConsultant(auth, uid) {
  if (typeof uid !== 'string' || uid.length === 0) throw forbidden();
  let user;
  try {
    user = await auth.getUser(uid);
  } catch {
    throw forbidden();
  }
  if (user.disabled || user.customClaims?.[CONSULTANT_CLAIM] !== true) throw forbidden();
  return { uid: user.uid, displayName: user.displayName || 'Tư vấn viên BeeWise' };
}
