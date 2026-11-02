import 'package:beewise/models/tutor.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Home excludes fixtures before applying Remote Config display limit',
    () async {
      final repository = _Catalog();
      final container = ProviderContainer(
        overrides: [
          tutorRepositoryProvider.overrideWithValue(repository),
          remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
        ],
      );
      addTearDown(container.dispose);
      final tutors = await container.read(activeTutorsProvider.future);
      expect(repository.requestedLimit, 100);
      expect(tutors.length, 6);
      expect(tutors.first.id, Tutor.demoTutorId);
      expect(tutors.every((tutor) => !tutor.isSyntheticTestFixture), isTrue);
    },
  );
  const payload = {'active': true, 'verified': false, 'demoOnly': true};
  test(
    'only the consented demo is report eligible without professional badge',
    () {
      final tutor = Tutor.fromMap(Tutor.demoTutorId, payload);
      expect(tutor.isDemoProfile, isTrue);
      expect(tutor.verified, isFalse);
      expect(tutor.reportEligible, isTrue);
      expect(Tutor.demoDisclosure, 'Hồ sơ demo — đã duyệt cho kiểm thử');
      expect(Tutor.fromMap('another-id', payload).reportEligible, isFalse);
    },
  );
  test(
    'demo approval never overrides synthetic, inactive or malformed flags',
    () {
      for (final patch in [
        {'syntheticTestFixture': true},
        {'fixtureNamespace': 'fixture'},
        {'active': false},
        {'verified': true},
        {'demoOnly': 'true'},
        {'demoOnly': null},
      ]) {
        final tutor = Tutor.fromMap(Tutor.demoTutorId, {...payload, ...patch});
        expect(tutor.reportEligible, isFalse, reason: '$patch');
        expect(tutor.verified, isFalse);
      }
    },
  );
  test(
    'ordinary verified and unverified profiles retain existing eligibility',
    () {
      expect(
        Tutor.fromMap('ordinary', {
          'active': true,
          'verified': true,
        }).reportEligible,
        isTrue,
      );
      expect(
        Tutor.fromMap('ordinary', {
          'active': true,
          'verified': false,
        }).reportEligible,
        isFalse,
      );
      expect(
        Tutor.fromMap('bao-lab3-fixture', payload).reportEligible,
        isFalse,
      );
    },
  );
}

class _Catalog implements TutorRepository {
  int? requestedLimit;
  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async {
    requestedLimit = limit;
    return [
      for (var i = 0; i < 6; i++)
        Tutor.fromMap('bao-lab3-$i', {'active': true}),
      Tutor.fromMap(Tutor.demoTutorId, {
        'active': true,
        'verified': false,
        'demoOnly': true,
      }),
      for (var i = 0; i < 8; i++)
        Tutor.fromMap('ordinary-$i', {'active': true}),
    ].take(limit).toList();
  }

  @override
  Future<Tutor> tutorById(String id) => throw UnimplementedError();
}
