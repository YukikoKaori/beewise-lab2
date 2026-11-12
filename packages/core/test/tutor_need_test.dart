import 'dart:convert';

import 'package:beewise_core/beewise_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F-FINAL-04 canonical location vocabulary & matching', () {
    test(
      'defines unified 16-region canonical vocabulary without duplicates',
      () {
        expect(NormalizedTutorNeed.locations, const [
          'TP.HCM',
          'Thủ Đức',
          'Quận 1',
          'Quận 3',
          'Quận 7',
          'Bình Thạnh',
          'Hà Nội',
          'Cầu Giấy',
          'Đống Đa',
          'Ba Đình',
          'Thanh Xuân',
          'Hai Bà Trưng',
          'Hoàn Kiếm',
          'Nam Từ Liêm',
          'Bắc Từ Liêm',
          'Đà Nẵng',
        ]);
        expect(
          NormalizedTutorNeed.locations.toSet().length,
          NormalizedTutorNeed.locations.length,
        );
      },
    );

    test(
      'normalizes full administrative names, abbreviations, and ASCII aliases',
      () {
        expect(
          NormalizedTutorNeed.normalizeLocation('  Thành phố   Hồ Chí Minh '),
          'TP.HCM',
        );
        expect(NormalizedTutorNeed.normalizeLocation('TP HCM'), 'TP.HCM');
        expect(NormalizedTutorNeed.normalizeLocation('Sài Gòn'), 'TP.HCM');
        expect(NormalizedTutorNeed.normalizeLocation('q. 1'), 'Quận 1');
        expect(NormalizedTutorNeed.normalizeLocation('Q3'), 'Quận 3');
        expect(NormalizedTutorNeed.normalizeLocation('Quận 7'), 'Quận 7');
        expect(
          NormalizedTutorNeed.normalizeLocation('binh thanh'),
          'Bình Thạnh',
        );
        expect(NormalizedTutorNeed.normalizeLocation('TP. Thủ Đức'), 'Thủ Đức');
        expect(NormalizedTutorNeed.normalizeLocation('ha noi'), 'Hà Nội');
        expect(
          NormalizedTutorNeed.normalizeLocation('Quận Cầu Giấy'),
          'Cầu Giấy',
        );
        expect(
          NormalizedTutorNeed.normalizeLocation('hai ba trung'),
          'Hai Bà Trưng',
        );
        expect(NormalizedTutorNeed.normalizeLocation('Da Nang'), 'Đà Nẵng');
        expect(NormalizedTutorNeed.normalizeLocation(''), isNull);
        expect(
          NormalizedTutorNeed.normalizeLocation('Khu vực không hợp lệ'),
          isNull,
        );
      },
    );

    test('normalizeLocationList deduplicates aliases while preserving legacy areas', () {
      final areas = NormalizedTutorNeed.normalizeLocationList([
        'Thành phố Hồ Chí Minh',
        'Sài Gòn',
        'TP.HCM',
        'q1',
        'Quận 10',
        '  Phú   Nhuận  ',
        'Quận Cầu Giấy',
        'cầu giấy',
        '   ',
      ]);
      expect(areas, ['TP.HCM', 'Quận 1', 'Quận 10', 'Phú Nhuận', 'Cầu Giấy']);
    });

    test(
      'parentCityForLocation resolves canonical and legacy districts only',
      () {
        expect(NormalizedTutorNeed.parentCityForLocation('TP.HCM'), isNull);
        expect(NormalizedTutorNeed.parentCityForLocation('Hà Nội'), isNull);
        expect(NormalizedTutorNeed.parentCityForLocation('Đà Nẵng'), isNull);
        expect(NormalizedTutorNeed.parentCityForLocation('Thủ Đức'), 'TP.HCM');
        expect(NormalizedTutorNeed.parentCityForLocation('Quận 1'), 'TP.HCM');
        expect(NormalizedTutorNeed.parentCityForLocation('Cầu Giấy'), 'Hà Nội');
        expect(NormalizedTutorNeed.parentCityForLocation('Quận 10'), 'TP.HCM');
        expect(
          NormalizedTutorNeed.parentCityForLocation('Long Biên'),
          'Hà Nội',
        );
        expect(
          NormalizedTutorNeed.parentCityForLocation('Hải Châu'),
          'Đà Nẵng',
        );
      },
    );

    test(
      'tutorMatchesLocation handles aliases and symmetric hierarchy safely',
      () {
        // Geographical alias match (legacy HCM record vs canonical search/AI)
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const [
            'Thành phố Hồ Chí Minh',
          ], 'TP.HCM'),
          isTrue,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['TP.HCM'], 'Sài Gòn'),
          isTrue,
        );

        // City-level search matches both canonical and legacy districts in that city
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const [
            'Cầu Giấy',
          ], 'Hà Nội'),
          isTrue,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['Tây Hồ'], 'Hà Nội'),
          isTrue,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['Thủ Đức'], 'TP.HCM'),
          isTrue,
        );

        // District-level search matches tutor covering the whole parent city
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const [
            'Hà Nội',
          ], 'Cầu Giấy'),
          isTrue,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['TP.HCM'], 'Quận 1'),
          isTrue,
        );

        // Sibling districts in same city OR different cities do not false-match
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['Quận 1'], 'Quận 3'),
          isFalse,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['Thủ Đức'], 'Hà Nội'),
          isFalse,
        );
        expect(
          NormalizedTutorNeed.tutorMatchesLocation(const ['Đống Đa'], null),
          isTrue,
        );
      },
    );

    test(
      'decode accepts geographical aliases and canonicalizes to vocabulary',
      () {
        final decoded = NormalizedTutorNeed.decode(
          jsonEncode({
            'subject': 'Toán',
            'grade': 9,
            'location': 'Thành phố Hồ Chí Minh',
            'maxHourlyFee': 250000,
            'schedule': 'buổi tối',
            'teachingMode': 'online',
          }),
        );
        expect(decoded.location, 'TP.HCM');

        final districtDecoded = NormalizedTutorNeed.decode(
          jsonEncode({
            'subject': null,
            'grade': null,
            'location': 'Quận Cầu Giấy',
            'maxHourlyFee': null,
            'schedule': null,
            'teachingMode': null,
          }),
        );
        expect(districtDecoded.location, 'Cầu Giấy');

        expect(
          () => NormalizedTutorNeed.decode(
            jsonEncode({
              'subject': null,
              'grade': null,
              'location': 'Atlantis',
              'maxHourlyFee': null,
              'schedule': null,
              'teachingMode': null,
            }),
          ),
          throwsFormatException,
        );
      },
    );
  });
}
