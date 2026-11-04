import 'dart:async';
import 'dart:convert';

import 'package:beewise/models/tutor.dart';
import 'package:beewise/services/matching_service.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Config extends Mock implements RemoteConfigService {}

class Repository implements TutorRepository {
  List<Tutor> tutors = [tutor('real'), tutor(Tutor.demoTutorId, demo: true)];
  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async => tutors;
  @override
  Future<Tutor> tutorById(String id) async =>
      tutors.firstWhere((t) => t.id == id);
}

Tutor tutor(
  String id, {
  bool fixture = false,
  bool active = true,
  bool demo = false,
}) => Tutor(
  id: id,
  name: 'Technical demo',
  credential: '',
  introduction: '',
  subjects: ['Toán'],
  grades: ['10'],
  hourlyFee: 150000,
  areas: ['TP.HCM'],
  teachingModes: ['in_person'],
  availability: 'Evenings',
  verified: !demo,
  active: active,
  isSyntheticTestFixture: fixture,
  isDemoProfile: demo,
);

void main() {
  late Repository repository;
  late Config config;
  setUp(() {
    repository = Repository();
    config = Config();
    when(() => config.matchingEnabled).thenReturn(true);
    when(() => config.aiResultLimit).thenReturn(3);
    when(() => config.modelName).thenReturn('gemini-3.8-flash');
  });
  MatchingService service(String? output) => MatchingService(
    repository,
    config,
    generate: (_, _, _, _) async => output,
  );
  String result(List<Map<String, Object?>> items) =>
      jsonEncode({'recommendations': items});
  test('valid provider-shaped response binds supplied tutor and preserves demo disclosure', () async {
    final matches = await service(
      result([
        {'tutorId': Tutor.demoTutorId, 'reason': 'Demo phù hợp môn Toán.'},
      ]),
    ).match('Toán 10');
    expect(matches.single.tutor.isDemoProfile, isTrue);
    expect(matches.single.tutor.verified, isFalse);
    expect(matches.single.reason, isNotEmpty);
    // A controlled unit response; genuine Gemini acceptance has separate native evidence.
  });
  test('empty recommendations is a genuine no-result; empty text/malformed shape fails', () async {
    expect(await service(result([])).match('Toán'), isEmpty);
    for (final value in [
      null,
      '',
      'not JSON',
      '[]',
      '{}',
      '{"recommendations":{}}',
    ]) {
      await expectLater(
        service(value).match('Toán'),
        throwsA(isA<MatchingException>()),
      );
    }
  });
  test('unknown, duplicate, synthetic, inactive and empty-explanation results cannot escape', () async {
    repository.tutors.addAll([
      tutor('fixture', fixture: true),
      tutor('inactive', active: false),
    ]);
    final values = [
      {'tutorId': 'unknown', 'reason': 'x'},
      {'tutorId': 'fixture', 'reason': 'x'},
      {'tutorId': 'inactive', 'reason': 'x'},
      {'tutorId': 'real', 'reason': ' '},
      {'tutorId': 'real', 'reason': 'a' * 500},
      {'tutorId': 'real', 'reason': 'duplicate'},
      {'tutorId': Tutor.demoTutorId, 'reason': 'demo'},
    ];
    final matches = await service(result(values)).match('Toán');
    expect(matches.map((m) => m.tutor.id), ['real', Tutor.demoTutorId]);
    expect(matches.first.reason.length, 300);
  });
  test('RC gate and input validation run before any provider call', () async {
    var calls = 0;
    final matching = MatchingService(
      repository,
      config,
      generate: (_, _, _, _) async {
        calls++;
        return result([]);
      },
    );
    for (final value in [' ', 'a' * 501]) {
      await expectLater(
        matching.match(value),
        throwsA(isA<MatchingException>()),
      );
    }
    when(() => config.matchingEnabled).thenReturn(false);
    await expectLater(
      matching.match('Toán'),
      throwsA(isA<MatchingException>()),
    );
    expect(calls, 0);
  });
  test('provider receives bounded permitted candidates, result limit and demo flag', () async {
    repository.tutors.add(tutor('fixture', fixture: true));
    when(() => config.aiResultLimit).thenReturn(1);
    final matching = MatchingService(
      repository,
      config,
      generate: (model, limit, need, candidates) async {
        expect(model, 'gemini-3.8-flash');
        expect(limit, 1);
        expect(need, 'Toán');
        expect(candidates.length, 2);
        expect(candidates.last['demoOnly'], true);
        expect(candidates.last.containsKey('name'), false);
        return result([
          {'tutorId': 'real', 'reason': 'x'},
          {'tutorId': Tutor.demoTutorId, 'reason': 'y'},
        ]);
      },
    );
    expect((await matching.match(' Toán ')).length, 1);
  });
  for (final code in [
    'resource-exhausted',
    'app-check-failed',
    'network-request-failed',
  ]) {
    test(
      '$code remains an error and a subsequent real invocation can retry',
      () async {
        var calls = 0;
        final matching = MatchingService(
          repository,
          config,
          generate: (_, _, _, _) async {
            if (++calls == 1) {
              throw FirebaseException(plugin: 'firebase_ai', code: code);
            }
            return result([
              {'tutorId': 'real', 'reason': 'Phù hợp'},
            ]);
          },
        );
        await expectLater(
          matching.match('Toán'),
          throwsA(isA<FirebaseException>()),
        );
        expect((await matching.match('Toán')).single.tutor.id, 'real');
        expect(calls, 2);
      },
    );
  }
  test(
    'pending provider deadline ends operation without fabricating success',
    () async {
      final pending = Completer<String?>();
      final matching = MatchingService(
        repository,
        config,
        timeout: const Duration(milliseconds: 10),
        generate: (_, _, _, _) => pending.future,
      );
      await expectLater(
        matching.match('Toán'),
        throwsA(isA<TimeoutException>()),
      );
      pending.complete(
        result([
          {'tutorId': 'real', 'reason': 'late'},
        ]),
      );
    },
  );
}
