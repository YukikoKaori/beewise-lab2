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
    await _respond(chatId, proposalId, {
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
    await _respond(chatId, revisionId, {
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
    await _respond(chatId, revisionId, {
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

  Future<void> _respond(
    String chatId,
    String proposalId,
    Map<String, Object?> data,
  ) async {
    final uid = _requireUser();
    if (chatId.isEmpty ||
        proposalId.isEmpty ||
        chatId.contains('/') ||
        proposalId.contains('/')) {
      throw const WorkflowException('Đề xuất không hợp lệ.');
    }
    final chatRef = _firestore.collection('chats').doc(chatId);
    await _firestore.runTransaction<void>((transaction) async {
      final chat = (await transaction.get(chatRef)).data();
      final proposal = (await transaction.get(
        chatRef.collection('messages').doc(proposalId),
      )).data();
      final type = data['type'] as String;
      final trial = type.startsWith('trial_');
      final payload = proposal?['payload'];
      final expiresAt = payload is Map ? payload['expiresAt'] : null;
      if (_auth.currentUser?.uid != uid ||
          chat?['parentId'] != uid ||
          chat?[trial ? 'currentProposalId' : 'currentRevisionId'] !=
              proposalId ||
          chat?['onboardingStatus'] !=
              (trial ? 'trial_proposed' : 'class_revision_pending') ||
          proposal?['role'] != 'consultant' ||
          proposal?['kind'] != (trial ? 'trial_proposal' : 'class_revision') ||
          payload is! Map ||
          payload['status'] != 'pending' ||
          expiresAt is! Timestamp ||
          !expiresAt.toDate().isAfter(DateTime.now())) {
        throw const WorkflowException(
          'Đề xuất đã hết hạn hoặc không còn chờ phản hồi. Hãy tải lại cuộc trò chuyện.',
        );
      }
      for (final field in ['alternateTime', 'reason']) {
        if ((type == 'trial_alternate_time' && field == 'alternateTime') ||
            (type == 'class_adjustment_requested' && field == 'reason')) {
          final value = data[field];
          if (value is! String || value.trim().isEmpty || value.length > 500) {
            throw const WorkflowException(
              'Vui lòng nhập nội dung từ 1 đến 500 ký tự.',
            );
          }
        }
      }
      final response = chatRef.collection('responses').doc(proposalId);
      if ((await transaction.get(response)).exists) {
        throw const WorkflowException('Bạn đã phản hồi đề xuất này.');
      }
      transaction.set<Map<String, dynamic>>(response, data);
    });
  }

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
