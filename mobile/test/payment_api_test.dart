import 'dart:convert';

import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/crash_reporting_service.dart';
import 'package:beewise/services/payment_api.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class RecordingAnalytics extends AnalyticsService {
  final events = <String>[];
  final parameters = <Map<String, Object>?>[];
  @override
  Future<void> event(String name, [Map<String, Object>? values]) async {
    events.add(name);
    parameters.add(values);
  }
}

void main() {
  late MockAuth auth;
  late MockUser user;
  late List<http.Request> requests;

  setUp(() {
    auth = MockAuth();
    user = MockUser();
    requests = [];
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.getIdToken()).thenAnswer((_) async => 'id-token');
  });

  PaymentApi api(
    http.Response Function(http.Request) handler, {
    String base = 'https://api.beewise.test/',
  }) => PaymentApi(
    auth: auth,
    baseUrl: base,
    client: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }),
  );

  http.Response jsonResponse(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test(
    'checkout sends only the invoice id with the Firebase ID token',
    () async {
      final session = await api(
        (_) => jsonResponse(200, {
          'invoiceId': 'inv_1',
          'orderCode': 123456,
          'checkoutUrl': 'https://pay.payos.vn/web/abc',
          'reused': true,
        }),
      ).createCheckout('inv_1');

      expect(session.checkoutUrl.toString(), 'https://pay.payos.vn/web/abc');
      expect(session.orderCode, 123456);
      expect(session.reused, isTrue);
      final request = requests.single;
      expect(
        request.url.toString(),
        'https://api.beewise.test/v1/payments/checkout',
      );
      expect(request.headers['authorization'], 'Bearer id-token');
      expect(jsonDecode(request.body), {'invoiceId': 'inv_1'});
    },
  );

  test('a non-HTTPS checkout link is refused', () async {
    final client = api(
      (_) => jsonResponse(200, {
        'orderCode': 1,
        'checkoutUrl': 'http://evil.test/pay',
      }),
    );
    await expectLater(
      client.createCheckout('inv_1'),
      throwsA(isA<PaymentApiException>()),
    );
  });

  test('server errors surface the server message and code', () async {
    final client = api(
      (_) => jsonResponse(409, {
        'error': {
          'code': 'already_paid',
          'message': 'Hóa đơn đã được thanh toán.',
        },
      }),
    );
    await expectLater(
      client.createCheckout('inv_1'),
      throwsA(
        isA<PaymentApiException>()
            .having((e) => e.code, 'code', 'already_paid')
            .having((e) => e.message, 'message', 'Hóa đơn đã được thanh toán.'),
      ),
    );
  });

  test(
    'non-JSON failures and network errors become friendly messages',
    () async {
      await expectLater(
        api((_) => http.Response('<html>502</html>', 502)).reconcile('inv_1'),
        throwsA(
          isA<PaymentApiException>().having(
            (e) => e.message,
            'message',
            contains('đang gặp sự cố'),
          ),
        ),
      );
      await expectLater(
        api((_) => throw http.ClientException('offline')).reconcile('inv_1'),
        throwsA(
          isA<PaymentApiException>().having((e) => e.code, 'code', 'network'),
        ),
      );
    },
  );

  test('missing configuration or sign-in fails before any request', () async {
    await expectLater(
      api((_) => jsonResponse(200, {}), base: '').createCheckout('inv_1'),
      throwsA(
        isA<PaymentApiException>().having(
          (e) => e.code,
          'code',
          'not_configured',
        ),
      ),
    );
    when(() => user.isAnonymous).thenReturn(true);
    await expectLater(
      api((_) => jsonResponse(200, {})).createCheckout('inv_1'),
      throwsA(
        isA<PaymentApiException>().having(
          (e) => e.code,
          'code',
          'unauthenticated',
        ),
      ),
    );
    expect(requests, isEmpty);
  });

  test('reconcile reports server-verified status only', () async {
    final result = await api(
      (_) =>
          jsonResponse(200, {'invoiceStatus': 'verified', 'classId': 'cls_1'}),
    ).reconcile('inv_1');
    expect(result.verified, isTrue);
    expect(result.classId, 'cls_1');
    expect(requests.single.url.path, '/v1/payments/reconcile');
  });

  group('WorkflowController payOS actions', () {
    late RecordingAnalytics analytics;
    late List<Uri> opened;
    late bool launchResult;

    ProviderContainer container(PaymentApi paymentApi) {
      final value = ProviderContainer(
        overrides: [
          paymentApiProvider.overrideWithValue(paymentApi),
          checkoutLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return launchResult;
          }),
          analyticsServiceProvider.overrideWithValue(analytics),
          crashReportingServiceProvider.overrideWithValue(
            CrashReportingService(),
          ),
        ],
      );
      addTearDown(value.dispose);
      return value;
    }

    setUp(() {
      analytics = RecordingAnalytics();
      opened = [];
      launchResult = true;
    });

    test('opens payOS and logs a PII-free begin_checkout event', () async {
      final c = container(
        api(
          (_) => jsonResponse(200, {
            'orderCode': 99,
            'checkoutUrl': 'https://pay.payos.vn/web/x',
          }),
        ),
      );
      await c
          .read(workflowControllerProvider.notifier)
          .startPayOsCheckout('inv_1');
      expect(c.read(workflowControllerProvider).hasError, isFalse);
      expect(opened.single.host, 'pay.payos.vn');
      expect(analytics.events, ['begin_checkout']);
      expect(analytics.parameters.single, {
        'payment_provider': 'payos',
        'reused_link': 0,
      });
    });

    test('a launcher failure is shown as an error, not as success', () async {
      launchResult = false;
      final c = container(
        api(
          (_) => jsonResponse(200, {
            'orderCode': 99,
            'checkoutUrl': 'https://pay.payos.vn/web/x',
          }),
        ),
      );
      await c
          .read(workflowControllerProvider.notifier)
          .startPayOsCheckout('inv_1');
      final state = c.read(workflowControllerProvider);
      expect(state.hasError, isTrue);
      expect(friendlyError(state.error!), contains('Không mở được'));
    });

    test('refresh asks the server and never marks payment locally', () async {
      final c = container(
        api((_) => jsonResponse(200, {'invoiceStatus': 'pending'})),
      );
      await c
          .read(workflowControllerProvider.notifier)
          .refreshPaymentStatus('inv_1');
      expect(c.read(workflowControllerProvider).hasError, isFalse);
      expect(analytics.parameters.single, {'result': 'pending'});
      expect(opened, isEmpty);
    });
  });
}
