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

  factory Tutor.fromMap(String id, Map<String, dynamic> map) => Tutor(
    id: id,
    name: map['name'] as String? ?? '',
    credential: map['credential'] as String? ?? '',
    introduction: map['introduction'] as String? ?? '',
    subjects: _stringList(map['subjects']),
    grades: _stringList(map['grades']),
    hourlyFee: (map['hourlyFee'] as num?)?.round() ?? 0,
    areas: _stringList(map['areas']),
    teachingModes: _stringList(map['teachingModes']),
    availability: map['availability'] as String? ?? '',
    verified: map['verified'] as bool? ?? false,
    active: map['active'] as bool? ?? false,
    rating: (map['rating'] as num?)?.toDouble(),
    reviewCount: (map['reviewCount'] as num?)?.round() ?? 0,
    experienceYears: (map['experienceYears'] as num?)?.round() ?? 0,
    avatarUrl: map['avatarUrl'] as String?,
  );

  static List<String> _stringList(Object? value) => value is Iterable
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
