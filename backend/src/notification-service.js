import { FieldValue } from 'firebase-admin/firestore';
import { isFullyApproved } from './tutor-application-service.js';
import { docId } from './validation.js';

const clip = (value, max) => {
  const text = String(value ?? '').replace(/\s+/g, ' ').trim();
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
};

/** Title/body/route for a tutor application in its current review state, or null (no notice). */
export function applicationNotice(application) {
  if (!application) return null;
  const reason = clip(application.rejectionReason || application.feedback, 160);
  if (isFullyApproved(application)) {
    return { key: 'approved', title: 'Hồ sơ gia sư đã được duyệt', body: 'Bạn có thể vào trang gia sư để theo dõi lớp học.', route: '/tutor/home' };
  }
  switch (application.status) {
    case 'approved':
      return { key: 'approved_pending', title: 'Hồ sơ đã duyệt, chờ kích hoạt', body: 'BeeWise đang hoàn tất xác minh và kích hoạt tài khoản của bạn.', route: '/tutor/pending' };
    case 'needs_info':
      return { key: `needs_info:${reason}`, title: 'Hồ sơ cần bổ sung', body: reason || 'Vui lòng cập nhật hồ sơ theo yêu cầu của BeeWise.', route: '/tutor/pending' };
    case 'rejected':
      return { key: `rejected:${reason}`, title: 'Hồ sơ chưa được duyệt', body: reason || 'Hồ sơ của bạn chưa đáp ứng yêu cầu của BeeWise.', route: '/tutor/pending' };
    default:
      return null;
  }
}

/**
 * Who is told what when a chat reaches an onboarding status. Routes are canonical app routes
 * (the app validates ownership again before opening them). Text is short and never contains
 * contact details, amounts or personal data beyond the parent's display name.
 */
export function chatNotices(chat, chatId) {
  const parentName = clip(chat.parentName, 60) || 'Một phụ huynh';
  const parentRoute = `/chats/${chatId}`;
  const tutorRoute = `/tutor/chats/${chatId}`;
  const parent = (title, body) => ({ audience: 'parent', uid: chat.parentId, title, body, route: parentRoute });
  const tutor = (title, body, route = tutorRoute) => ({ audience: 'tutor', uid: chat.tutorId, title, body, route });
  switch (chat.onboardingStatus) {
    case 'connection_pending_consultant':
      return [tutor('Có phụ huynh muốn kết nối', `${parentName} vừa gửi yêu cầu kết nối với bạn.`)];
    case 'consultant_assigned':
      return [
        parent('Tư vấn viên đã tham gia', 'Tư vấn viên BeeWise sẽ hỗ trợ bạn sắp xếp buổi học thử.'),
        tutor('Tư vấn viên đã tham gia nhóm', `Nhóm chat với ${parentName} đã có tư vấn viên hỗ trợ.`),
      ];
    case 'trial_proposed':
      return [
        parent('Có đề xuất buổi học thử', 'Hãy xem và phản hồi trong nhóm chat.'),
        tutor('Đã có đề xuất buổi học thử', `Tư vấn viên vừa đề xuất buổi học thử với ${parentName}.`),
      ];
    case 'trial_accepted':
      return [tutor('Phụ huynh đã đồng ý học thử', `${parentName} đã đồng ý lịch học thử.`)];
    case 'trial_reschedule_requested':
      return [tutor('Phụ huynh đề xuất giờ khác', `${parentName} muốn đổi giờ học thử.`)];
    case 'class_revision_pending':
      return [parent('Có thông tin lớp cần xác nhận', 'Hãy xem thông tin lớp và xác nhận trong nhóm chat.')];
    case 'class_adjustment_requested':
      return [tutor('Phụ huynh yêu cầu điều chỉnh lớp', `${parentName} đã yêu cầu điều chỉnh thông tin lớp.`)];
    case 'invoice_issued':
      return [parent('Hóa đơn học phí đã sẵn sàng', 'Bạn có thể thanh toán để mở lịch học chính thức.')];
    case 'schedule_confirmed':
      return [
        parent('Thanh toán đã được xác minh', 'Lịch học chính thức đã được tạo.'),
        tutor('Lớp mới đã thanh toán', `Lớp của ${parentName} đã sẵn sàng, lịch dạy đã được tạo.`,
          chat.classId ? `/tutor/class/${chat.classId}` : tutorRoute),
      ];
    default:
      return [];
  }
}

/**
 * Server-written in-app inbox: users/{uid}/notifications/{id}. Clients can only read their own
 * (see firestore.rules), so this is the only source of truth for what the app shows in
 * "Thông báo". Idempotent: a marker on the source document (`lastNotifiedStatus`) is updated in
 * the same transaction, so restarts and duplicate snapshot events never repeat a notification,
 * while a genuine new state (e.g. needs_info again) notifies again.
 */
export class NotificationService {
  constructor({ db }) {
    this.db = db;
  }

  #write(tx, uid, id, { type, title, body, route }) {
    tx.set(this.db.collection('users').doc(uid).collection('notifications').doc(id), {
      recipientUid: uid,
      type,
      title,
      body,
      route,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  /** Tells an applicant about a review decision. */
  async notifyApplication(uid) {
    docId(uid, 'uid');
    const ref = this.db.collection('tutorApplications').doc(uid);
    return this.db.runTransaction(async (tx) => {
      const application = (await tx.get(ref)).data();
      if (!application) return { notified: false };
      const notice = applicationNotice(application);
      const marker = (notice?.key ?? `status:${application.status ?? ''}`).slice(0, 300);
      if (application.lastNotifiedStatus === marker) return { notified: false };
      tx.update(ref, { lastNotifiedStatus: marker });
      if (!notice) return { notified: false };
      const slug = notice.key.replace(/[^A-Za-z0-9]/g, '').slice(0, 40) || 'state';
      this.#write(tx, uid, `application_${slug}_${Date.now().toString(36)}`, { type: 'tutor_application', ...notice });
      return { notified: true, key: notice.key };
    });
  }

  /** Tells the parent and/or tutor when a chat reaches a new onboarding status. */
  async notifyChat(chatId) {
    docId(chatId, 'chatId');
    const ref = this.db.collection('chats').doc(chatId);
    return this.db.runTransaction(async (tx) => {
      const chat = (await tx.get(ref)).data();
      if (!chat?.onboardingStatus) return { notified: 0 };
      if (chat.lastNotifiedStatus === chat.onboardingStatus) return { notified: 0 };
      const notices = chatNotices(chat, chatId).filter((n) => typeof n.uid === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(n.uid));
      tx.update(ref, { lastNotifiedStatus: chat.onboardingStatus });
      for (const notice of notices) {
        this.#write(tx, notice.uid, `chat_${chatId}_${chat.onboardingStatus}_${notice.audience}`, { type: 'workflow', ...notice });
      }
      return { notified: notices.length };
    });
  }
}
