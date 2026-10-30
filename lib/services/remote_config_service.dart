import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService(this._config);

  final FirebaseRemoteConfig? _config;

  Future<void> initialize() async {
    final config = _config;
    if (config == null) return;
    await config.setDefaults(const {
      'home_tutor_limit': 6,
      'ai_result_limit': 3,
      'ai_matching_enabled': true,
      'gemini_model': 'gemini-2.5-flash',
    });
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );
    try {
      await config.fetchAndActivate();
    } catch (_) {
      // In-app defaults remain available when Remote Config is unreachable.
    }
  }

  int get homeTutorLimit => _limit('home_tutor_limit', 6, 100);
  // The handoff permits up to three ranked AI recommendations.
  int get aiResultLimit => _limit('ai_result_limit', 3, 3);
  bool get matchingEnabled => _config?.getBool('ai_matching_enabled') ?? true;
  String get modelName {
    final model = _config?.getString('gemini_model').trim();
    return model == null || model.isEmpty ? 'gemini-2.5-flash' : model;
  }

  int _limit(String key, int fallback, int maximum) {
    final value = _config?.getInt(key) ?? fallback;
    return value < 1 ? fallback : value.clamp(1, maximum);
  }
}
