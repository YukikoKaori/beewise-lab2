import 'dart:convert';

class NormalizedTutorNeed {
  const NormalizedTutorNeed({
    this.subject,
    this.grade,
    this.location,
    this.maxHourlyFee,
    this.schedule,
    this.teachingMode,
  });
  final String? subject, location, schedule, teachingMode;
  final int? grade, maxHourlyFee;

  static const subjects = [
    'Toán',
    'Tiếng Anh',
    'Ngữ văn',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Tin học',
  ];
  static const locations = [
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
  ];

  /// Maps geographical abbreviations, administrative prefixes, and ASCII or
  /// accented variants to a canonical entry in [locations].
  static const Map<String, String> locationAliases = {
    'thành phố hồ chí minh': 'TP.HCM',
    'tp hồ chí minh': 'TP.HCM',
    'tp. hồ chí minh': 'TP.HCM',
    'hồ chí minh': 'TP.HCM',
    'ho chi minh city': 'TP.HCM',
    'ho chi minh': 'TP.HCM',
    'tp.hcm': 'TP.HCM',
    'tp. hcm': 'TP.HCM',
    'tp hcm': 'TP.HCM',
    'tphcm': 'TP.HCM',
    'hcm': 'TP.HCM',
    'sài gòn': 'TP.HCM',
    'sai gon': 'TP.HCM',
    'thành phố thủ đức': 'Thủ Đức',
    'tp thủ đức': 'Thủ Đức',
    'tp. thủ đức': 'Thủ Đức',
    'quận thủ đức': 'Thủ Đức',
    'thủ đức': 'Thủ Đức',
    'thu duc': 'Thủ Đức',
    'quận 1': 'Quận 1',
    'quan 1': 'Quận 1',
    'q. 1': 'Quận 1',
    'q.1': 'Quận 1',
    'q1': 'Quận 1',
    'quận 3': 'Quận 3',
    'quan 3': 'Quận 3',
    'q. 3': 'Quận 3',
    'q.3': 'Quận 3',
    'q3': 'Quận 3',
    'quận 7': 'Quận 7',
    'quan 7': 'Quận 7',
    'q. 7': 'Quận 7',
    'q.7': 'Quận 7',
    'q7': 'Quận 7',
    'quận bình thạnh': 'Bình Thạnh',
    'q. bình thạnh': 'Bình Thạnh',
    'bình thạnh': 'Bình Thạnh',
    'binh thanh': 'Bình Thạnh',
    'thành phố hà nội': 'Hà Nội',
    'tp hà nội': 'Hà Nội',
    'tp. hà nội': 'Hà Nội',
    'hà nội': 'Hà Nội',
    'ha noi': 'Hà Nội',
    'hanoi': 'Hà Nội',
    'quận cầu giấy': 'Cầu Giấy',
    'q. cầu giấy': 'Cầu Giấy',
    'cầu giấy': 'Cầu Giấy',
    'cau giay': 'Cầu Giấy',
    'quận đống đa': 'Đống Đa',
    'q. đống đa': 'Đống Đa',
    'đống đa': 'Đống Đa',
    'dong da': 'Đống Đa',
    'quận ba đình': 'Ba Đình',
    'q. ba đình': 'Ba Đình',
    'ba đình': 'Ba Đình',
    'ba dinh': 'Ba Đình',
    'quận thanh xuân': 'Thanh Xuân',
    'q. thanh xuân': 'Thanh Xuân',
    'thanh xuân': 'Thanh Xuân',
    'thanh xuan': 'Thanh Xuân',
    'quận hai bà trưng': 'Hai Bà Trưng',
    'q. hai bà trưng': 'Hai Bà Trưng',
    'hai bà trưng': 'Hai Bà Trưng',
    'hai ba trung': 'Hai Bà Trưng',
    'quận hoàn kiếm': 'Hoàn Kiếm',
    'q. hoàn kiếm': 'Hoàn Kiếm',
    'hoàn kiếm': 'Hoàn Kiếm',
    'hoan kiem': 'Hoàn Kiếm',
    'quận nam từ liêm': 'Nam Từ Liêm',
    'q. nam từ liêm': 'Nam Từ Liêm',
    'nam từ liêm': 'Nam Từ Liêm',
    'nam tu liem': 'Nam Từ Liêm',
    'quận bắc từ liêm': 'Bắc Từ Liêm',
    'q. bắc từ liêm': 'Bắc Từ Liêm',
    'bắc từ liêm': 'Bắc Từ Liêm',
    'bac tu liem': 'Bắc Từ Liêm',
    'thành phố đà nẵng': 'Đà Nẵng',
    'tp đà nẵng': 'Đà Nẵng',
    'tp. đà nẵng': 'Đà Nẵng',
    'đà nẵng': 'Đà Nẵng',
    'da nang': 'Đà Nẵng',
    'danang': 'Đà Nẵng',
  };

  static const Map<String, String> _districtParentCities = {
    'Thủ Đức': 'TP.HCM',
    'Quận 1': 'TP.HCM',
    'Quận 3': 'TP.HCM',
    'Quận 7': 'TP.HCM',
    'Bình Thạnh': 'TP.HCM',
    'Cầu Giấy': 'Hà Nội',
    'Đống Đa': 'Hà Nội',
    'Ba Đình': 'Hà Nội',
    'Thanh Xuân': 'Hà Nội',
    'Hai Bà Trưng': 'Hà Nội',
    'Hoàn Kiếm': 'Hà Nội',
    'Nam Từ Liêm': 'Hà Nội',
    'Bắc Từ Liêm': 'Hà Nội',
  };

  static const Map<String, String> _legacyParentCityAliases = {
    'quận 2': 'TP.HCM',
    'quận 4': 'TP.HCM',
    'quận 5': 'TP.HCM',
    'quận 6': 'TP.HCM',
    'quận 8': 'TP.HCM',
    'quận 10': 'TP.HCM',
    'quận 11': 'TP.HCM',
    'quận 12': 'TP.HCM',
    'phú nhuận': 'TP.HCM',
    'quận phú nhuận': 'TP.HCM',
    'tân bình': 'TP.HCM',
    'quận tân bình': 'TP.HCM',
    'tân phú': 'TP.HCM',
    'quận tân phú': 'TP.HCM',
    'gò vấp': 'TP.HCM',
    'quận gò vấp': 'TP.HCM',
    'bình tân': 'TP.HCM',
    'quận bình tân': 'TP.HCM',
    'nhà bè': 'TP.HCM',
    'huyện nhà bè': 'TP.HCM',
    'bình chánh': 'TP.HCM',
    'huyện bình chánh': 'TP.HCM',
    'hóc môn': 'TP.HCM',
    'huyện hóc môn': 'TP.HCM',
    'củ chi': 'TP.HCM',
    'huyện củ chi': 'TP.HCM',
    'cần giờ': 'TP.HCM',
    'huyện cần giờ': 'TP.HCM',
    'tây hồ': 'Hà Nội',
    'quận tây hồ': 'Hà Nội',
    'hoàng mai': 'Hà Nội',
    'quận hoàng mai': 'Hà Nội',
    'long biên': 'Hà Nội',
    'quận long biên': 'Hà Nội',
    'hà đông': 'Hà Nội',
    'quận hà đông': 'Hà Nội',
    'hải châu': 'Đà Nẵng',
    'quận hải châu': 'Đà Nẵng',
    'sơn trà': 'Đà Nẵng',
    'quận sơn trà': 'Đà Nẵng',
    'thanh khê': 'Đà Nẵng',
    'quận thanh khê': 'Đà Nẵng',
    'ngũ hành sơn': 'Đà Nẵng',
    'quận ngũ hành sơn': 'Đà Nẵng',
    'liên chiểu': 'Đà Nẵng',
    'quận liên chiểu': 'Đà Nẵng',
    'cẩm lệ': 'Đà Nẵng',
    'quận cẩm lệ': 'Đà Nẵng',
  };

  static const schedules = [
    'buổi sáng',
    'buổi chiều',
    'buổi tối',
    'cuối tuần',
    'thứ hai',
    'thứ ba',
    'thứ tư',
    'thứ năm',
    'thứ sáu',
    'thứ bảy',
    'chủ nhật',
  ];
  static const modes = ['online', 'in_person'];
  static const maxFee = 10000000;
  static const keys = {
    'subject',
    'grade',
    'location',
    'maxHourlyFee',
    'schedule',
    'teachingMode',
  };

  static String _collapseKey(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Normalizes a canonical location or known alias to an entry in [locations].
  /// Returns `null` when [raw] is blank or unrecognized.
  static String? normalizeLocation(String? raw) {
    if (raw == null) return null;
    final key = _collapseKey(raw);
    if (key.isEmpty) return null;
    for (final canonical in locations) {
      if (canonical.toLowerCase() == key) return canonical;
    }
    return locationAliases[key];
  }

  /// Normalizes known geographical aliases to [locations] while preserving
  /// unrecognized legacy/custom area labels without dropping data.
  static String normalizeLocationOrPreserve(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '';
    return normalizeLocation(trimmed) ?? trimmed;
  }

  /// Normalizes and deduplicates a list of tutor areas while keeping order and
  /// preserving legacy area labels outside the canonical allowlist.
  static List<String> normalizeLocationList(Iterable<String> rawAreas) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final area in rawAreas) {
      final token = normalizeLocationOrPreserve(area);
      if (token.isEmpty) continue;
      if (seen.add(token.toLowerCase())) {
        normalized.add(token);
      }
    }
    return normalized;
  }

  /// Returns the parent city (`'TP.HCM'`, `'Hà Nội'`, or `'Đà Nẵng'`) for a
  /// district-level area, or `null` for a city-level entry or unknown label.
  static String? parentCityForLocation(String location) {
    final key = _collapseKey(location);
    if (key.isEmpty) return null;
    final canonical = normalizeLocation(key);
    if (canonical != null) {
      return _districtParentCities[canonical];
    }
    return _legacyParentCityAliases[key];
  }

  /// Symmetric hierarchical matching between recorded [tutorAreas] and a
  /// confirmed or selected [requestedLocation]:
  /// - Equivalent aliases match (`'Thành phố Hồ Chí Minh'` <-> `'TP.HCM'`).
  /// - City request matches tutors in the city or any district of that city
  ///   (`'Hà Nội'` <-> `'Cầu Giấy'`).
  /// - District request matches tutors in that district or covering the whole
  ///   parent city (`'Cầu Giấy'` <-> `'Hà Nội'`), never a different district.
  static bool tutorMatchesLocation(
    List<String> tutorAreas,
    String? requestedLocation,
  ) {
    if (requestedLocation == null || requestedLocation.trim().isEmpty) {
      return true;
    }
    final targetNormalized = normalizeLocationOrPreserve(requestedLocation);
    final targetKey = targetNormalized.toLowerCase();
    final targetParentCity = parentCityForLocation(targetNormalized);

    for (final rawArea in tutorAreas) {
      final areaNormalized = normalizeLocationOrPreserve(rawArea);
      if (areaNormalized.isEmpty) continue;
      if (areaNormalized.toLowerCase() == targetKey) {
        return true;
      }
      final areaParentCity = parentCityForLocation(areaNormalized);
      if (areaParentCity != null && areaParentCity.toLowerCase() == targetKey) {
        return true;
      }
      if (targetParentCity != null &&
          areaNormalized.toLowerCase() == targetParentCity.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  static NormalizedTutorNeed decode(String json) {
    if (json.length > 2048) throw const FormatException('Oversized response');
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> ||
        !data.keys.toSet().containsAll(keys) ||
        data.length != keys.length) {
      throw const FormatException('Invalid requirement fields');
    }
    String? known(String key, List<String> allowed) {
      final value = data[key];
      if (value == null) return null;
      if (value is! String || !allowed.contains(value)) {
        throw const FormatException('Unsupported requirement');
      }
      return value;
    }

    String? knownLocation() {
      final value = data['location'];
      if (value == null) return null;
      if (value is! String) {
        throw const FormatException('Unsupported requirement');
      }
      final canonical = normalizeLocation(value);
      if (canonical == null) {
        throw const FormatException('Unsupported requirement');
      }
      return canonical;
    }

    int? integer(String key, int max) {
      final value = data[key];
      if (value == null) return null;
      if (value is! int || value < 1 || value > max) {
        throw const FormatException('Invalid requirement number');
      }
      return value;
    }

    return NormalizedTutorNeed(
      subject: known('subject', subjects),
      grade: integer('grade', 12),
      location: knownLocation(),
      maxHourlyFee: integer('maxHourlyFee', maxFee),
      schedule: known('schedule', schedules),
      teachingMode: known('teachingMode', modes),
    );
  }
}
