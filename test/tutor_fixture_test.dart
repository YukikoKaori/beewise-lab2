import 'package:beewise/models/tutor.dart';
import 'package:beewise/services/matching_service.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FixtureRepository implements TutorRepository {
  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async => [
    Tutor.fromMap('bao-lab3-fixture', {
      'name': 'Synthetic sample',
      'active': true,
      'verified': true,
    }),
  ];

  @override
  Future<Tutor> tutorById(String id) => throw UnimplementedError();
}

void main() {
  for (final fixture in [
    {'syntheticTestFixture': true},
    {'fixtureNamespace': 'bao-lab3-20261030'},
  ]) {
    test(
      'fixture metadata forces visible test label and removes endorsement: $fixture',
      () {
        final tutor = Tutor.fromMap('sample', {
          ...fixture,
          'name': 'Sample',
          'verified': true,
          'active': true,
        });
        expect(tutor.name, '[TEST] Sample');
        expect(tutor.verified, isFalse);
        expect(tutor.isSyntheticTestFixture, isTrue);
        expect(tutor.active, isTrue); // No cloud record is changed/deactivated.
      },
    );
  }
  test('known fixture ID cannot lose its label by removing metadata', () {
    final tutor = Tutor.fromMap('bao-lab3-20261030-tutor-01', {
      'name': '[TEST] Sample',
      'verified': true,
    });
    expect(tutor.name, '[TEST] Sample');
    expect(tutor.verified, isFalse);
    expect(tutor.isSyntheticTestFixture, isTrue);
  });
  test('genuine profiles keep name and verified status', () {
    final tutor = Tutor.fromMap('genuine', {
      'name': 'Genuine profile',
      'verified': true,
      'syntheticTestFixture': false,
      'fixtureNamespace': '',
    });
    expect(tutor.name, 'Genuine profile');
    expect(tutor.verified, isTrue);
    expect(tutor.isSyntheticTestFixture, isFalse);
  });
  test(
    'fixture-only catalog never enters Firebase AI as real tutor data',
    () async {
      // No Firebase app/model is initialized: reaching the AI SDK would fail.
      final service = MatchingService(
        FixtureRepository(),
        RemoteConfigService(null),
      );
      expect(await service.match('Need a mathematics tutor'), isEmpty);
    },
  );
}
