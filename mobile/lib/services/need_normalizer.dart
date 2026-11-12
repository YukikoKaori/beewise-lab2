import 'package:beewise_core/beewise_core.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'matching_service.dart' show MatchingException;
import 'remote_config_service.dart';

/// Send a fixed educational vocabulary, never the raw input or tutor records.
String providerSafeNeed(String raw) {
  if (raw.trim().isEmpty || raw.length > 500) return '';
  final hints = <(int, String)>[];
  final coveredSpans = <(int, int)>[];
  final input = raw.toLowerCase().replaceAll(
    RegExp(r'https?://\S+|\S+@\S+'),
    ' ',
  );
  bool overlapsSpan(int start, int end) =>
      coveredSpans.any((span) => start < span.$2 && end > span.$1);
  void add(String pattern, String Function(RegExpMatch) value) {
    final expression = RegExp(
      '(?<![a-zà-ỹ0-9])(?:$pattern)(?![a-zà-ỹ0-9])',
      unicode: true,
    );
    for (final match in expression.allMatches(input)) {
      if (overlapsSpan(match.start, match.end)) continue;
      coveredSpans.add((match.start, match.end));
      hints.add((match.start, value(match)));
    }
  }

  final aliasEntries = NormalizedTutorNeed.locationAliases.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final entry in aliasEntries) {
    final pattern = entry.key.split(' ').map(RegExp.escape).join(r'\s+');
    add(pattern, (_) => entry.value);
  }

  for (final phrase in [
    ...NormalizedTutorNeed.subjects,
    ...NormalizedTutorNeed.schedules,
    'trực tuyến',
    'trực tiếp',
    'online',
    'offline',
    'không muốn',
    'hoặc',
    'ưu tiên',
  ]) {
    add(RegExp.escape(phrase.toLowerCase()), (_) => phrase);
  }
  add(r'lớp\s+(1[0-2]|[1-9])', (m) => 'lớp ${m[1]}');
  add(
    r'(?:dưới|tối đa|ngân sách|học phí)\s+(?:dưới\s+|tối đa\s+)?([1-9][0-9]{0,3})\s*k',
    (m) => 'giới hạn ${m[1]}000 VND',
  );
  add(
    r'(?:dưới|tối đa|ngân sách|học phí)\s+(?:dưới\s+|tối đa\s+)?([1-9][0-9]{4,6})\s*(?:đ|vnd|đồng)',
    (m) => 'giới hạn ${m[1]} VND',
  );
  hints.sort((a, b) => a.$1.compareTo(b.$1));
  return hints.take(24).map((hint) => hint.$2).join(' · ');
}

typedef NeedGenerator = Future<String?> Function(
  String model,
  String prompt,
  String input,
);

class NeedNormalizer {
  NeedNormalizer(
    this.config, {
    NeedGenerator? generate,
    this.timeout = const Duration(seconds: 25),
  }) : _generate = generate ?? _firebase;

  final RemoteConfigService config;
  final NeedGenerator _generate;
  final Duration timeout;

  Future<NormalizedTutorNeed> parse(String raw) async {
    if (!config.matchingEnabled) {
      throw const MatchingException(
        'AI đang tạm dừng. Bạn vẫn có thể điền bộ lọc.',
      );
    }
    final safeInput = providerSafeNeed(raw);
    if (safeInput.isEmpty) {
      throw const MatchingException(
        'Chưa nhận ra thông tin học tập. Hãy thêm môn/lớp hoặc điền bộ lọc.',
      );
    }
    final result = await _generate(
      config.modelName,
      config.needPrompt,
      safeInput,
    ).timeout(timeout);
    if (result == null) throw const FormatException('Empty provider response');
    final need = NormalizedTutorNeed.decode(result);
    final hints = safeInput.split(' · ').toSet();
    if (!hints.containsAll([
          ?need.subject,
          if (need.grade case final grade?) 'lớp $grade',
          ?need.location,
          if (need.maxHourlyFee case final fee?) 'giới hạn $fee VND',
          ?need.schedule,
        ]) ||
        (need.teachingMode == 'online' &&
            !hints.contains('online') &&
            !hints.contains('trực tuyến')) ||
        (need.teachingMode == 'in_person' &&
            !hints.contains('offline') &&
            !hints.contains('trực tiếp'))) {
      throw const FormatException('Provider returned an unsupported hint');
    }
    return need;
  }

  static Future<String?> _firebase(
    String model,
    String prompt,
    String input,
  ) async {
    final output = await FirebaseAI.googleAI()
        .generativeModel(
          model: model,
          systemInstruction: Content.text(
            'Chuẩn hóa các gợi ý học tập sau khi đã lọc dữ liệu riêng tư. '
            'Không tự suy đoán thông tin; trả null khi thiếu hoặc mơ hồ. '
            'Không đưa danh tính cá nhân, văn bản tự do hay dữ liệu ngoài schema. $prompt',
          ),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            maxOutputTokens: 768,
            responseSchema: Schema.object(
              properties: {
                'subject': Schema.enumString(
                  enumValues: NormalizedTutorNeed.subjects,
                  nullable: true,
                ),
                'grade': Schema.integer(
                  minimum: 1,
                  maximum: 12,
                  nullable: true,
                ),
                'location': Schema.enumString(
                  enumValues: NormalizedTutorNeed.locations,
                  nullable: true,
                ),
                'maxHourlyFee': Schema.integer(
                  minimum: 1,
                  maximum: NormalizedTutorNeed.maxFee,
                  nullable: true,
                ),
                'schedule': Schema.enumString(
                  enumValues: NormalizedTutorNeed.schedules,
                  nullable: true,
                ),
                'teachingMode': Schema.enumString(
                  enumValues: NormalizedTutorNeed.modes,
                  nullable: true,
                ),
              },
            ),
          ),
        )
        .generateContent([Content.text(input)]);
    return output.text;
  }
}
