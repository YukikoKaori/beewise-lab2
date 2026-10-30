import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/tutor.dart';
import 'remote_config_service.dart';
import 'tutor_repository.dart';

class TutorRecommendation {
  const TutorRecommendation(this.tutor, this.reason);
  final Tutor tutor;
  final String reason;
}

class MatchingService {
  MatchingService(this._repository, this._remoteConfig);

  final TutorRepository _repository;
  final RemoteConfigService _remoteConfig;

  Future<List<TutorRecommendation>> match(String need) async {
    final request = need.trim();
    if (request.isEmpty) {
      throw const MatchingException('Bạn hãy mô tả nhu cầu học tập trước nhé.');
    }
    if (request.length > 500) {
      throw const MatchingException('Nội dung tối đa 500 ký tự.');
    }
    if (!_remoteConfig.matchingEnabled) {
      throw const MatchingException(
        'Tính năng ghép gia sư đang tạm dừng. Bạn có thể tự tìm theo bộ lọc.',
      );
    }
    final tutors = (await _repository.activeTutors(limit: 100))
        .where((tutor) => !tutor.isSyntheticTestFixture)
        .toList(growable: false);
    if (tutors.isEmpty) return const [];

    final candidates = tutors
        .map(
          (tutor) => {
            'id': tutor.id,
            'subjects': tutor.subjects,
            'grades': tutor.grades,
            'credential': tutor.credential,
            'introduction': tutor.introduction,
            'hourlyFee': tutor.hourlyFee,
            'areas': tutor.areas,
            'teachingModes': tutor.teachingModes,
            'availability': tutor.availability,
            'verified': tutor.verified,
          },
        )
        .toList();
    final model = FirebaseAI.googleAI().generativeModel(
      model: _remoteConfig.modelName,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      systemInstruction: Content.text(
        'Bạn là trợ lý gợi ý gia sư của BeeWise. Chỉ chọn từ các hồ sơ được cung cấp. '
        'Không suy đoán thông tin còn thiếu. Trả về JSON object có trường '
        '"recommendations": array gồm tối đa ${_remoteConfig.aiResultLimit} phần tử, '
        'mỗi phần tử có "tutorId" và "reason" bằng tiếng Việt. Không thêm nội dung ngoài JSON.',
      ),
    );
    final response = await model.generateContent([
      Content.text(
        'Nhu cầu (không chứa thông tin định danh): $request\nHồ sơ thật: ${jsonEncode(candidates)}',
      ),
    ]);
    final content = response.text;
    if (content == null || content.isEmpty) {
      throw const MatchingException(
        'AI chưa trả về kết quả. Nội dung của bạn vẫn được giữ để thử lại.',
      );
    }
    late final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(content);
      if (value is! Map) {
        throw const MatchingException(
          'AI trả về dữ liệu không đúng định dạng. Hãy thử lại hoặc tự tìm gia sư.',
        );
      }
      decoded = Map<String, dynamic>.from(value);
    } on FormatException {
      throw const MatchingException(
        'AI chưa trả về kết quả hợp lệ. Nội dung của bạn vẫn được giữ để thử lại.',
      );
    }
    final rawItems = decoded['recommendations'];
    if (rawItems != null && rawItems is! List) {
      throw const MatchingException(
        'AI trả về danh sách gợi ý không đúng định dạng. Hãy thử lại.',
      );
    }
    final items = rawItems as List<dynamic>? ?? const [];
    final byId = {for (final tutor in tutors) tutor.id: tutor};
    final results = <TutorRecommendation>[];
    for (final item in items.take(_remoteConfig.aiResultLimit)) {
      if (item is! Map<String, dynamic>) continue;
      final tutorId = item['tutorId'];
      if (tutorId is! String) continue;
      final tutor = byId[tutorId];
      if (tutor == null) continue;
      final reason = item['reason'];
      final safeReason = reason is String && reason.trim().isNotEmpty
          ? String.fromCharCodes(reason.trim().runes.take(300))
          : 'Gia sư có thông tin phù hợp với nhu cầu của bạn.';
      results.add(TutorRecommendation(tutor, safeReason));
    }
    return results;
  }
}

class MatchingException implements Exception {
  const MatchingException(this.message);
  final String message;
  @override
  String toString() => message;
}
