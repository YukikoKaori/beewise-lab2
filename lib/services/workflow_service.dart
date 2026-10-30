import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkflowService {
  WorkflowService(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchInvoice(
    String invoiceId,
  ) => _firestore.collection('invoices').doc(invoiceId).snapshots();

  Future<void> answerTrial({
    required String chatId,
    required String proposalId,
    required bool accepted,
    String? alternateTime,
  }) async {
    final uid = _requireUser();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('responses')
        .add({
          'parentId': uid,
          'proposalId': proposalId,
          'type': accepted ? 'trial_accepted' : 'trial_alternate_time',
          'alternateTime': alternateTime?.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> requestClassAdjustment({
    required String chatId,
    required String revisionId,
    required String reason,
  }) async {
    final uid = _requireUser();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('responses')
        .add({
          'parentId': uid,
          'proposalId': revisionId,
          'type': 'class_adjustment_requested',
          'reason': reason.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
    // Only the trusted consultant/backend advances chat status after it has
    // accepted and processed the adjustment request.
  }

  Future<void> confirmClassRevision({
    required String chatId,
    required String revisionId,
  }) async {
    final uid = _requireUser();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('responses')
        .add({
          'parentId': uid,
          'proposalId': revisionId,
          'type': 'class_revision_confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
    // Payment is unlocked only when the trusted backend/consultant posts an
    // invoice after observing this response. The client never marks an invoice paid.
  }

  Future<void> requestPaymentVerification(String invoiceId) async {
    final uid = _requireUser();
    await _firestore.collection('paymentVerificationRequests').add({
      'invoiceId': invoiceId,
      'parentId': uid,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSchedule(
    String classId,
  ) => _firestore.collection('classes').doc(classId).snapshots();

  String _requireUser() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const WorkflowException('Bạn cần đăng nhập để tiếp tục bước này.');
    }
    return user.uid;
  }
}

class WorkflowException implements Exception {
  const WorkflowException(this.message);
  final String message;
  @override
  String toString() => message;
}
