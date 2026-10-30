import 'package:beewise/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAuth auth;
  late MockUser user;
  late NotificationService service;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    auth = MockAuth();
    user = MockUser();
    when(() => user.uid).thenReturn('alice');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => auth.currentUser).thenReturn(user);
    service = NotificationService(null, null, auth);
  });
  tearDown(() => service.dispose());

  RemoteMessage push(String recipient, {String id = 'push'}) => RemoteMessage(
    messageId: id,
    data: {'recipientUid': recipient, 'route': '/chats/chat'},
    notification: const RemoteNotification(title: 'Private message'),
  );

  test(
    'account switching and sign-out never return another UID inbox',
    () async {
      await saveReceivedNotification(push('alice'), 'alice');
      expect((await service.notifications()).single.title, 'Private message');
      when(() => user.uid).thenReturn('bob');
      expect(await service.notifications(), isEmpty);
      await saveReceivedNotification(push('alice', id: 'late'), 'bob');
      expect(await service.notifications(), isEmpty);
      when(() => auth.currentUser).thenReturn(null);
      expect(await service.notifications(), isEmpty);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('alice');
      expect((await service.notifications()).length, 1);
    },
  );
  test('unknown recipients, guests and duplicate delivery are safe', () async {
    await saveReceivedNotification(const RemoteMessage(), 'alice');
    await saveReceivedNotification(push('alice'), null);
    expect(await service.notifications(), isEmpty);
    await saveReceivedNotification(push('alice'), 'alice');
    await saveReceivedNotification(push('alice'), 'alice');
    expect((await service.notifications()).length, 1);
    when(() => user.isAnonymous).thenReturn(true);
    expect(await service.notifications(), isEmpty);
  });
}
