import 'package:beewise_core/beewise_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roles fail closed and are separate from tutor authorization', () {
    for (final value in [null, true, 'owner', 'Staff', 'user']) {
      expect(BeeWiseRole.fromValue(value).canReview, isFalse);
    }
    expect(BeeWiseRole.fromValue('staff').canReview, isTrue);
    expect(BeeWiseRole.fromValue('admin').canReview, isTrue);
    for (final status in ['pending', 'needs_info', 'approved']) {
      for (final verified in [false, true]) {
        for (final active in [false, true]) {
          expect(
            isAuthorizedTutor(
              status: status,
              verified: verified,
              active: active,
            ),
            status == 'approved' && verified && active,
          );
        }
      }
    }
  });
}
