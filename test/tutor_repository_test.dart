import 'package:beewise/models/tutor.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public tutor catalog excludes synthetic fixtures and keeps real tutors',
    () {
      final tutors = [
        Tutor.fromMap('bao-lab3-synthetic', {
          'name': 'Test tutor',
          'active': true,
        }),
        Tutor.fromMap('real-tutor-1', {'name': 'Real tutor', 'active': true}),
      ];

      final visible = excludeSyntheticTutorFixtures(tutors);

      expect(visible.map((tutor) => tutor.id), ['real-tutor-1']);
      expect(() => visible.add(tutors.first), throwsUnsupportedError);
    },
  );
}
