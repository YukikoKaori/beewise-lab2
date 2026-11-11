import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({this._analytics});

  final FirebaseAnalytics? _analytics;

  Future<void> event(String name, [Map<String, Object>? parameters]) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Telemetry must never turn a successful user action into a failed one.
    }
  }

  Future<void> login(String method) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logLogin(loginMethod: method);
    } catch (_) {
      // Authentication success does not depend on analytics availability.
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _analytics?.setUserId(id: uid);
    } catch (_) {
      // A telemetry outage must not interrupt authentication or sign-out.
    }
  }

  Future<void> search({
    required int queryLength,
    required int filterCount,
    required String sortMode,
    required int resultCount,
    required String outcome,
  }) => event('search', {
    'query_length': queryLength,
    'filter_count': filterCount,
    'sort_mode': sortMode,
    'result_count': resultCount,
    'outcome': outcome,
  });

  Future<void> tutorViewed({
    required int subjectCount,
    required String entrySource,
  }) => event('view_tutor', {
    'subject_count': subjectCount,
    'entry_source': entrySource,
  });

  Future<void> detailViewed(String detailType) =>
      event('view_detail', {'detail_type': detailType});
}
