import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

// Legacy device-global v1 records have no trustworthy owner and are never read.
String notificationStorageKey(String uid) =>
    'beewise.received_notifications.v2.${Uri.encodeComponent(uid)}';

bool notificationBelongsTo(RemoteMessage message, String? uid) =>
    uid != null && message.data['recipientUid'] == uid;

@pragma('vm:entry-point')
Future<void> beewiseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options == null) return;
  await Firebase.initializeApp(options: options);
  final user = FirebaseAuth.instance.currentUser;
  await saveReceivedNotification(
    message,
    user == null || user.isAnonymous ? null : user.uid,
  );
}

Future<void> saveReceivedNotification(
  RemoteMessage message,
  String? uid,
) async {
  if (!notificationBelongsTo(message, uid)) return;
  // Async preferences bypass the per-isolate cache used by background FCM.
  final preferences = SharedPreferencesAsync();
  final key = notificationStorageKey(uid!);
  final items = await preferences.getStringList(key) ?? [];
  if (message.messageId != null &&
      items.any((raw) {
        try {
          return BeeWiseNotification.fromJson(raw).id == message.messageId;
        } catch (_) {
          return false;
        }
      })) {
    return;
  }
  final record = {
    'id': message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
    'title': message.notification?.title ?? 'BeeWise',
    'body': message.notification?.body ?? '',
    'route': message.data['route']?.toString() ?? '/home',
    'receivedAt': DateTime.now().toIso8601String(),
  };
  items.insert(0, jsonEncode(record));
  await preferences.setStringList(key, items.take(100).toList());
}

class BeeWiseNotification {
  const BeeWiseNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.receivedAt,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final DateTime receivedAt;

  factory BeeWiseNotification.fromJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return BeeWiseNotification(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'BeeWise',
      body: data['body'] as String? ?? '',
      route: data['route'] as String? ?? '/home',
      receivedAt:
          DateTime.tryParse(data['receivedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationService {
  NotificationService(this._messaging, this._firestore, this._auth);
  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final _openedRoutes = StreamController<String>.broadcast();
  final _updates = StreamController<void>.broadcast();
  StreamSubscription<String>? _registeredSubscription;
  StreamSubscription<String>? _unregisteredSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  String? _registeredUid;
  String? _currentToken;
  String? _registrationError;
  Stream<String> get openedRoutes => _openedRoutes.stream;
  Stream<void> get updates => _updates.stream;
  String? get registrationError => _registrationError;

  Future<void> initialize() async {
    final messaging = _messaging;
    if (messaging == null) return;
    FirebaseMessaging.onBackgroundMessage(beewiseMessagingBackgroundHandler);
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _recordRegistrationFailure(
          'Quyền thông báo đang tắt. Bật quyền trong cài đặt Android để nhận tin mới.',
        );
      }
    } catch (_) {
      _recordRegistrationFailure(
        'Không thể yêu cầu quyền thông báo. Kiểm tra cài đặt Android rồi thử lại.',
      );
    }
    _registeredSubscription = messaging.onRegistered.listen((installationId) {
      _currentToken = installationId;
      if (_registeredUid != null) {
        unawaited(_storeToken(installationId).catchError(_recordAsyncFailure));
      }
    });
    _unregisteredSubscription = messaging.onUnregistered.listen((
      installationId,
    ) {
      final uid = _registeredUid;
      if (uid != null) {
        unawaited(
          _removeToken(uid, installationId).catchError(_recordAsyncFailure),
        );
      }
      if (_currentToken == installationId) _currentToken = null;
    });
    _authSubscription = _auth?.authStateChanges().listen((user) async {
      _registeredUid = null;
      _updates.add(null);
      try {
        final nextUid = user == null || user.isAnonymous ? null : user.uid;
        final isTutorApplicant =
            nextUid != null && await _hasTutorApplication(nextUid);
        final parentUid = isTutorApplicant ? null : nextUid;
        if (_auth.currentUser?.uid != nextUid) return;
        _registeredUid = parentUid;
        if (parentUid != null) {
          final token = _currentToken;
          if (token != null) await _storeToken(token);
        }
        _clearRegistrationFailure();
      } catch (_) {
        _recordRegistrationFailure(
          'Không thể đồng bộ đăng ký thiết bị với tài khoản. Hãy thử lại sau.',
        );
      }
    });
    try {
      await messaging.register();
    } catch (_) {
      _recordRegistrationFailure(
        'Chưa đăng ký được thông báo đẩy. Kiểm tra mạng rồi thử lại.',
      );
    }
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      try {
        await saveReceivedNotification(message, _notificationUid);
        _updates.add(null);
      } catch (_) {
        _recordRegistrationFailure(
          'Không thể lưu thông báo mới trên thiết bị. Hãy mở lại ứng dụng.',
        );
      }
    });
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      if (notificationBelongsTo(message, _notificationUid)) {
        _openedRoutes.add(_safeRoute(message.data['route']?.toString()));
      }
    });
    final initial = await messaging.getInitialMessage();
    if (initial != null && notificationBelongsTo(initial, _notificationUid)) {
      _openedRoutes.add(_safeRoute(initial.data['route']?.toString()));
    }
  }

  void _recordAsyncFailure(Object error) => _recordRegistrationFailure(
    'Không thể đồng bộ thông báo với tài khoản. Kiểm tra mạng rồi thử lại.',
  );

  void _recordRegistrationFailure(String message) {
    _registrationError = message;
    _updates.add(null);
  }

  void _clearRegistrationFailure() {
    if (_registrationError == null) return;
    _registrationError = null;
    _updates.add(null);
  }

  Future<List<BeeWiseNotification>> notifications() async {
    final uid = _notificationUid;
    if (uid == null) return [];
    final items =
        await SharedPreferencesAsync().getStringList(
          notificationStorageKey(uid),
        ) ??
        [];
    if (_notificationUid != uid) return [];
    return items
        .expand((raw) {
          try {
            return [BeeWiseNotification.fromJson(raw)];
          } catch (_) {
            return <BeeWiseNotification>[];
          }
        })
        .toList(growable: false);
  }

  String? get _notificationUid {
    final user = _auth?.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  static String _safeRoute(String? route) {
    if (route == null || !route.startsWith('/')) return '/home';
    const allowed = ['/home', '/search', '/matching', '/profile', '/chats/'];
    if (allowed.any(
      (item) =>
          route == item ||
          (item == '/chats/' && RegExp(r'^/chats/[^/?#]+$').hasMatch(route)),
    )) {
      return route;
    }
    return '/home';
  }

  Future<void> _storeToken(String installationId) async {
    _currentToken = installationId;
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null ||
        firestore == null ||
        uid != _registeredUid ||
        _auth!.currentUser!.isAnonymous) {
      return;
    }
    if (await _hasTutorApplication(uid)) return;
    if (_auth.currentUser?.uid != uid || _registeredUid != uid) return;
    await firestore
        .collection('parents')
        .doc(uid)
        .collection('devices')
        .doc(installationId)
        .set({
          'installationId': installationId,
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _removeToken(String uid, [String? installationId]) async {
    final id = installationId ?? _currentToken;
    final firestore = _firestore;
    if (id == null || firestore == null) return;
    await firestore
        .collection('parents')
        .doc(uid)
        .collection('devices')
        .doc(id)
        .delete();
  }

  Future<void> detachCurrentUser() async {
    final uid = _auth?.currentUser?.uid;
    if (uid != null && _registeredUid == uid) await _removeToken(uid);
    _registeredUid = null;
  }

  Future<void> refreshAccountRole() async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || !await _hasTutorApplication(uid)) return;
    if (_registeredUid == uid) await _removeToken(uid);
    _registeredUid = null;
  }

  Future<bool> _hasTutorApplication(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return false;
    return (await firestore.collection('tutorApplications').doc(uid).get())
        .exists;
  }

  Future<void> dispose() async {
    await _registeredSubscription?.cancel();
    await _unregisteredSubscription?.cancel();
    await _authSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    await _openedRoutes.close();
    await _updates.close();
  }
}
