import 'dart:convert';

import 'package:beewise/services/tutor_application_api.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirestore extends Mock implements FirebaseFirestore {}

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
    when(() => user.uid).thenReturn('tutor-1');
    when(() => user.getIdToken()).thenAnswer((_) async => 'id-token');
  });

  http.Response jsonResponse(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  TutorApplicationApi api(
    http.Response Function(http.Request) handler, {
    String base = 'https://api.beewise.test/',
  }) => TutorApplicationApi(
    auth: auth,
    baseUrl: base,
    client: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }),
  );

  Future<void> resubmit(TutorApplicationApi client) => client.resubmit(
    name: '  Nguyen Linh Dan ',
    phone: ' 0387871708 ',
    qualification: 'Cử nhân',
    introduction: 'Ba năm kinh nghiệm dạy học cấp hai.',
    subjects: const ['Toán'],
    grades: const ['6'],
    hourlyFee: 180000,
    areas: const ['Quận 7'],
    teachingModes: const ['online'],
    availability: 'Tối thứ 2',
  );

  test('resubmit posts only editable fields with the ID token, never uid/email/status', () async {
    await resubmit(api((_) => jsonResponse(200, {'status': 'pending'})));

    expect(requests, hasLength(1));
    final request = requests.single;
    expect(
      request.url.toString(),
      'https://api.beewise.test/v1/tutor-applications/resubmit',
    );
    expect(request.headers['authorization'], 'Bearer id-token');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['name'], 'Nguyen Linh Dan');
    expect(body['phone'], '0387871708');
    expect(body['hourlyFee'], 180000);
    for (final forbidden in ['uid', 'email', 'status', 'verified', 'active']) {
      expect(body.containsKey(forbidden), isFalse, reason: forbidden);
    }
  });

  test(
    'server messages are surfaced and failures never look successful',
    () async {
      await expectLater(
        resubmit(
          api(
            (_) => jsonResponse(409, {
              'error': {
                'code': 'invalid_state',
                'message':
                    'Chỉ hồ sơ ở trạng thái cần bổ sung mới có thể cập nhật.',
              },
            }),
          ),
        ),
        throwsA(
          isA<TutorApplicationException>().having(
            (e) => e.message,
            'message',
            contains('cần bổ sung'),
          ),
        ),
      );
      await expectLater(
        resubmit(api((_) => http.Response('<html>boom</html>', 502))),
        throwsA(isA<TutorApplicationException>()),
      );
    },
  );

  test(
    'unconfigured base URL and signed-out users fail before any request',
    () async {
      final unconfigured = api((_) => jsonResponse(200, {}), base: '');
      expect(unconfigured.configured, isFalse);
      await expectLater(
        resubmit(unconfigured),
        throwsA(isA<TutorApplicationException>()),
      );

      when(() => auth.currentUser).thenReturn(null);
      await expectLater(
        resubmit(api((_) => jsonResponse(200, {}))),
        throwsA(isA<TutorApplicationException>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'service reports the backend as available only when the API is configured',
    () {
      final firestore = MockFirestore();
      expect(
        TutorApplicationService(auth, firestore).isResubmissionBackendAvailable,
        isFalse,
      );
      expect(
        TutorApplicationService(
          auth,
          firestore,
          api: api((_) => jsonResponse(200, {}), base: ''),
        ).isResubmissionBackendAvailable,
        isFalse,
      );
      expect(
        TutorApplicationService(
          auth,
          firestore,
          api: api((_) => jsonResponse(200, {})),
        ).isResubmissionBackendAvailable,
        isTrue,
      );
    },
  );
}
