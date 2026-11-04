import { FieldValue } from 'firebase-admin/firestore';
import { requireConsultant } from './auth.js';

/**
 * Optional automatic consumer (WORKFLOW_WATCHER=1): processes new parent
 * responses as the chat's assigned consultant (re-verified on every event) and
 * treats a parent "I have paid" request only as a trigger for provider
 * reconciliation. Idempotency lives in the services, so duplicate snapshot
 * events and restarts are safe.
 */
export function startWorkflowWatcher({ db, auth, consultants, payments, logger = console }) {
  const unsubscribeResponses = db.collectionGroup('responses').onSnapshot((snapshot) => {
    for (const change of snapshot.docChanges()) {
      if (change.type !== 'added') continue;
      const chatRef = change.doc.ref.parent.parent;
      (async () => {
        const chat = (await chatRef.get()).data();
        if (!chat?.consultantId) return;
        const consultant = await requireConsultant(auth, chat.consultantId);
        const result = await consultants.processResponse(consultant, chatRef.id, change.doc.id);
        logger.info?.('[watcher] response', chatRef.id, change.doc.id, result.outcome);
      })().catch((error) => logger.warn?.('[watcher] response failed', change.doc.id, error?.code ?? error?.message));
    }
  }, (error) => logger.error?.('[watcher] responses listener stopped', error?.message));

  const unsubscribeRequests = db.collection('paymentVerificationRequests').where('status', '==', 'pending')
    .onSnapshot((snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type !== 'added') continue;
        const request = change.doc.data();
        (async () => {
          let result;
          try {
            result = await payments.reconcileInvoice(request.parentId, request.invoiceId);
          } catch (error) {
            result = { error: error?.code ?? 'failed' };
          }
          await change.doc.ref.update({ status: 'checked', result, checkedAt: FieldValue.serverTimestamp() });
        })().catch((error) => logger.warn?.('[watcher] verification request failed', change.doc.id, error?.message));
      }
    }, (error) => logger.error?.('[watcher] verification listener stopped', error?.message));

  return () => { unsubscribeResponses(); unsubscribeRequests(); };
}
