import 'package:cloud_firestore/cloud_firestore.dart';

import 'access.dart';

class BeeWiseFirestore {
  BeeWiseFirestore(this.db);

  final FirebaseFirestore db;

  DocumentReference<Map<String, dynamic>> user(String uid) =>
      db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> application(String uid) =>
      db.collection('tutorApplications').doc(uid);

  CollectionReference<Map<String, dynamic>> get applications =>
      db.collection('tutorApplications');

  CollectionReference<Map<String, dynamic>> get tutors =>
      db.collection('tutors');

  CollectionReference<Map<String, dynamic>> get announcements =>
      db.collection('announcements');

  CollectionReference<Map<String, dynamic>> reviews(String uid) =>
      application(uid).collection('reviews');

  Future<BeeWiseRole> ensureUser(String uid, String displayName) async {
    final ref = user(uid);
    final profile = await ref.get(const GetOptions(source: Source.server));
    if (profile.exists) return BeeWiseRole.fromValue(profile.data()?['role']);
    return db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        return BeeWiseRole.fromValue(existing.data()?['role']);
      }
      transaction.set(ref, {
        'role': BeeWiseRole.user.name,
        'displayName': displayName.length > 100
            ? displayName.substring(0, 100)
            : displayName,
      });
      return BeeWiseRole.user;
    });
  }

  Future<void> review({
    required String applicantUid,
    required String reviewerUid,
    required TutorReviewDecision decision,
    required String reason,
  }) async {
    final note = reason.trim();
    if (note.isEmpty || note.length > 500) {
      throw ArgumentError('Provide a review reason of at most 500 characters.');
    }
    final ref = application(applicantUid);
    final receipt = reviews(applicantUid).doc();
    final approved = decision == TutorReviewDecision.approved;
    await db.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      if (current.data()?['status'] != 'pending') {
        throw StateError('This application is no longer pending.');
      }
      transaction.update(ref, {
        'status': decision.wireValue,
        'active': approved,
        'verified': approved,
        'reviewReason': note,
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'latestReviewId': receipt.id,
      });
      transaction.set(receipt, {
        'status': decision.wireValue,
        'reason': note,
        'reviewerUid': reviewerUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> publishAnnouncement({
    required String uid,
    required String title,
    required String body,
  }) => announcements.add({
    'title': title.trim(),
    'body': body.trim(),
    'status': 'published',
    'createdAt': FieldValue.serverTimestamp(),
    'authorUid': uid,
  });

  Stream<List<InboxNotice>> watchAnnouncements() => announcements
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (event) => [
          for (final doc in event.docs)
            ?InboxNotice.announcement(doc.id, doc.data()),
        ],
      );

  Stream<List<InboxNotice>> watchReviewNotices(String uid) => reviews(uid)
      .orderBy('createdAt', descending: true)
      .limit(25)
      .snapshots()
      .map(
        (event) => [
          for (final doc in event.docs) ?InboxNotice.review(doc.id, doc.data()),
        ],
      );
}

enum InboxNoticeKind { announcement, review }

class InboxNotice {
  const InboxNotice(this.id, this.title, this.body, this.createdAt, this.kind);

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final InboxNoticeKind kind;

  static InboxNotice? announcement(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final body = data['body'];
    final at = data['createdAt'];
    if (data['status'] != 'published' ||
        title is! String ||
        title.trim().isEmpty ||
        body is! String ||
        at is! Timestamp) {
      return null;
    }
    return InboxNotice(
      id,
      title,
      body,
      at.toDate(),
      InboxNoticeKind.announcement,
    );
  }

  static InboxNotice? review(String id, Map<String, dynamic> data) {
    final at = data['createdAt'];
    if (at is! Timestamp) return null;
    final reason = data['reason'];
    final status = data['status'];
    final title = switch (status) {
      'approved' => 'Hồ sơ gia sư đã được duyệt',
      'needs_info' => 'Hồ sơ gia sư cần bổ sung',
      'rejected' => 'Hồ sơ gia sư chưa được duyệt',
      _ => null,
    };
    if (title == null) return null;
    return InboxNotice(
      id,
      title,
      reason is String && reason.trim().isNotEmpty
          ? reason
          : 'Mở hồ sơ gia sư để xem kết quả.',
      at.toDate(),
      InboxNoticeKind.review,
    );
  }
}
