import 'dart:async';
import 'dart:convert';

import 'package:beewise/screens/confirm_tutor_need_screen.dart';
import 'package:beewise/services/need_normalizer.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise_core/beewise_core.dart';
import 'package:flutter_test/flutter_test.dart';

const response = {
  'subject': 'Toán',
  'grade': 9,
  'location': 'Thủ Đức',
  'maxHourlyFee': 200000,
  'schedule': 'buổi tối',
  'teachingMode': null,
};

void main() {
  test(
    'provider receives learning hints without identities or unrelated numbers',
    () async {
      var count = 0;
      final parser = NeedNormalizer(
        RemoteConfigService(null),
        generate: (model, prompt, text) async {
          count++;
          expect(model, isNotEmpty);
          expect(prompt, isNotEmpty);
          expect(text, contains('Toán'));
          expect(text, contains('lớp 9'));
          expect(text, contains('200000 VND'));
          for (final secret in [
            '0999999999',
            'example.test',
            'Nguyễn',
            'https://',
            '999999999',
          ]) {
            expect(text, isNot(contains(secret)));
          }
          return jsonEncode(response);
        },
      );
      final parsed = await parser.parse(
        'Nguyễn A 0999999999 admin@example.test https://example.test/Toán 999999999 '
        'cần Toán lớp 9 ở Thủ Đức, học phí dưới 200k, buổi tối',
      );
      expect(parsed.grade, 9);
      expect(parsed.teachingMode, isNull);
      expect(count, 1);
    },
  );

  test(
    'rejects malformed, invented, wrongly typed and out-of-range values',
    () {
      for (final input in [
        '{}',
        'not JSON',
        jsonEncode({...response, 'grade': '9'}),
        jsonEncode({...response, 'grade': 13}),
        jsonEncode({...response, 'maxHourlyFee': 0}),
        jsonEncode({...response, 'subject': 'unrecognised subject'}),
        jsonEncode({...response, 'extra': true}),
      ]) {
        expect(() => NormalizedTutorNeed.decode(input), throwsFormatException);
      }
    },
  );

  test(
    'timeout and disabled config never retry or call another model',
    () async {
      var count = 0;
      final parser = NeedNormalizer(
        RemoteConfigService(null),
        timeout: Duration.zero,
        generate: (model, prompt, text) {
          count++;
          return Completer<String?>().future;
        },
      );
      await expectLater(
        parser.parse('Toán lớp 9'),
        throwsA(isA<TimeoutException>()),
      );
      expect(count, 1);
      final disabled = NeedNormalizer(
        _DisabledConfig(),
        generate: (model, prompt, text) async =>
            throw StateError('Unexpected inference'),
      );
      await expectLater(disabled.parse('Toán lớp 9'), throwsException);
    },
  );

  test(
    'matching uses confirmed fields and excludes inactive or synthetic tutors',
    () {
      Tutor tutor(String id, {bool synthetic = false, bool active = true}) =>
          Tutor(
            id: id,
            name: 'Example',
            credential: 'Degree',
            introduction: 'Example description',
            subjects: const ['Toán'],
            grades: const ['Lớp 9'],
            hourlyFee: 180000,
            areas: const ['Thủ Đức'],
            teachingModes: const ['online'],
            availability: 'Học tối',
            verified: true,
            active: active,
            isSyntheticTestFixture: synthetic,
          );
      final candidates = [
        tutor('a'),
        tutor('b', synthetic: true),
        tutor('c', active: false),
      ];
      expect(
        matchConfirmedNeed(
          candidates,
          NormalizedTutorNeed.decode(jsonEncode(response)),
        ).map((t) => t.id),
        ['a'],
      );
      expect(
        matchConfirmedNeed(candidates, const NormalizedTutorNeed(grade: 10)),
        isEmpty,
      );
    },
  );
}

class _DisabledConfig extends RemoteConfigService {
  _DisabledConfig() : super(null);
  @override
  bool get matchingEnabled => false;
}
