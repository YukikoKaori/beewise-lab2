import { FieldValue } from 'firebase-admin/firestore';
import { conflict, notFound } from './errors.js';
import { docId, tutorApplicationPayload } from './validation.js';

/** True only for a fully approved application (the same triple the Flutter app and Rules use). */
export const isFullyApproved = (application) =>
  application?.status === 'approved' && application.verified === true && application.active === true;

/**
 * Trusted tutor-application workflow. Clients create a `pending` application directly
 * (Rules), but can never update it or publish a catalog profile, so both happen here
 * inside Firestore transactions (the Admin SDK bypasses Rules, so invariants live here).
 *
 * Approval itself stays a manual staff action in the Firebase console; this service only
 * reacts to it (publish) and handles the applicant's resubmission.
 */
export class TutorApplicationService {
  constructor({ db }) {
    this.db = db;
  }

  /** Applicant fixes a `needs_info` application; it goes back to `pending` review. */
  async resubmit(uid, input) {
    docId(uid, 'uid');
    const data = tutorApplicationPayload(input);
    const ref = this.db.collection('tutorApplications').doc(uid);
    return this.db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw notFound('application_not_found', 'Không tìm thấy hồ sơ gia sư.');
      const current = snapshot.data();
      if (current.status === 'rejected') {
        throw conflict('application_rejected', 'Hồ sơ đã bị từ chối nên không thể tự gửi lại.');
      }
      if (current.status !== 'needs_info') {
        throw conflict('invalid_state', 'Chỉ hồ sơ ở trạng thái cần bổ sung mới có thể cập nhật.');
      }
      const previousReason = [current.rejectionReason, current.feedback]
        .find((value) => typeof value === 'string' && value.trim().length > 0);
      tx.update(ref, {
        ...data,
        status: 'pending',
        verified: false,
        active: false,
        consentAccepted: true,
        ...(previousReason ? { previousRejectionReason: previousReason.trim() } : {}),
        rejectionReason: FieldValue.delete(),
        feedback: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
        resubmittedAt: FieldValue.serverTimestamp(),
      });
      return { status: 'pending' };
    });
  }

  /**
   * Publishes (or refreshes) the public `tutors/{uid}` profile of a fully approved
   * application. Idempotent. Never overwrites a catalog document that was not created from
   * this application, and never touches rating/review data of an existing profile.
   */
  async publish(uid) {
    docId(uid, 'uid');
    const appRef = this.db.collection('tutorApplications').doc(uid);
    const tutorRef = this.db.collection('tutors').doc(uid);
    return this.db.runTransaction(async (tx) => {
      const application = (await tx.get(appRef)).data();
      if (!application) throw notFound('application_not_found', 'Không tìm thấy hồ sơ gia sư.');
      if (!isFullyApproved(application)) {
        throw conflict('not_approved', 'Hồ sơ chưa được duyệt, xác minh và kích hoạt đầy đủ.');
      }
      const existing = (await tx.get(tutorRef)).data();
      if (existing && existing.applicationUid !== uid) {
        throw conflict('catalog_conflict', 'Đã có hồ sơ danh mục khác dùng mã này.');
      }
      tx.set(tutorRef, {
        name: application.name,
        credential: application.qualification,
        introduction: application.introduction,
        subjects: application.subjects,
        grades: application.grades,
        hourlyFee: application.hourlyFee,
        areas: application.areas,
        teachingModes: application.teachingModes,
        availability: application.availability,
        verified: true,
        active: true,
        applicationUid: uid,
        updatedAt: FieldValue.serverTimestamp(),
        ...(existing ? {} : { reviewCount: 0, experienceYears: 0, publishedAt: FieldValue.serverTimestamp() }),
      }, { merge: true });
      return { tutorId: uid, created: !existing };
    });
  }

  /** Hides a previously published profile once its application stops being fully approved. */
  async unpublish(uid) {
    docId(uid, 'uid');
    const appRef = this.db.collection('tutorApplications').doc(uid);
    const tutorRef = this.db.collection('tutors').doc(uid);
    return this.db.runTransaction(async (tx) => {
      const application = (await tx.get(appRef)).data();
      if (isFullyApproved(application)) return { tutorId: uid, changed: false };
      const existing = (await tx.get(tutorRef)).data();
      if (!existing || existing.applicationUid !== uid || existing.active !== true) {
        return { tutorId: uid, changed: false };
      }
      tx.update(tutorRef, { active: false, verified: false, updatedAt: FieldValue.serverTimestamp() });
      return { tutorId: uid, changed: true };
    });
  }

  /** Brings the catalog in line with the application's current state. */
  async sync(uid) {
    const application = (await this.db.collection('tutorApplications').doc(uid).get()).data();
    return isFullyApproved(application) ? this.publish(uid) : this.unpublish(uid);
  }
}
