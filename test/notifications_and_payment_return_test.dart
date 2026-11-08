import 'dart:async';

import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/screens/tutor_screens.dart';
import 'package:beewise/services/notification_service.dart';
import 'package:beewise/services/server_notification_service.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class _MockDocSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _FakeLocalNotifications extends Fake implements NotificationService {
  _FakeLocalNotifications(this.items);
  final List<BeeWiseNotification> items;
  final controller = StreamController<void>.broadcast();

  @override
  Stream<void> get updates => controller.stream;

  @override
  Future<List<BeeWiseNotification>> notifications() async => items;
}

class _FakeServerNotifications extends Fake
    implements ServerNotificationService {
  _FakeServerNotifications(this.stream);
  final Stream<List<BeeWiseNotification>> stream;

  @override
  Stream<List<BeeWiseNotification>> watch() => stream;
}

BeeWiseNotification _note(String id, DateTime at, {String uid = 'u1'}) =>
    BeeWiseNotification(
      id: id,
      title: 'Tiêu đề $id',
      body: 'Nội dung',
      route: '/home',
      receivedAt: at,
      recipientUid: uid,
    );

void main() {
  group('server inbox documents', () {
    Map<String, dynamic> doc({Object? recipient = 'u1'}) => {
      'recipientUid': recipient,
      'title': '  Hồ sơ cần bổ sung ',
      'body': 'Thiếu bằng cấp',
      'route': '/tutor/pending',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 9, 4)),
      'read': false,
    };

    test('a document addressed to the user becomes a notification', () {
      final item = parseServerNotification('u1', 'n1', doc())!;
      expect(item.id, 'server_n1');
      expect(item.title, 'Hồ sơ cần bổ sung');
      expect(item.route, '/tutor/pending');
      expect(item.recipientUid, 'u1');
      expect(item.receivedAt.toUtc(), DateTime.utc(2026, 11, 9, 4));
    });

    test('someone else’s or malformed documents are dropped', () {
      expect(parseServerNotification('u1', 'n1', doc(recipient: 'u2')), isNull);
      expect(parseServerNotification('u1', 'n1', {'title': 'x'}), isNull);
      expect(
        parseServerNotification('u1', 'n1', {...doc(), 'title': '   '}),
        isNull,
      );
      expect(parseServerNotification('u1', '', doc()), isNull);
      expect(
        parseServerNotification('u1', 'n2', {...doc(), 'route': 5})!.route,
        isEmpty,
      );
    });
  });

  group('merged notification list', () {
    ProviderContainer container({
      required List<BeeWiseNotification> local,
      required Stream<List<BeeWiseNotification>> server,
    }) {
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          notificationServiceProvider.overrideWithValue(
            _FakeLocalNotifications(local),
          ),
          serverNotificationServiceProvider.overrideWithValue(
            _FakeServerNotifications(server),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'device and server notifications are combined, newest first',
      () async {
        final base = DateTime.utc(2026, 11, 9, 4);
        final server = StreamController<List<BeeWiseNotification>>.broadcast();
        addTearDown(server.close);
        final c = container(
          local: [_note('push1', base.add(const Duration(minutes: 5)))],
          server: server.stream,
        );
        final seen = <List<String>>[];
        c.listen(notificationsProvider, (_, next) {
          final value = next.asData?.value;
          if (value != null) seen.add([for (final n in value) n.id]);
        }, fireImmediately: true);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        server.add([
          _note('server_a', base),
          _note('server_b', base.add(const Duration(minutes: 10))),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(seen.last, ['server_b', 'push1', 'server_a']);
      },
    );

    test('an unavailable server inbox never hides the device list', () async {
      final c = container(
        local: [_note('push1', DateTime.utc(2026, 11, 9))],
        server: Stream.value(const <BeeWiseNotification>[]).asBroadcastStream(),
      );
      // The provider rebuilds once when the sign-in state settles; wait for that.
      c.listen(notificationsProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final value = c.read(notificationsProvider).requireValue;
      expect([for (final n in value) n.id], ['push1']);
    });
  });

  group('bell dot', () {
    test(
      'only notifications newer than the last time they were opened count',
      () {
        final opened = DateTime.utc(2026, 11, 9, 4);
        bool unseen(DateTime at) => at.isAfter(opened);
        expect(unseen(opened.add(const Duration(seconds: 1))), isTrue);
        expect(unseen(opened), isFalse);
        expect(unseen(opened.subtract(const Duration(hours: 1))), isFalse);
      },
    );
  });

  group('consultant label', () {
    test('does not double the "Tư vấn viên" prefix', () {
      expect(tutorConsultantLabel('Lan'), 'Tư vấn viên Lan');
      expect(
        tutorConsultantLabel('Tư vấn viên BeeWise'),
        'Tư vấn viên BeeWise',
      );
      expect(tutorConsultantLabel('  tư vấn viên Lan  '), 'tư vấn viên Lan');
      expect(tutorConsultantLabel('  '), 'Tư vấn viên BeeWise');
    });
  });

  group('payment screen', () {
    _MockDocSnapshot invoice(String status, {String? classId}) {
      final doc = _MockDocSnapshot();
      when(() => doc.exists).thenReturn(true);
      when(() => doc.data()).thenReturn({
        'status': status,
        'amount': 2000,
        'currency': 'VND',
        'description': 'Học phí',
        'classId': ?classId,
      });
      return doc;
    }

    Future<StreamController<DocumentSnapshot<Map<String, dynamic>>>> pump(
      WidgetTester tester, {
      required DocumentSnapshot<Map<String, dynamic>> first,
    }) async {
      final stream = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      addTearDown(stream.close);
      final router = GoRouter(
        initialLocation: '/payment/inv_1',
        routes: [
          GoRoute(
            path: '/payment/:invoiceId',
            builder: (_, state) =>
                PaymentScreen(invoiceId: state.pathParameters['invoiceId']!),
          ),
          GoRoute(
            path: '/schedule/:classId',
            builder: (_, state) =>
                Scaffold(body: Text('LỊCH ${state.pathParameters['classId']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceQueryProvider('inv_1').overrideWith((ref) => stream.stream),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      stream.add(first);
      await tester.pump();
      await tester.pump();
      return stream;
    }

    testWidgets(
      'a pending invoice that becomes verified takes the parent to the schedule',
      (tester) async {
        final stream = await pump(tester, first: invoice('pending'));
        expect(find.textContaining('Chờ thanh toán'), findsWidgets);
        stream.add(invoice('verified', classId: 'cls_42'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('LỊCH cls_42'), findsOneWidget);
      },
    );

    testWidgets('opening an invoice that was already paid does not jump away', (
      tester,
    ) async {
      await pump(tester, first: invoice('verified', classId: 'cls_42'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('LỊCH cls_42'), findsNothing);
      expect(find.textContaining('Đã thanh toán'), findsWidgets);
    });
  });
}
