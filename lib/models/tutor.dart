class Tutor {
  const Tutor({
    required this.id,
    required this.name,
    required this.credential,
    required this.introduction,
    required this.subjects,
    required this.grades,
    required this.hourlyFee,
    required this.areas,
    required this.teachingModes,
    required this.availability,
    required this.verified,
    required this.active,
    this.rating,
    this.reviewCount = 0,
    this.experienceYears = 0,
    this.avatarUrl,
    this.isSyntheticTestFixture = false,
    this.isDemoProfile = false,
  });

  final String id;
  final String name;
  final String credential;
  final String introduction;
  final List<String> subjects;
  final List<String> grades;
  final int hourlyFee;
  final List<String> areas;
  final List<String> teachingModes;
  final String availability;
  final bool verified;
  final bool active;
  final double? rating;
  final int reviewCount;
  final int experienceYears;
  final String? avatarUrl;
  final bool isSyntheticTestFixture;
  final bool isDemoProfile;

  static const demoTutorId = 'tutor_acd3824aa8734c63ac8827df';
  static const demoDisclosure = 'Hồ sơ demo — đã duyệt cho kiểm thử';
  static const demoDisclaimer =
      'Thông tin do chủ hồ sơ cung cấp; chưa xác minh chuyên môn hoặc kinh nghiệm.';
  bool get reportEligible =>
      active && !isSyntheticTestFixture && (verified || isDemoProfile);

  factory Tutor.fromMap(String id, Map<String, dynamic> map) {
    final namespace = map['fixtureNamespace'];
    final synthetic =
        map['syntheticTestFixture'] == true ||
        (namespace is String && namespace.trim().isNotEmpty) ||
        id.startsWith('bao-lab3-');
    final name = map['name'] as String? ?? '';
    final demo =
        !synthetic &&
        id == demoTutorId &&
        map['demoOnly'] == true &&
        map['verified'] == false;
    return Tutor(
      id: id,
      name: synthetic && !name.startsWith('[TEST]') ? '[TEST] $name' : name,
      credential: map['credential'] as String? ?? '',
      introduction: map['introduction'] as String? ?? '',
      subjects: _stringList(map['subjects']),
      grades: _stringList(map['grades']),
      hourlyFee: (map['hourlyFee'] as num?)?.round() ?? 0,
      areas: _stringList(map['areas']),
      teachingModes: _stringList(map['teachingModes']),
      availability: map['availability'] as String? ?? '',
      verified:
          !synthetic &&
          (!map.containsKey('demoOnly') || map['demoOnly'] == false) &&
          (map['verified'] as bool? ?? false),
      active: map['active'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: (map['reviewCount'] as num?)?.round() ?? 0,
      experienceYears: (map['experienceYears'] as num?)?.round() ?? 0,
      avatarUrl: map['avatarUrl'] as String?,
      isSyntheticTestFixture: synthetic,
      isDemoProfile: demo,
    );
  }

  static List<String> _stringList(Object? value) => value is Iterable
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
