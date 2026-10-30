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

  int get homeTutorLimit => _config?.getInt('home_tutor_limit') ?? 6;
  int get aiResultLimit => _config?.getInt('ai_result_limit') ?? 3;
  bool get matchingEnabled => _config?.getBool('ai_matching_enabled') ?? true;
  String get modelName =>
      _config?.getString('gemini_model') ?? 'gemini-2.5-flash';
}
