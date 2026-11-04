import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { conflict, forbidden, notFound } from './errors.js';
import { classRevisionPayload, docId, trialPayload, ttlHours } from './validation.js';

export const CHAT_STATUS = Object.freeze({
  pendingConsultant: 'connection_pending_consultant',
  consultantAssigned: 'consultant_assigned',
  trialProposed: 'trial_proposed',
  trialAccepted: 'trial_accepted',
  trialReschedule: 'trial_reschedule_requested',
  revisionPending: 'class_revision_pending',
  adjustmentRequested: 'class_adjustment_requested',
  invoiceIssued: 'invoice_issued',
  scheduleConfirmed: 'schedule_confirmed',
});

/** Deterministic IDs make issuance idempotent under retries and races. */
export const invoiceIdFor = (chatId, revisionId) => `inv_${chatId}_${revisionId}`;
export const receiptIdFor = (chatId, proposalId) => `${chatId}__${proposalId}`;

/**
 * Trusted consultant state machine (F-03 part A). Every method re-reads state
 * inside a Firestore transaction because the Admin SDK bypasses Security Rules:
 * the invariants the Rules enforce for clients must be enforced here as well.
 */
export class ConsultantService {
  constructor({ db, now = () => new Date(), invoiceDueDays = 3 }) {
    this.db = db;
    this.now = now;
    this.invoiceDueDays = invoiceDueDays;
  }

  /** Assigns a verified consultant to a reciprocal, valid connection intake. */
  async claimChat(staff, chatId) {
    docId(chatId, 'chatId');
    const chatRef = this.db.collection('chats').doc(chatId);
    return this.db.runTransaction(async (tx) => {
      const chat = await this.#readChat(tx, chatRef);
      if (chat.consultantId) {
        if (chat.consultantId === staff.uid) return { chatId, status: chat.onboardingStatus, alreadyAssigned: true };
        throw conflict('already_assigned', 'Cuộc trò chuyện đã có tư vấn viên khác phụ trách.');
      }
      if (chat.onboardingStatus !== CHAT_STATUS.pendingConsultant || chat.consultantQueue !== true) {
        throw conflict('invalid_state', 'Cuộc trò chuyện không ở trạng thái chờ tư vấn viên.');
      }
      const requestRef = this.db.collection('connectionRequests').doc(docId(chat.connectionRequestId, 'connectionRequestId'));
      const request = (await tx.get(requestRef)).data();
      if (!request || request.parentId !== chat.parentId || request.tutorId !== chat.tutorId || request.chatId !== chatId) {
        throw conflict('invalid_intake', 'Yêu cầu kết nối không khớp với cuộc trò chuyện.');
      }
      const tutor = (await tx.get(this.db.collection('tutors').doc(docId(chat.tutorId, 'tutorId')))).data();
      if (!tutor || tutor.active !== true) {
        throw conflict('tutor_inactive', 'Gia sư không còn hoạt động.');
      }
      tx.update(chatRef, {
        consultantId: staff.uid,
        consultantQueue: false,
        onboardingStatus: CHAT_STATUS.consultantAssigned,
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.set(chatRef.collection('messages').doc(), this.#message(staff, {
        kind: 'text',
        body: `${staff.displayName} đã tham gia nhóm và sẽ hỗ trợ sắp xếp buổi học thử.`,
      }));
      return { chatId, status: CHAT_STATUS.consultantAssigned, alreadyAssigned: false };
    });
  }

  /** Publishes a pending trial proposal and atomically moves the current pointer. */
  async proposeTrial(staff, chatId, input, { ttl } = {}) {
    const payload = trialPayload(input);
    return this.#publishProposal(staff, chatId, {
      kind: 'trial_proposal',
      pointer: 'currentProposalId',
      allowedFrom: [CHAT_STATUS.consultantAssigned, CHAT_STATUS.trialReschedule, CHAT_STATUS.trialProposed],
      nextStatus: CHAT_STATUS.trialProposed,
      body: `Buổi học thử ${payload.subject} vào ${payload.date} lúc ${payload.time}.`,
      payload,
      ttl: ttlHours(ttl),
    });
  }

  /** Publishes a new class revision under a fresh ID (never edits an old one). */
  async proposeClassRevision(staff, chatId, input, { ttl } = {}) {
    const payload = classRevisionPayload(input);
    return this.#publishProposal(staff, chatId, {
      kind: 'class_revision',
      pointer: 'currentRevisionId',
      allowedFrom: [CHAT_STATUS.trialAccepted, CHAT_STATUS.adjustmentRequested, CHAT_STATUS.revisionPending],
      nextStatus: CHAT_STATUS.revisionPending,
      body: `Lớp ${payload.subject}: ${payload.schedule}, bắt đầu ${payload.startDate}.`,
      payload,
      ttl: ttlHours(ttl),
    });
  }

  /**
   * Consumes exactly one immutable parent response. Deduplicated by the full
   * response path; stale, expired or foreign responses are recorded and rejected.
   */
  async processResponse(staff, chatId, proposalId) {
    docId(chatId, 'chatId');
    docId(proposalId, 'proposalId');
    const chatRef = this.db.collection('chats').doc(chatId);
    const responseRef = chatRef.collection('responses').doc(proposalId);
    const proposalRef = chatRef.collection('messages').doc(proposalId);
    const receiptRef = this.db.collection('workflowReceipts').doc(receiptIdFor(chatId, proposalId));
    return this.db.runTransaction(async (tx) => {
      const [receiptSnap, responseSnap, proposalSnap] = await Promise.all([
        tx.get(receiptRef), tx.get(responseRef), tx.get(proposalRef),
      ]);
      const chat = await this.#readChat(tx, chatRef);
      this.#requireAssigned(chat, staff);
      if (receiptSnap.exists) return { ...receiptSnap.data().result, alreadyProcessed: true };
      const response = responseSnap.data();
      const proposal = proposalSnap.data();
      if (!response) throw notFound('response_not_found', 'Chưa có phản hồi cho đề xuất này.');

      const reject = (reason) => {
        const result = { outcome: 'rejected', reason };
        tx.create(receiptRef, { chatId, proposalId, result, processedBy: staff.uid, processedAt: FieldValue.serverTimestamp() });
        return result;
      };
      const trial = String(response.type).startsWith('trial_');
      const expectedKind = trial ? 'trial_proposal' : 'class_revision';
      const pointer = trial ? 'currentProposalId' : 'currentRevisionId';
      const expectedStatus = trial ? CHAT_STATUS.trialProposed : CHAT_STATUS.revisionPending;
      const expiresAt = proposal?.payload?.expiresAt;
      const createdAt = response.createdAt;
      if (response.parentId !== chat.parentId || response.proposalId !== proposalId) return reject('owner_mismatch');
      if (!proposal || proposal.role !== 'consultant' || proposal.kind !== expectedKind) return reject('not_a_proposal');
      if (chat[pointer] !== proposalId || chat.onboardingStatus !== expectedStatus) return reject('stale');
      if (proposal.payload?.status !== 'pending') return reject('not_pending');
      if (!(expiresAt instanceof Timestamp) || !(createdAt instanceof Timestamp) || createdAt.toMillis() > expiresAt.toMillis()) {
        return reject('expired');
      }

      let result;
      const update = (proposalStatus, chatStatus, systemBody, chatExtra = {}) => {
        tx.update(proposalRef, { 'payload.status': proposalStatus, 'payload.respondedAt': createdAt });
        tx.update(chatRef, { ...chatExtra, onboardingStatus: chatStatus, updatedAt: FieldValue.serverTimestamp() });
        tx.set(chatRef.collection('messages').doc(), this.#systemMessage(systemBody));
      };
      switch (response.type) {
        case 'trial_accepted':
          update('accepted', CHAT_STATUS.trialAccepted, 'Phụ huynh đã đồng ý buổi học thử. Tư vấn viên sẽ gửi thông tin lớp chính thức.');
          result = { outcome: 'trial_accepted' };
          break;
        case 'trial_alternate_time':
          update('alternate_requested', CHAT_STATUS.trialReschedule, 'Phụ huynh đề xuất thời gian khác. Tư vấn viên sẽ gửi đề xuất mới.');
          result = { outcome: 'trial_reschedule_requested' };
          break;
        case 'class_adjustment_requested':
          update('adjustment_requested', CHAT_STATUS.adjustmentRequested, 'Phụ huynh yêu cầu điều chỉnh thông tin lớp.');
          result = { outcome: 'class_adjustment_requested' };
          break;
        case 'class_revision_confirmed': {
          const invoiceId = invoiceIdFor(chatId, proposalId);
          const invoiceRef = this.db.collection('invoices').doc(invoiceId);
          const existing = await tx.get(invoiceRef);
          update('confirmed', CHAT_STATUS.invoiceIssued, 'Phụ huynh đã xác nhận thông tin lớp. Hóa đơn học phí đã được tạo.', { currentInvoiceId: invoiceId });
          if (!existing.exists) {
            tx.create(invoiceRef, this.#invoice(chat, chatId, proposalId, proposal.payload));
          }
          tx.set(chatRef.collection('messages').doc(), this.#message(staff, {
            kind: 'payment_request',
            body: `Hóa đơn học phí ${proposal.payload.totalFee.toLocaleString('vi-VN')} đ đã sẵn sàng.`,
            payload: { invoiceId, amount: proposal.payload.totalFee, currency: 'VND' },
          }));
          result = { outcome: 'invoice_issued', invoiceId };
          break;
        }
        default:
          return reject('unknown_type');
      }
      tx.create(receiptRef, { chatId, proposalId, result, processedBy: staff.uid, processedAt: FieldValue.serverTimestamp() });
      return result;
    });
  }

  async #publishProposal(staff, chatId, { kind, pointer, allowedFrom, nextStatus, body, payload, ttl }) {
    docId(chatId, 'chatId');
    const chatRef = this.db.collection('chats').doc(chatId);
    return this.db.runTransaction(async (tx) => {
      const chat = await this.#readChat(tx, chatRef);
      this.#requireAssigned(chat, staff);
      if (!allowedFrom.includes(chat.onboardingStatus)) {
        throw conflict('invalid_state', `Không thể gửi ${kind} khi trạng thái là ${chat.onboardingStatus}.`);
      }
      const previousId = chat[pointer];
      const previousRef = previousId ? chatRef.collection('messages').doc(previousId) : null;
      const previous = previousRef ? (await tx.get(previousRef)).data() : null;
      const messageRef = chatRef.collection('messages').doc();
      const expiresAt = Timestamp.fromMillis(this.now().getTime() + ttl * 3_600_000);
      if (previous?.payload?.status === 'pending') {
        // A replaced proposal can no longer be answered (Rules require the current pointer).
        tx.update(previousRef, { 'payload.status': 'superseded' });
      }
      tx.create(messageRef, this.#message(staff, { kind, body, payload: { ...payload, status: 'pending', expiresAt } }));
      tx.update(chatRef, { [pointer]: messageRef.id, onboardingStatus: nextStatus, updatedAt: FieldValue.serverTimestamp() });
      return { chatId, proposalId: messageRef.id, kind, expiresAt: expiresAt.toDate().toISOString() };
    });
  }

  #invoice(chat, chatId, revisionId, terms) {
    const due = new Date(this.now().getTime() + this.invoiceDueDays * 86_400_000);
    return {
      parentId: chat.parentId,
      tutorId: chat.tutorId,
      chatId,
      revisionId,
      amount: terms.totalFee,
      currency: 'VND',
      description: `Học phí ${terms.subject} · ${terms.schedule}`,
      terms: {
        subject: terms.subject, goal: terms.goal, tutorName: terms.tutorName, schedule: terms.schedule,
        time: terms.time, mode: terms.mode, location: terms.location, startDate: terms.startDate,
        lessonDuration: terms.lessonDuration, fee: terms.fee, totalFee: terms.totalFee,
      },
      status: 'pending',
      dueAt: due.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }),
      dueAtTs: Timestamp.fromDate(due),
      activeOrderCode: null,
      classId: null,
      createdAt: FieldValue.serverTimestamp(),
    };
  }

  async #readChat(tx, chatRef) {
    const chat = (await tx.get(chatRef)).data();
    if (!chat) throw notFound('chat_not_found', 'Không tìm thấy cuộc trò chuyện.');
    return chat;
  }

  #requireAssigned(chat, staff) {
    if (!chat.consultantId) throw conflict('not_assigned', 'Cuộc trò chuyện chưa có tư vấn viên phụ trách.');
    if (chat.consultantId !== staff.uid) throw forbidden('Bạn không phụ trách cuộc trò chuyện này.');
  }

  #message(staff, { kind, body, payload }) {
    return {
      senderId: staff.uid,
      senderName: staff.displayName,
      role: 'consultant',
      kind,
      body,
      ...(payload ? { payload } : {}),
      createdAt: FieldValue.serverTimestamp(),
    };
  }

  #systemMessage(body) {
    return { senderId: 'system', senderName: 'BeeWise', role: 'system', kind: 'system', body, createdAt: FieldValue.serverTimestamp() };
  }
}

