import 'dart:async';
import 'dart:convert';

import 'package:beewise/services/notification_service.dart';
import 'package:beewise/services/auth_service.dart';
import 'package:beewise/services/push_installation_registration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MockMessaging extends Mock implements FirebaseMessaging {}

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirestore extends Mock implements FirebaseFirestore {}

// Firestore's sealed SDK types are mocked only at the SDK I/O boundary.
// ignore: subtype_of_sealed_class
class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockSettings extends Mock implements NotificationSettings {}

class TestMessagingPlatform extends FirebaseMessagingPlatform {
  @override
  void registerBackgroundMessageHandler(BackgroundMessageHandler handler) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockMessaging messaging;
  late MockAuth auth;
  late MockFirestore firestore;
  late User? currentUser;
  late User alice;
  late User bob;
  late StreamController<User?> authEvents;
  late StreamController<String> registered;
  late StreamController<String> unregistered;
  late NotificationService service;
  late Map<String, Map<String, dynamic>> records;
  late Map<String, MockDocument> documents;
  late Map<String, MockCollection> collections;
  late List<String> operations;
  late String fid;
  late bool failDelete;
  late bool failWrite;
  late bool failRegister;
  late bool failUnregister;
  Future<void> Function(String)? beforeWrite;
  Future<void> Function(String)? beforeRead;

  User user(String uid, {bool anonymous = false}) {
    final value = MockUser();
    when(() => value.uid).thenReturn(uid);
    when(() => value.isAnonymous).thenReturn(anonymous);
    return value;
  }

  // All SDK doubles complete immediately unless a race test explicitly holds an
  // operation. Drain stream/microtask work without real clock/network sleeps.
  Future<void> settle() => pumpEventQueue(times: 40);
  late MockDocument Function(String) document;

  MockCollection collection(String path) => collections.putIfAbsent(path, () {
    final value = MockCollection();
    when(
      () => value.doc(any()),
    ).thenAnswer((call) => document('$path/${call.positionalArguments.first}'));
    return value;
  });

  document = (String path) => documents.putIfAbsent(path, () {
    final value = MockDocument();
    when(() => value.collection(any())).thenAnswer(
      (call) => collection('$path/${call.positionalArguments.first}'),
    );
    Future<MockSnapshot> read(Invocation _) async {
      operations.add('get:$path');
      await beforeRead?.call(path);
      final snapshot = MockSnapshot();
      when(() => snapshot.exists).thenReturn(records.containsKey(path));
      when(() => snapshot.data()).thenAnswer((_) => records[path]);
      return snapshot;
    }

    when(() => value.get()).thenAnswer(read);
    when(() => value.get(const GetOptions(source: Source.server)))
        .thenAnswer(read);
    when(() => value.set(any(), any())).thenAnswer((call) async {
      operations.add('set:${currentUser?.uid}:$path');
      expect(
        path.split('/')[1],
        currentUser?.uid,
        reason: 'No cross-UID write',
      );
      final journal = await SharedPreferencesAsync().getString(
        PushInstallationRegistration.journalKey,
      );
      expect(
        (jsonDecode(journal!) as Map)[currentUser!.uid],
        contains(path.split('/').last),
      );
      await beforeWrite?.call(path);
      if (failWrite) throw StateError('offline write');
      records[path] = Map<String, dynamic>.from(
        call.positionalArguments.first as Map,
      );
    });
    when(() => value.delete()).thenAnswer((_) async {
      operations.add('delete:${currentUser?.uid}:$path');
      expect(
        path.split('/')[1],
        currentUser?.uid,
        reason: 'Never delete as another UID',
      );
      if (failDelete) throw StateError('offline delete');
      records.remove(path);
    });
    return value;
  });

  void changeUser(User? next) {
    currentUser = next;
    authEvents.add(next);
  }

  BeeWiseNotification notification(String recipient, String route) =>
      BeeWiseNotification(
        id: 'push',
        title: 'Test',
        body: '',
        route: route,
        recipientUid: recipient,
        receivedAt: DateTime(2026),
      );

  RemoteMessage push(String recipient, String route) => RemoteMessage(
    messageId: 'push',
    data: {'recipientUid': recipient, 'route': route},
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
    FirebaseMessagingPlatform.instance = TestMessagingPlatform();
  });
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    messaging = MockMessaging();
    auth = MockAuth();
    firestore = MockFirestore();
    alice = user('alice');
    bob = user('bob');
    currentUser = alice;
    authEvents = StreamController<User?>.broadcast(sync: true);
    registered = StreamController<String>.broadcast(sync: true);
    unregistered = StreamController<String>.broadcast(sync: true);
    records = {};
    documents = {};
    collections = {};
    operations = [];
    fid = 'install-old';
    failDelete = false;
    failWrite = false;
    failRegister = false;
    failUnregister = false;
    beforeRead = null;
    beforeWrite = null;
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(() => auth.authStateChanges()).thenAnswer((_) => authEvents.stream);
    when(() => firestore.collection(any())).thenAnswer(
      (call) => collection(call.positionalArguments.first as String),
    );
    when(() => messaging.onRegistered).thenAnswer((_) => registered.stream);
    when(() => messaging.onUnregistered).thenAnswer((_) => unregistered.stream);
    when(() => messaging.setAutoInitEnabled(false)).thenAnswer((_) async {
      operations.add('auto:false');
    });
    when(() => messaging.unregister()).thenAnswer((_) async {
      operations.add('unregister');
      if (failUnregister) throw StateError('offline revoke');
      unregistered.add(fid);
    });
    when(() => messaging.register()).thenAnswer((_) async {
      operations.add('register:${currentUser?.uid}');
      if (failRegister) throw StateError('offline register');
      registered.add(fid);
    });
    final settings = MockSettings();
    when(() => settings.authorizationStatus)
        .thenReturn(AuthorizationStatus.authorized);
    when(
      () => messaging.requestPermission(alert: true, badge: true, sound: true),
    ).thenAnswer((_) async => settings);
    when(() => messaging.getInitialMessage()).thenAnswer((_) async => null);
    service = NotificationService(messaging, firestore, auth);
  });
  tearDown(() async {
    await service.dispose();
    await authEvents.close();
    await registered.close();
    await unregistered.close();
  });

  Future<void> start() async {
    await service.initialize();
    await settle();
  }

  test(
    'startup disables auto-init and journals ownership before writing the FID',
    () async {
      await start();
      expect(records.keys, contains('parents/alice/devices/install-old'));
      expect(
        operations.indexOf('auto:false'),
        lessThan(operations.indexOf('register:alice')),
      );
      expect(service.registrationError, isNull);
    },
  );
  test(
    'first login ignores a stale registered callback during role lookup',
    () async {
      currentUser = null;
      await start();
      final roleStarted = Completer<void>();
      final roleGate = Completer<void>();
      beforeRead = (path) async {
        if (path == 'tutorApplications/alice' && !roleStarted.isCompleted) {
          roleStarted.complete();
          await roleGate.future;
        }
      };
      changeUser(alice);
      await roleStarted.future;
      // Native events have no auth generation. This one belongs to a request
      // completed before the current role lookup, not the upcoming register().
      registered.add(fid);
      roleGate.complete();
      await settle();
      expect(records.keys, contains('parents/alice/devices/install-old'));
      expect(service.registrationError, isNull);
    },
  );

  test(
    'role-read error fails closed and explicit retry requires a fresh read',
    () async {
      beforeRead = (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await start();
      expect(operations.where((op) => op.startsWith('register:')), isEmpty);
      expect(records, isEmpty);
      expect(service.registrationError, isNotNull);
      beforeRead = null;
      await service.retryRegistration();
      await settle();
      expect(records.keys, contains('parents/alice/devices/install-old'));
      expect(service.registrationError, isNull);
    },
  );

  test('same-owner session restoration cleans journal then acknowledges a new binding', () async {
    await start();
    await service.dispose();
    operations.clear();
    service = NotificationService(messaging, firestore, auth);
    await start();
    expect(service.registrationError, isNull);
    expect(records.keys, ['parents/alice/devices/install-old']);
    expect(
      operations.indexOf('delete:alice:parents/alice/devices/install-old'),
      lessThan(
        operations.indexOf('set:alice:parents/alice/devices/install-old'),
      ),
    );
  });

  test('missing native acknowledgement becomes retryable instead of pending forever', () async {
    final registration = PushInstallationRegistration(
      messaging,
      firestore,
      auth,
      onChanged: () {},
      acknowledgementTimeout: Duration.zero,
    );
    when(() => messaging.register()).thenAnswer((_) async {});
    await registration.initialize();
    await settle();
    expect(records, isEmpty);
    expect(registration.error, contains('Chưa đồng bộ'));
    registered.add(fid);
    await settle();
    expect(records, isEmpty);
    expect(registration.error, isNotNull);
    when(() => messaging.register())
        .thenAnswer((_) async => registered.add(fid));
    await registration.retry();
    await settle();
    expect(registration.error, isNull);
    expect(records.keys, contains('parents/alice/devices/install-old'));
    await registration.dispose();
  });
  test(
    'managed switch detaches under A before assigning the same FID to B',
    () async {
      await start();
      await service.detachCurrentUser();
      expect(
        records.keys,
        isNot(contains('parents/alice/devices/install-old')),
      );
      changeUser(bob);
      await settle();
      expect(records.keys, contains('parents/bob/devices/install-old'));
      expect(
        operations,
        isNot(contains('delete:bob:parents/alice/devices/install-old')),
      );
    },
  );
  test(
    'unexpected account switch quarantines FID and never deletes another UID',
    () async {
      await start();
      operations.clear();
      changeUser(bob);
      await settle();
      expect(service.registrationError, isNotNull);
      expect(operations, contains('unregister'));
      expect(operations.where((op) => op.startsWith('delete:')), isEmpty);
      expect(records.keys, isNot(contains('parents/bob/devices/install-old')));
      await service.retryRegistration();
      await settle();
      expect(records.keys, isNot(contains('parents/bob/devices/install-old')));
      changeUser(alice);
      await settle();
      expect(service.registrationError, isNull);
      expect(
        operations,
        contains('delete:alice:parents/alice/devices/install-old'),
      );
      await service.detachCurrentUser();
      changeUser(bob);
      await settle();
      expect(records.keys, contains('parents/bob/devices/install-old'));
    },
  );
  test('external sign-out revokes delivery; owner reauthentication recovers cleanup', () async {
    await start();
    operations.clear();
    changeUser(null);
    await settle();
    expect(operations, contains('unregister'));
    expect(operations.where((op) => op.startsWith('delete:')), isEmpty);
    changeUser(alice);
    await settle();
    expect(service.registrationError, isNull);
    await service.detachCurrentUser();
    changeUser(null);
    await settle();
    expect(records.keys.where((p) => p.contains('/devices/')), isEmpty);
  });
  test('rotation removes the prior FID before writing new and ignores late old unregister', () async {
    await start();
    operations.clear();
    fid = 'install-new';
    registered.add(fid);
    unregistered.add('install-old');
    await settle();
    expect(records.keys, isNot(contains('parents/alice/devices/install-old')));
    expect(records.keys, contains('parents/alice/devices/install-new'));
    expect(
      operations.indexOf('delete:alice:parents/alice/devices/install-old'),
      lessThan(
        operations.indexOf('set:alice:parents/alice/devices/install-new'),
      ),
    );
    expect(service.registrationError, isNull);
  });
  test('failed detach preserves recovery journal and propagates until retry succeeds', () async {
    await start();
    failDelete = true;
    await expectLater(service.detachCurrentUser(), throwsStateError);
    expect(service.registrationError, isNotNull);
    expect(
      await SharedPreferencesAsync().getString(
        PushInstallationRegistration.journalKey,
      ),
      contains('install-old'),
    );
    failDelete = false;
    await service.retryRegistration();
    await settle();
    expect(service.registrationError, isNull);
    await service.detachCurrentUser();
    expect(records.keys.where((p) => p.contains('/devices/')), isEmpty);
  });
  test(
    'failed binding is not forgotten and retries cleanup before re-registering',
    () async {
      failWrite = true;
      await start();
      expect(service.registrationError, isNotNull);
      expect(
        await SharedPreferencesAsync().getString(
          PushInstallationRegistration.journalKey,
        ),
        contains('install-old'),
      );
      failWrite = false;
      operations.clear();
      await service.retryRegistration();
      await settle();
      expect(service.registrationError, isNull);
      expect(
        operations.indexOf('delete:alice:parents/alice/devices/install-old'),
        lessThan(
          operations.indexOf('set:alice:parents/alice/devices/install-old'),
        ),
      );
    },
  );
  test('a late write ack after account switch stays quarantined, never transferred', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    beforeWrite = (_) {
      if (!started.isCompleted) started.complete();
      return gate.future;
    };
    await service.initialize();
    await started.future;
    changeUser(bob);
    gate.complete();
    await settle();
    expect(service.registrationError, isNotNull);
    expect(records.keys, isNot(contains('parents/bob/devices/install-old')));
    expect(
      operations,
      isNot(contains('delete:bob:parents/alice/devices/install-old')),
    );
  });
  test('restart retains foreign ownership and blocks unsafe reuse', () async {
    await start();
    await service.dispose();
    currentUser = bob;
    service = NotificationService(messaging, firestore, auth);
    await start();
    expect(service.registrationError, isNotNull);
    expect(records.keys, isNot(contains('parents/bob/devices/install-old')));
  });
  test(
    'registration and revocation failures remain retryable and visible',
    () async {
      failRegister = true;
      await start();
      expect(service.registrationError, isNotNull);
      failRegister = false;
      await service.retryRegistration();
      await settle();
      expect(service.registrationError, isNull);
      failUnregister = true;
      await expectLater(service.detachCurrentUser(), throwsStateError);
      expect(service.registrationError, isNotNull);
      failUnregister = false;
      await service.retryRegistration();
      await settle();
      expect(service.registrationError, isNull);
    },
  );
  test('current unregister cleans its owned record; duplicate/late unregister cannot delete the next ID', () async {
    await start();
    unregistered.add(fid);
    await settle();
    expect(service.registrationError, isNotNull);
    expect(records.keys.where((p) => p.contains('/devices/')), isEmpty);
    fid = 'next';
    await service.retryRegistration();
    await settle();
    unregistered.add('install-old');
    await settle();
    expect(records.keys, contains('parents/alice/devices/next'));
  });
  test('applicant transition removes only own stale registration and never re-registers', () async {
    await start();
    records['tutorApplications/alice'] = {'status': 'pending'};
    await service.refreshAccountRole();
    expect(records.keys.where((p) => p.contains('/devices/')), isEmpty);
    operations.clear();
    await service.retryRegistration();
    await settle();
    expect(operations.where((op) => op.startsWith('register:')), isEmpty);
  });
  test('guest and corrupt cleanup state fail closed without Firestore registration', () async {
    currentUser = user('guest', anonymous: true);
    await start();
    expect(records, isEmpty);
    await service.dispose();
    await SharedPreferencesAsync().setString(
      PushInstallationRegistration.journalKey,
      '{broken',
    );
    currentUser = alice;
    service = NotificationService(messaging, firestore, auth);
    operations.clear();
    await start();
    expect(service.registrationError, isNotNull);
    expect(operations.where((op) => op.startsWith('register:')), isEmpty);
  });

  test(
    'canonical route parser rejects malformed, encoded and unapproved paths',
    () {
      for (final route in [
        '/home',
        '/search',
        '/matching',
        '/profile',
        '/messages',
        '/chats/chat-1',
      ]) {
        expect(parseNotificationRoute(route), route);
      }
      for (final route in <String?>[
        null,
        '',
        '/chats/',
        '/chats/.',
        '/chats/..',
        '/chats/a/b',
        '/chats/a?x=1',
        '/chats/a#x',
        '/chats/%2e%2e',
        '/home/evil',
        '/profile?uid=bob',
        '//evil',
        'https://evil',
        '/chats/a\\b',
        '/chats/a\nb',
        '/payment/invoice',
        '/schedule/class',
        '/register',
        '/chats/a\n',
        '/chats/a\r',
        '/chats/a\u2028',
        '/chats/a ',
      ]) {
        expect(parseNotificationRoute(route), isNull, reason: '$route');
      }
    },
  );
  test('inbox routes require same recipient, parent role and actual chat ownership', () async {
    records['chats/own'] = {'parentId': 'alice'};
    records['chats/other'] = {'parentId': 'bob'};
    expect(
      await service.routeForNotification(notification('alice', '/chats/own')),
      '/chats/own',
    );
    expect(
      await service.routeForNotification(notification('alice', '/chats/other')),
      isNull,
    );
    expect(
      await service.routeForNotification(
        notification('alice', '/chats/missing'),
      ),
      isNull,
    );
    expect(
      await service.routeForNotification(notification('bob', '/home')),
      isNull,
    );
    expect(
      await service.routeForNotification(notification('alice', '/payment/i')),
      isNull,
    );
    records['tutorApplications/alice'] = {'status': 'pending'};
    expect(
      await service.routeForNotification(notification('alice', '/home')),
      isNull,
    );
    currentUser = null;
    expect(
      await service.routeForNotification(notification('alice', '/home')),
      isNull,
    );
  });
  test('saved item from account A cannot be tapped after B signs in', () async {
    await saveReceivedNotification(push('alice', '/home'), 'alice');
    final item = (await service.notifications()).single;
    currentUser = bob;
    expect(await service.routeForNotification(item), isNull);
    expect(await service.notifications(), isEmpty);
  });
  test(
    'missing routes are rejected consistently in saved and opened messages',
    () async {
      final message = RemoteMessage(data: {'recipientUid': 'alice'});
      await saveReceivedNotification(message, 'alice');
      final saved = (await service.notifications()).single;
      expect(await service.routeForNotification(saved), isNull);
      final legacy = BeeWiseNotification.fromJson(
        jsonEncode({'id': 'missing'}),
        ownerUid: 'alice',
      );
      expect(await service.routeForNotification(legacy), isNull);
      final opened = <BeeWiseNotification>[];
      final subscription = service.openedNotifications.listen(opened.add);
      await start();
      FirebaseMessagingPlatform.onMessageOpenedApp.add(message);
      await settle();
      expect(await service.routeForNotification(opened.single), isNull);
      await subscription.cancel();
    },
  );
  test('route authorization rejects auth changes during an awaited chat read and offline errors', () async {
    await start();
    records['chats/own'] = {'parentId': 'alice'};
    final gate = Completer<void>();
    final started = Completer<void>();
    beforeRead = (path) async {
      if (path == 'chats/own') {
        started.complete();
        await gate.future;
      }
    };
    final route = service.routeForNotification(
      notification('alice', '/chats/own'),
    );
    await started.future;
    changeUser(bob);
    changeUser(alice);
    gate.complete();
    expect(await route, isNull);
    beforeRead = (_) async => throw StateError('offline/permission-denied');
    expect(
      await service.routeForNotification(notification('alice', '/home')),
      isNull,
    );
  });
  test('foreground, opened and cold-start notifications use the same guarded resolver', () async {
    records['chats/own'] = {'parentId': 'alice'};
    when(() => messaging.getInitialMessage())
        .thenAnswer((_) async => push('alice', '/chats/own'));
    final routes = <String>[];
    final subscription = service.openedNotifications.listen((item) async {
      final route = await service.routeForNotification(item);
      if (route != null) routes.add(route);
    });
    await start();
    FirebaseMessagingPlatform.onMessage.add(push('alice', '/home'));
    FirebaseMessagingPlatform.onMessage.add(push('bob', '/home'));
    FirebaseMessagingPlatform.onMessageOpenedApp.add(
      push('alice', '/home/evil'),
    );
    FirebaseMessagingPlatform.onMessageOpenedApp.add(push('bob', '/home'));
    FirebaseMessagingPlatform.onMessageOpenedApp.add(push('alice', '/profile'));
    await settle();
    expect(routes, ['/chats/own', '/profile']);
    expect((await service.notifications()).length, 1);
    await subscription.cancel();
  });
  test('late expected unregister of a reused FID never removes the new account mapping', () async {
    await start();
    when(() => messaging.unregister()).thenAnswer((_) async {
      operations.add('unregister'); // Native callback deliberately delayed.
    });
    await service.detachCurrentUser();
    changeUser(bob);
    await settle();
    expect(records.keys, contains('parents/bob/devices/install-old'));
    unregistered.add('install-old');
    unregistered.add('install-old');
    await settle();
    expect(records.keys, contains('parents/bob/devices/install-old'));
    expect(service.registrationError, isNull);
  });
  test('detach before initialization does not leave an unobserved revocation marker', () async {
    await service.detachCurrentUser();
    await service.retryRegistration();
    await settle();
    unregistered.add(fid);
    await settle();
    expect(records.keys.where((path) => path.contains('/devices/')), isEmpty);
    expect(service.registrationError, isNotNull);
  });
  test(
    'stale role lookup completing after auth changes cannot register old UID',
    () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      beforeRead = (path) async {
        if (path == 'tutorApplications/alice') {
          if (!started.isCompleted) started.complete();
          await gate.future;
        }
      };
      final initialization = service.initialize();
      await started.future;
      changeUser(bob);
      registered.add(fid);
      gate.complete();
      await initialization;
      await settle();
      expect(
        records.keys,
        isNot(contains('parents/alice/devices/install-old')),
      );
      expect(records.keys, contains('parents/bob/devices/install-old'));
    },
  );
  test('a newer rotation wins over an older in-flight binding', () async {
    await start();
    final gate = Completer<void>();
    final started = Completer<void>();
    beforeWrite = (path) async {
      if (path.endsWith('/middle')) {
        started.complete();
        await gate.future;
      }
    };
    registered.add('middle');
    await started.future;
    registered.add('newest');
    gate.complete();
    await settle();
    expect(records.keys.where((path) => path.contains('/devices/')), [
      'parents/alice/devices/newest',
    ]);
  });
  test(
    'sign-out keeps the installation journal and UID inbox needed for recovery',
    () async {
      await start();
      await saveReceivedNotification(push('alice', '/home'), 'alice');
      when(() => auth.signOut()).thenAnswer((_) async => changeUser(null));
      await FirebaseAuthService(auth, firestore).signOut();
      expect(
        await SharedPreferencesAsync().getString(
          PushInstallationRegistration.journalKey,
        ),
        contains('alice'),
      );
      expect(
        await SharedPreferencesAsync().getStringList(
          notificationStorageKey('alice'),
        ),
        isNotEmpty,
      );
    },
  );
  test('v2 legacy identity comes only from its key; forged recipients and global legacy are ignored', () async {
    final old = jsonEncode({'id': 'old', 'route': '/profile'});
    final forged = jsonEncode({
      'id': 'forged',
      'route': '/home',
      'recipientUid': 'bob',
    });
    await SharedPreferencesAsync().setStringList(
      'beewise.received_notifications.v1',
      [old],
    );
    expect(await service.notifications(), isEmpty);
    await SharedPreferencesAsync().setStringList(
      notificationStorageKey('alice'),
      [old, forged],
    );
    final item = (await service.notifications()).single;
    expect(item.recipientUid, 'alice');
    expect(await service.routeForNotification(item), '/profile');
    currentUser = bob;
    expect(await service.routeForNotification(item), isNull);
  });
  test(
    'opened-event recipient is rechecked at the final navigation boundary',
    () async {
      final opened = <BeeWiseNotification>[];
      final subscription = service.openedNotifications.listen(opened.add);
      await start();
      FirebaseMessagingPlatform.onMessageOpenedApp.add(push('alice', '/home'));
      await settle();
      expect(opened, hasLength(1));
      changeUser(bob);
      await settle();
      expect(await service.routeForNotification(opened.single), isNull);
      await subscription.cancel();
    },
  );
}
