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
    'Hà Nội',
    'Đà Nẵng',
  ];
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
      location: known('location', locations),
      maxHourlyFee: integer('maxHourlyFee', maxFee),
      schedule: known('schedule', schedules),
      teachingMode: known('teachingMode', modes),
    );
  }
}
