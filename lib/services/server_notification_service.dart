import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart' show BeeWiseNotification;

/// Reads the in-app notification inbox the trusted backend writes to
/// `users/{uid}/notifications` (see backend/src/notification-service.js).
///
/// Clients can only read their own documents (firestore.rules); nothing here can create or
/// change one. The inbox is shown next to the push notifications stored on the device.
class ServerNotificationService {
  ServerNotificationService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Newest first, at most 50. A failure (offline, rules not deployed yet) is shown as an empty
  /// inbox rather than an error, so the device's own notifications keep working, and the
  /// listener is opened again a little later: Firestore ends a listener after a permission error
  /// and would otherwise stay empty even once the cause is fixed.
  Stream<List<BeeWiseNotification>> watch() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return Stream.value(const []);
    final uid = user.uid;
    return resubscribingStream<List<BeeWiseNotification>>(
      () => _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs)
                ?parseServerNotification(uid, doc.id, doc.data()),
            ],
          ),
      whenFailed: const [],
    );
  }
}

/// Re-opens [open] after it fails or ends. While it is failing the listener sees [whenFailed]
/// once per attempt; cancelling the subscription stops the loop.
Stream<T> resubscribingStream<T>(
  Stream<T> Function() open, {
  required T whenFailed,
  Duration retryAfter = const Duration(seconds: 20),
}) async* {
  while (true) {
    try {
      // `await for` (not `yield*`): a stream error must be thrown here to be caught; `yield*`
      // would forward it to the listener instead.
      await for (final value in open()) {
        yield value;
      }
    } catch (_) {
      yield whenFailed;
    }
    await Future<void>.delayed(retryAfter);
  }
}

/// Maps one inbox document, or null when it is not addressed to [uid] or is malformed.
BeeWiseNotification? parseServerNotification(
  String uid,
  String id,
  Map<String, dynamic> data,
) {
  final recipient = data['recipientUid'];
  final title = data['title'];
  final body = data['body'];
  final route = data['route'];
  if (recipient != uid || title is! String || body is! String) return null;
  if (id.isEmpty || title.trim().isEmpty) return null;
  final createdAt = data['createdAt'];
  return BeeWiseNotification(
    id: 'server_$id',
    title: title.trim(),
    body: body.trim(),
    route: route is String ? route : '',
    receivedAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    recipientUid: uid,
  );
}
