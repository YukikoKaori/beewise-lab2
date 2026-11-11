import 'dart:async';

import 'package:beewise/models/tutor_workspace_models.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:beewise/services/tutor_workspace_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockQueryDoc extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class _FakeApplications extends Fake implements TutorApplicationService {
  _FakeApplications(this.data);
  final TutorApplicationData data;

  @override
  Stream<TutorApplicationData?> watchApplicationData(String uid) =>
      Stream.value(data);

  @override
  Future<TutorApplicationData?> getApplicationData(String uid) async => data;
}

void main() {
  // Exactly the shape the trusted backend writes (backend/src/payment-service.js).
  Map<String, dynamic> backendClass() => {
    'parentId': 'parent-1',
    'tutorId': 'tutor-1',
    'chatId': 'chat-1',
    'paymentStatus': 'verified',
    'subject': 'Toán lớp 8',
    'goal': 'Lấy lại căn bản',
    'schedule': 'Thứ 3, Thứ 5',
    'time': '19:00 - 20:30',
    'location': 'Google Meet',
    'totalFee': 1500000,
    'totalAmount': 1500000,
    'hourlyFee': 250000,
    'hoursPerSession': 1.5,
    'totalSessions': 4,
    'parentName': 'Chị Lan',
    'consultantName': 'Tư vấn viên A',
    'sessions': [
      {
        'id': 'cls_1_s1',
        'classId': 'cls_1',
        'tutorId': 'tutor-1',
        'subjectTitle': 'Toán lớp 8',
        'parentName': 'Chị Lan',
        'locationSummary': 'Google Meet',
        'startTime': Timestamp.fromDate(DateTime.utc(2026, 11, 17, 12)),
        'endTime': Timestamp.fromDate(DateTime.utc(2026, 11, 17, 13, 30)),
        'sessionNumber': 1,
        'totalSessions': 4,
        'confirmed': true,
      },
    ],
  };

  test('class record understands the fields the backend really writes', () {
    final record = TutorClassRecord.fromMap('cls_1', backendClass());
    expect(record.title, 'Toán lớp 8');
    expect(record.parentName, 'Chị Lan');
    expect(record.consultantName, 'Tư vấn viên A');
    expect(record.locationSummary, 'Google Meet');
    expect(record.scheduleSummary, 'Thứ 3, Thứ 5 · 19:00 - 20:30');
    expect(record.hourlyFee, 250000);
    expect(record.totalAmount, 1500000);
    expect(record.totalSessions, 4);
    expect(record.isPaymentVerified, isTrue);
    expect(record.sessions, hasLength(1));
    expect(record.sessions.single.tutorId, 'tutor-1');
    expect(record.sessions.single.confirmed, isTrue);
    expect(record.feeBreakdownText, contains('250.000'));
  });

  test(
    'class fields fall back to the older names and never show blanks as data',
    () {
      final legacy = TutorClassRecord.fromMap('cls_2', {
        'tutorId': 'tutor-1',
        'parentId': 'parent-1',
        'paymentStatus': 'pending',
        'area': 'Quận 7',
        'fee': 200000,
        'totalFee': 900000,
      });
      expect(legacy.locationSummary, 'Quận 7');
      expect(legacy.hourlyFee, 200000);
      expect(legacy.totalAmount, 900000);
      expect(legacy.scheduleSummary, 'Chưa cập nhật lịch học');
      expect(legacy.parentName, 'Phụ huynh');
      expect(legacy.isPaymentVerified, isFalse);
    },
  );

  test('every onboarding status the backend produces has a readable label', () {
    const statuses = {
      'connection_pending_consultant': 'Đang chờ tư vấn viên tham gia',
      'consultant_assigned': 'Tư vấn viên đã tham gia nhóm',
      'trial_proposed': 'Chờ phụ huynh xác nhận học thử',
      'trial_accepted': 'Đã xác nhận lịch học thử',
      'trial_reschedule_requested': 'Phụ huynh đề xuất giờ học thử khác',
      'class_revision_pending': 'Chờ phụ huynh xác nhận thông tin lớp',
      'class_adjustment_requested': 'Phụ huynh yêu cầu điều chỉnh lớp',
      'invoice_issued': 'Chờ phụ huynh thanh toán',
      'schedule_confirmed': 'Lớp học đã xác nhận',
    };
    statuses.forEach((status, label) {
      final summary = TutorChatSummary.fromMap('c', {
        'tutorId': 't',
        'onboardingStatus': status,
      });
      expect(summary.onboardingStatusLabel, label, reason: status);
    });
  });

  test(
    'chat summary shows the denormalised parent, consultant and preview',
    () {
      final summary = TutorChatSummary.fromMap('chat-1', {
        'tutorId': 'tutor-1',
        'parentId': 'parent-1',
        'parentName': 'Chị Lan',
        'consultantName': 'Tư vấn viên A',
        'subjectSummary': 'Lấy lại căn bản Toán 8',
        'areaSummary': 'Quận 7',
        'lastMessageText': 'Em chào cô ạ',
        'classId': 'cls_1',
        'onboardingStatus': 'schedule_confirmed',
      });
      expect(summary.parentName, 'Chị Lan');
      expect(summary.parentInitials, isNotEmpty);
      expect(summary.consultantName, 'Tư vấn viên A');
      expect(summary.lastMessageText, 'Em chào cô ạ');
      expect(summary.classId, 'cls_1');
      expect(summary.isNew, isFalse);
    },
  );

  test(
    'T4 chat session converts Firestore Timestamps instead of crashing',
    () async {
      final auth = _MockAuth();
      final user = _MockUser();
      when(() => user.uid).thenReturn('tutor-1');
      when(() => user.isAnonymous).thenReturn(false);
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges())
          .thenAnswer((_) => Stream<User?>.value(user));

      final store = _MockFirestore();
      final chats = _MockCollection();
      final chatDoc = _MockDoc();
      final messages = _MockCollection();
      final messageQuery = _MockQuery();
      when(() => store.collection('chats')).thenReturn(chats);
      when(() => chats.doc('chat-1')).thenReturn(chatDoc);

      final chatSnap = _MockDocSnapshot();
      when(() => chatSnap.exists).thenReturn(true);
      when(() => chatSnap.id).thenReturn('chat-1');
      when(() => chatSnap.data()).thenReturn({
        'tutorId': 'tutor-1',
        'parentId': 'parent-1',
        'parentName': 'Chị Lan',
        'onboardingStatus': 'consultant_assigned',
      });
      when(() => chatDoc.snapshots()).thenAnswer((_) => Stream.value(chatSnap));
      when(() => chatDoc.collection('messages')).thenReturn(messages);
      when(() => messages.orderBy('createdAt')).thenReturn(messageQuery);

      _MockQueryDoc message(String id, Map<String, dynamic> data) {
        final doc = _MockQueryDoc();
        when(() => doc.id).thenReturn(id);
        when(() => doc.data()).thenReturn(data);
        return doc;
      }

      final firstMessage = message('m1', {
        'senderId': 'consultant-1',
        'senderName': 'Tư vấn viên A',
        'role': 'consultant',
        'kind': 'text',
        'body': 'Chào cả nhà, mình sẽ hỗ trợ buổi học thử.',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 9, 3)),
      });
      // A just-written message has no server timestamp yet.
      final pendingMessage = message('m2', {
        'senderId': 'system',
        'role': 'system',
        'kind': 'system',
        'body': 'Đã tạo.',
        'createdAt': null,
      });
      final querySnap = _MockQuerySnapshot();
      when(() => querySnap.docs).thenReturn([firstMessage, pendingMessage]);
      when(() => messageQuery.snapshots())
          .thenAnswer((_) => Stream.value(querySnap));

      final application = TutorApplicationData.fromMap('tutor-1', {
        'name': 'Gia sư',
        'status': 'approved',
        'verified': true,
        'active': true,
      });
      final service = FirebaseTutorWorkspaceService(
        store,
        auth,
        _FakeApplications(application),
      );

      final session = await service
          .watchTutorChatSession('tutor-1', 'chat-1')
          .first
          .timeout(const Duration(seconds: 2));
      expect(session.summary.parentName, 'Chị Lan');
      expect(session.messages, hasLength(2));
      expect(
        session.messages.first.createdAt.toUtc(),
        DateTime.utc(2026, 11, 9, 3),
      );
      expect(session.messages.first.role, 'consultant');
    },
  );
}
