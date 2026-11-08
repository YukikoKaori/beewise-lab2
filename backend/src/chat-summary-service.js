import { Timestamp } from 'firebase-admin/firestore';
import { docId } from './validation.js';

const MAX_TEXT = 120;
const clip = (value, max = MAX_TEXT) => {
  const text = String(value ?? '').replace(/\s+/g, ' ').trim();
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
};

/**
 * Denormalised chat summary fields the tutor workspace (T3/T4) lists without extra reads.
 * Clients create a chat with only its structural fields and can never update it, so the
 * trusted server fills the display fields. Everything here is derived from data the server
 * already trusts (parents/{id}, the connection request, the chat's own messages) and is
 * idempotent: re-running it changes nothing.
 */
export class ChatSummaryService {
  constructor({ db }) {
    this.db = db;
  }

  /** Fills parent name and the request summary once; never overwrites existing values. */
  async enrich(chatId) {
    docId(chatId, 'chatId');
    const chatRef = this.db.collection('chats').doc(chatId);
    return this.db.runTransaction(async (tx) => {
      const chat = (await tx.get(chatRef)).data();
      if (!chat) return { changed: false };
      const missingParent = !chat.parentName;
      const missingRequest = !chat.subjectSummary && !chat.areaSummary;
      if (!missingParent && !missingRequest) return { changed: false };

      const patch = {};
      if (missingParent && typeof chat.parentId === 'string') {
        const parent = (await tx.get(this.db.collection('parents').doc(docId(chat.parentId, 'parentId')))).data();
        if (parent?.displayName) patch.parentName = clip(parent.displayName, 100);
      }
      if (missingRequest && typeof chat.connectionRequestId === 'string') {
        const request = (await tx.get(this.db.collection('connectionRequests').doc(docId(chat.connectionRequestId, 'connectionRequestId')))).data();
        if (request?.learningGoal) patch.subjectSummary = clip(request.learningGoal);
        if (request?.area) patch.areaSummary = clip(request.area);
      }
      if (Object.keys(patch).length === 0) return { changed: false };
      tx.update(chatRef, patch);
      return { changed: true, fields: Object.keys(patch) };
    });
  }

  /**
   * Records the newest message as the chat preview. Only a strictly newer message wins, so
   * replaying history (watcher restart) or duplicate events never rewrites the preview.
   */
  async recordMessage(chatId, message) {
    docId(chatId, 'chatId');
    const createdAt = message?.createdAt;
    if (!(createdAt instanceof Timestamp) || typeof message.body !== 'string' || message.body.trim() === '') {
      return { changed: false };
    }
    const chatRef = this.db.collection('chats').doc(chatId);
    return this.db.runTransaction(async (tx) => {
      const chat = (await tx.get(chatRef)).data();
      if (!chat) return { changed: false };
      const last = chat.lastMessageAt;
      if (last instanceof Timestamp && last.toMillis() >= createdAt.toMillis()) return { changed: false };
      tx.update(chatRef, { lastMessageText: clip(message.body), lastMessageAt: createdAt, lastMessageBy: message.role ?? null });
      return { changed: true };
    });
  }
}
