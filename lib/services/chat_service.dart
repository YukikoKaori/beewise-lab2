import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';
import '../models/chat_preview.dart';

abstract interface class ChatService {
  Future<String> createConnectionRequest({
    required String tutorId,
    required String learningGoal,
    required String area,
    required String schedule,
    String? note,
  });
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Stream<List<ChatPreview>> watchParentChats(String parentId);
  Future<void> sendMessage(String chatId, String body);
}

class FirebaseChatService implements ChatService {
  FirebaseChatService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<String> createConnectionRequest({
    required String tutorId,
    required String learningGoal,
    required String area,
    required String schedule,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const ChatServiceException(
        'Bạn cần đăng nhập để gửi yêu cầu kết nối.',
      );
    }
    final request = _firestore.collection('connectionRequests').doc();
    final chat = _firestore.collection('chats').doc();
    final batch = _firestore.batch();
    batch.set(request, {
      'parentId': user.uid,
      'tutorId': tutorId,
      'chatId': chat.id,
      'learningGoal': learningGoal.trim(),
      'area': area.trim(),
      'schedule': schedule.trim(),
      'note': note?.trim() ?? '',
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chat, {
      'parentId': user.uid,
      'tutorId': tutorId,
      'consultantQueue': true,
      'participantRoles': ['parent', 'tutor', 'consultant'],
      'connectionRequestId': request.id,
      'onboardingStatus': 'connection_pending_consultant',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(chat.collection('messages').doc('request_created'), {
      'senderId': 'system',
      'senderName': 'BeeWise',
      'role': 'system',
      'kind': 'system',
      'body': 'Yêu cầu kết nối đã được gửi. Tư vấn viên BeeWise sẽ tham gia nhóm sau khi xác nhận.',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return chat.id;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                data['createdAt'] = createdAt.toDate();
              }
              return ChatMessage.fromMap(doc.id, data);
            })
            .toList(growable: false),
      );

  @override
  Stream<List<ChatPreview>> watchParentChats(String parentId) => _firestore
      .collection('chats')
      .where('parentId', isEqualTo: parentId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => ChatPreview(
                id: doc.id,
                tutorId: doc.data()['tutorId'] as String? ?? '',
                onboardingStatus:
                    doc.data()['onboardingStatus'] as String? ?? '',
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<void> sendMessage(String chatId, String body) async {
    final user = _auth.currentUser;
    final text = body.trim();
    if (text.isEmpty) throw const ChatServiceException('Tin nhắn đang trống.');
    if (user == null || user.isAnonymous) {
      throw const ChatServiceException('Bạn cần đăng nhập để nhắn tin.');
    }
    await _firestore.collection('chats').doc(chatId).collection('messages').add(
      {
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Phụ huynh',
        'role': 'parent',
        'kind': 'text',
        'body': text,
        'createdAt': FieldValue.serverTimestamp(),
        'delivery': 'sent',
      },
    );
  }
}

class ChatServiceException implements Exception {
  const ChatServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
