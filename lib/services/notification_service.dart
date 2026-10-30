import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'push_installation_registration.dart';

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
    'recipientUid': uid,
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
    required this.recipientUid,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final DateTime receivedAt;
  final String? recipientUid;

  factory BeeWiseNotification.fromJson(String raw, {String? ownerUid}) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return BeeWiseNotification(
      recipientUid: data['recipientUid'] as String? ?? ownerUid,
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

/// Accept only canonical routes used by notifications; no encoding, query,
/// fragment, traversal, external URI or empty chat IDs.
String? parseNotificationRoute(String? route) {
  const publicRoutes = [
    '/home',
    '/search',
    '/matching',
    '/profile',
    '/messages',
  ];
  if (publicRoutes.contains(route)) return route;
  if (route != null &&
      RegExp(r'^/chats/[A-Za-z0-9_-]{1,128}$').stringMatch(route) == route) {
    return route;
  }
  return null;
}

class NotificationService {
  NotificationService(this._messaging, this._firestore, this._auth) {
    final messaging = _messaging;
    final firestore = _firestore;
    final auth = _auth;
    _registration = messaging == null || firestore == null || auth == null
        ? null
        : PushInstallationRegistration(
            messaging,
            firestore,
            auth,
            onChanged: _notify,
          );
  }
  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  late final PushInstallationRegistration? _registration;
  final _openedNotifications =
      StreamController<BeeWiseNotification>.broadcast();
  final _updates = StreamController<void>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _initialization;
  RemoteMessage? _initialMessage;
  bool _disposed = false;
  int _authGeneration = 0;
  String? _notificationError;
  Stream<BeeWiseNotification> get openedNotifications =>
      _openedNotifications.stream;
  Stream<void> get updates => _updates.stream;
  String? get registrationError => _registration?.error ?? _notificationError;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final messaging = _messaging;
    if (messaging == null || _disposed) return;
    FirebaseMessaging.onBackgroundMessage(beewiseMessagingBackgroundHandler);
    _authSubscription = _auth?.authStateChanges().listen((_) {
      ++_authGeneration;
      _notify();
      _openInitialMessage();
    });
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      try {
        await saveReceivedNotification(message, _notificationUid);
        _notify();
      } catch (_) {
        _notificationError =
            'Không thể lưu thông báo mới trên thiết bị. Hãy mở lại ứng dụng.';
        _notify();
      }
    });
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openMessage,
    );
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _notificationError = 'Quyền thông báo đang tắt. Bật quyền trong cài đặt Android để nhận tin mới.';
        _notify();
      }
    } catch (_) {
      _notificationError = 'Không thể yêu cầu quyền thông báo. Kiểm tra cài đặt Android rồi thử lại.';
      _notify();
    }
    await _registration?.initialize();
    try {
      _initialMessage = await messaging.getInitialMessage();
      _openInitialMessage();
    } catch (_) {
      _notificationError = 'Không thể đọc thông báo mở ứng dụng. Hãy thử lại.';
      _notify();
    }
  }

  void _openInitialMessage() {
    final message = _initialMessage;
    if (message != null && notificationBelongsTo(message, _notificationUid)) {
      _initialMessage = null;
      _openMessage(message);
    }
  }

  void _openMessage(RemoteMessage message) {
    if (_disposed || !notificationBelongsTo(message, _notificationUid)) return;
    // Carry recipient identity through the asynchronous stream. The consumer
    // resolves/authorizes at navigation time, exactly like an inbox tap.
    _openedNotifications.add(
      BeeWiseNotification(
        id: message.messageId ?? '',
        recipientUid: message.data['recipientUid'] as String?,
        title: message.notification?.title ?? 'BeeWise',
        body: message.notification?.body ?? '',
        route: message.data['route']?.toString() ?? '',
        receivedAt: DateTime.now(),
      ),
    );
  }

  Future<String?> routeForNotification(BeeWiseNotification item) async {
    final route = parseNotificationRoute(item.route);
    final uid = _notificationUid;
    final firestore = _firestore;
    final generation = _authGeneration;
    if (route == null ||
        uid == null ||
        item.recipientUid != uid ||
        firestore == null ||
        _disposed) {
      return null;
    }
    try {
      final application = await firestore
          .collection('tutorApplications')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (application.exists ||
          _notificationUid != uid ||
          generation != _authGeneration) {
        return null;
      }
      if (route.startsWith('/chats/')) {
        final chat = await firestore
            .collection('chats')
            .doc(route.substring('/chats/'.length))
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
        if (!chat.exists || chat.data()?['parentId'] != uid) return null;
      }
      return !_disposed &&
              _notificationUid == uid &&
              generation == _authGeneration
          ? route
          : null;
    } catch (_) {
      // Missing/forbidden/offline resources are not navigation authority.
      return null;
    }
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
            // Older v2 entries derive identity only from their UID-specific key.
            final item = BeeWiseNotification.fromJson(raw, ownerUid: uid);
            return item.recipientUid == uid ? [item] : <BeeWiseNotification>[];
          } catch (_) {
            return <BeeWiseNotification>[];
          }
        })
        .toList(growable: false);
  }

  String? get _notificationUid {
    final user = _auth?.currentUser;
    return user == null ||
            user.isAnonymous ||
            user.uid == _registration?.detachedUid
        ? null
        : user.uid;
  }

  Future<void> detachCurrentUser() => _registration?.detach() ?? Future.value();
  Future<void> refreshAccountRole() =>
      _registration?.refreshRole() ?? Future.value();
  Future<void> retryRegistration() async {
    await initialize();
    await _registration?.retry();
  }

  void _notify() {
    if (!_disposed) _updates.add(null);
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_authGeneration;
    await _authSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    await _registration?.dispose();
    await _openedNotifications.close();
    await _updates.close();
  }
}
