import 'dart:async';

import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/auth_service.dart';
import 'package:beewise/services/crash_reporting_service.dart';
import 'package:beewise/services/notification_service.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockCrash extends Mock implements CrashReportingService {}

class MockNotifications extends Mock implements NotificationService {}

class RecordingAnalytics extends AnalyticsService {
  final calls = <String>[];
  Completer<void>? clearGate;

  @override
  Future<void> setUserId(String? uid) async {
    calls.add(uid == null ? 'clear:null' : 'identify:$uid');
    if (uid == null) await clearGate?.future;
  }

  @override
  Future<void> event(String name, [Map<String, Object>? parameters]) async {
    calls.add('event:$name');
  }
}

void main() {
  test(
    'restored A, guest, B, guest await identity changes before publication',
    () async {
      final auth = MockAuth();
      final crash = MockCrash();
      final analytics = RecordingAnalytics();
      final stream = StreamController<User?>();
      final a = MockUser();
      final b = MockUser();
      when(() => a.uid).thenReturn('test-a');
      when(() => b.uid).thenReturn('test-b');
      when(() => a.isAnonymous).thenReturn(false);
      when(() => b.isAnonymous).thenReturn(false);
      when(auth.authStateChanges).thenAnswer((_) => stream.stream);
      when(() => crash.setUser(any())).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          analyticsServiceProvider.overrideWithValue(analytics),
          crashReportingServiceProvider.overrideWithValue(crash),
        ],
      );
      final published = <String?>[];
      final subscription = container.listen(authStateProvider, (_, value) {
        if (value.hasValue) published.add(value.value?.uid);
      });
      stream.add(a);
      await pumpEventQueue();
      expect(published, ['test-a']);
      analytics.clearGate = Completer<void>();
      stream.add(null);
      stream.add(b);
      await pumpEventQueue();
      expect(published, ['test-a']);
      expect(analytics.calls, ['identify:test-a', 'clear:null']);
      analytics.clearGate!.complete();
      await pumpEventQueue();
      expect(published, ['test-a', null, 'test-b']);
      analytics.clearGate = null;
      stream.add(null);
      await pumpEventQueue();
      expect(published, ['test-a', null, 'test-b', null]);
      expect(analytics.calls, [
        'identify:test-a',
        'clear:null',
        'identify:test-b',
        'clear:null',
      ]);
      subscription.close();
      container.dispose();
      await stream.close();
    },
  );

  test(
    'managed logout awaits setUserId null Future before Auth signout',
    () async {
      final auth = MockAuth();
      final crash = MockCrash();
      final notifications = MockNotifications();
      final analytics = RecordingAnalytics()..clearGate = Completer<void>();
      when(notifications.detachCurrentUser).thenAnswer((_) async {
        analytics.calls.add('detach');
      });
      when(notifications.retryRegistration).thenAnswer((_) async {});
      when(() => crash.setUser(null)).thenAnswer((_) async {});
      when(auth.signOut).thenAnswer((_) async {
        analytics.calls.add('auth:signOut');
      });
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          analyticsServiceProvider.overrideWithValue(analytics),
          crashReportingServiceProvider.overrideWithValue(crash),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
      );
      final logout = container.read(authControllerProvider.notifier).signOut();
      await pumpEventQueue();
      expect(analytics.calls, ['event:logout', 'detach', 'clear:null']);
      verifyNever(auth.signOut);
      analytics.clearGate!.complete();
      await logout;
      expect(analytics.calls.last, 'auth:signOut');
      verify(auth.signOut).called(1);
      container.dispose();
    },
  );
}
