import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serializes installation ownership changes. A foreign pending mapping blocks
/// re-registration: unregister() revokes delivery but does not change the FID.
class PushInstallationRegistration {
  PushInstallationRegistration(
    this._messaging,
    this._firestore,
    this._auth, {
    required this.onChanged,
    this.acknowledgementTimeout = _timeout,
  });

  static const journalKey = 'beewise.push_installations.v1';
  static const _timeout = Duration(seconds: 15);
  // Override only in deterministic deadline tests; production uses 15 seconds.
  final Duration acknowledgementTimeout;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final void Function() onChanged;
  final _preferences = SharedPreferencesAsync();
  final _journal = <String, Set<String>>{};
  final _expectedUnregistrations = <Object, String?>{};
  Future<void> _tail = Future.value();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _registeredSubscription;
  StreamSubscription<String>? _unregisteredSubscription;
  Timer? _acknowledgementTimer;
  bool _loaded = false;
  bool _initialized = false;
  bool _disposed = false;
  int _generation = 0;
  String? _requestedUid;
  String? _installationId;
  String? detachedUid;
  String? error;

  String? get _uid {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  bool _current(String uid, int generation) =>
      !_disposed &&
      generation == _generation &&
      _uid == uid &&
      detachedUid != uid;

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    _registeredSubscription = _messaging.onRegistered.listen((id) {
      final uid = _requestedUid;
      final generation = _generation;
      _trace('registered-callback');
      if (uid == null || !_current(uid, generation)) {
        _schedule(() async {
          // A callback delivered during role lookup must not enqueue a revoke
          // that runs after that lookup has started a newer registration.
          if (generation == _generation && _requestedUid == null) {
            await _stopDelivery();
          } else {
            _trace('stale-callback-ignored');
          }
        });
        return;
      }
      _installationId = id;
      _schedule(() async {
        if (!_current(uid, generation)) return;
        await _bind(uid, id, generation);
      });
    });
    _unregisteredSubscription = _messaging.onUnregistered.listen((id) {
      _trace('unregistered-callback');
      final expected = _expectedUnregistrations.entries
          .where((entry) => entry.value == null || entry.value == id)
          .firstOrNull;
      if (expected != null) {
        _expectedUnregistrations.remove(expected.key);
        return;
      }
      // Expected revocation is already cleaned up by reconcile/detach. A delayed
      // event must never delete the current (possibly different) account's ID.
      if (_requestedUid == null || id != _installationId) return;
      _requestedUid = null;
      _installationId = null;
      _schedule(() async {
        await _load();
        await _cleanOwned(_uid);
        _setError('Đăng ký thông báo đã hết hiệu lực. Hãy thử đăng ký lại.');
      });
    });
    _authSubscription = _auth.authStateChanges().listen((_) {
      final uid = _uid;
      if (detachedUid != uid) detachedUid = null;
      _requestedUid = null;
      final generation = ++_generation;
      _trace('auth-change');
      onChanged();
      _schedule(() => _reconcile(uid, generation));
    });
    final generation = ++_generation;
    try {
      await _enqueue(() => _reconcile(_uid, generation));
    } catch (_) {
      // The user can retry after the visible initialization failure.
    }
  }

  Future<void> retry() async {
    if (_disposed) return;
    detachedUid = null;
    final generation = ++_generation;
    _requestedUid = null;
    try {
      await _enqueue(() => _reconcile(_uid, generation));
    } catch (_) {
      // The error remains visible; retry/auth events can resume the same journal.
    }
  }

  Future<void> detach() async {
    if (_disposed) return;
    final uid = _uid;
    detachedUid = uid;
    ++_generation;
    _requestedUid = null;
    onChanged();
    await _enqueue(() async {
      await _stopDelivery();
      await _load();
      await _cleanOwned(uid);
    });
    // Failure propagates so the managed auth change cannot proceed prematurely.
  }

  Future<void> refreshRole() async {
    final uid = _uid;
    if (uid != null && await _isApplicant(uid)) await detach();
  }

  Future<void> _reconcile(String? uid, int generation) async {
    if (generation != _generation) return;
    await _stopDelivery();
    await _load();
    await _cleanOwned(uid);
    if (generation != _generation) return;
    if (_journal.keys.any((owner) => owner != uid)) {
      throw StateError('Previous installation owner must finish cleanup');
    }
    if (uid == null || detachedUid == uid) {
      _setError(null);
      return;
    }
    if (!_current(uid, generation)) return;
    final applicant = await _isApplicant(uid);
    if (!_current(uid, generation)) return;
    if (applicant) {
      _setError(null);
      return;
    }
    _requestedUid = uid;
    _setError('Đang đồng bộ đăng ký thông báo. Hãy thử lại nếu chưa hoàn tất.');
    _trace('register-start');
    _acknowledgementTimer = Timer(acknowledgementTimeout, () {
      _schedule(() async {
        if (_current(uid, generation) &&
            _requestedUid == uid &&
            error != null) {
          _trace('acknowledgement-timeout');
          throw TimeoutException('Installation acknowledgement not received');
        }
      });
    });
    await _messaging.register().timeout(_timeout);
    _trace('register-sdk-complete');
    // Only onRegistered + an acknowledged Firestore write clears an error.
  }

  Future<void> _bind(String uid, String id, int generation) async {
    _trace('bind-start');
    if (id.isEmpty || id.contains('/')) {
      throw const FormatException('Invalid FID');
    }
    if (!_current(uid, generation) ||
        _requestedUid != uid ||
        _installationId != id) {
      return;
    }
    await _load();
    await _cleanOwned(uid, except: id);
    if (_journal.keys.any((owner) => owner != uid)) {
      throw StateError('Previous installation owner must finish cleanup');
    }
    if (!_current(uid, generation) || _installationId != id) return;
    if (await _isApplicant(uid) ||
        !_current(uid, generation) ||
        _installationId != id) {
      return;
    }
    // Persist before the write: even a timeout/late ack leaves recoverable work.
    (_journal[uid] ??= {}).add(id);
    await _save();
    if (!_current(uid, generation) || _installationId != id) return;
    await _device(uid, id)
        .set({
          'installationId': id,
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(_timeout);
    if (!_current(uid, generation) || _installationId != id) return;
    _acknowledgementTimer?.cancel();
    _trace('firestore-acknowledged');
    _setError(null);
  }

  Future<void> _stopDelivery() async {
    _acknowledgementTimer?.cancel();
    _trace('stop-delivery');
    final previousId = _installationId;
    _requestedUid = null;
    _installationId = null;
    try {
      await _messaging.setAutoInitEnabled(false).timeout(_timeout);
    } finally {
      final operation = Object();
      if (_unregisteredSubscription != null) {
        _expectedUnregistrations[operation] = previousId;
      }
      try {
        await _messaging.unregister().timeout(_timeout);
      } catch (failure) {
        _trace(
          'failed-${failure is FirebaseException ? failure.code : failure.runtimeType}',
        );
        _expectedUnregistrations.remove(operation);
        rethrow;
      }
    }
  }

  Future<void> _cleanOwned(String? uid, {String? except}) async {
    if (uid == null) return;
    for (final id in List.of(_journal[uid] ?? <String>{})) {
      if (id == except) continue;
      // Never send an old UID deletion using a new UID's credentials.
      if (_auth.currentUser?.uid != uid) return;
      await _device(uid, id).delete().timeout(_timeout);
      _journal[uid]!.remove(id);
      if (_journal[uid]!.isEmpty) _journal.remove(uid);
      await _save();
    }
  }

  DocumentReference<Map<String, dynamic>> _device(String uid, String id) =>
      _firestore.collection('parents').doc(uid).collection('devices').doc(id);

  Future<bool> _isApplicant(String uid) async =>
      (await _firestore
              .collection('tutorApplications')
              .doc(uid)
              .get(const GetOptions(source: Source.server))
              .timeout(_timeout))
          .exists;

  Future<void> _load() async {
    if (_loaded) return;
    final raw = await _preferences.getString(journalKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = <String, Set<String>>{};
      for (final entry in decoded.entries) {
        final ids = (entry.value as List).cast<String>().toSet();
        if (entry.key.isEmpty ||
            ids.any((id) => id.isEmpty || id.contains('/'))) {
          throw const FormatException('Invalid installation journal');
        }
        if (ids.isNotEmpty) entries[entry.key] = ids;
      }
      _journal.addAll(entries);
    }
    _loaded = true;
  }

  Future<void> _save() => _preferences.setString(
    journalKey,
    jsonEncode(_journal.map((uid, ids) => MapEntry(uid, ids.toList()))),
  );

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _tail.then((_) async {
      if (_disposed) return;
      try {
        await action();
      } catch (failure) {
        _trace(
          'failed-${failure is FirebaseException ? failure.code : failure.runtimeType}',
        );
        try {
          await _stopDelivery();
        } catch (_) {
          // Keep the journal and visible error when offline revocation fails.
        }
        _setError(
          'Chưa đồng bộ được thiết bị. Hãy thử lại; nếu đã đổi tài khoản, '
          'đăng nhập lại tài khoản trước để hoàn tất gỡ đăng ký thông báo.',
        );
        rethrow;
      }
    });
    _tail = next.catchError((_) {});
    return next;
  }

  void _schedule(Future<void> Function() action) =>
      unawaited(_enqueue(action).catchError((_) {}));

  void _setError(String? value) {
    error = value;
    if (!_disposed) onChanged();
  }

  void _trace(String stage) {
    if (kDebugMode) {
      debugPrint(
        'BeeWisePush $stage generation=$_generation '
        'requested=${_requestedUid != null} installation=${_installationId != null}',
      );
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _acknowledgementTimer?.cancel();
    ++_generation;
    await _authSubscription?.cancel();
    await _registeredSubscription?.cancel();
    await _unregisteredSubscription?.cancel();
    await _tail;
  }
}
