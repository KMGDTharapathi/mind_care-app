import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mind_care_app/services/crashlytics/crashlytics_service.dart';
import 'package:mind_care_app/services/remote_config/remote_config_service.dart';

class FirebaseRemoteConfigService implements RemoteConfigService {
  final FirebaseRemoteConfig? _remoteConfigOverride;
  final CrashlyticsService crashlyticsService;

  FirebaseRemoteConfigService({
    required this.crashlyticsService,
    FirebaseRemoteConfig? remoteConfig,
  }) : _remoteConfigOverride = remoteConfig;

  // Lazily access FirebaseRemoteConfig.instance so it's only resolved
  // after Firebase.initializeApp() has been called.
  FirebaseRemoteConfig get _remoteConfig =>
      _remoteConfigOverride ?? FirebaseRemoteConfig.instance;

  static const Map<String, dynamic> _defaults = {
    'enable_cloud_sync': true,
    'enable_analytics': true,
    'max_journal_entries': 500,
    'resource_library_version': '1.0.0',
  };

  @override
  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 3),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      await crashlyticsService.recordError(
        e,
        stack,
        reason: 'RemoteConfig fetchAndActivate failed',
      );
    }
  }

  @override
  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (_) {
      return _defaults[key] as bool? ?? false;
    }
  }

  @override
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (_) {
      return _defaults[key] as int? ?? 0;
    }
  }

  @override
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return _defaults[key] as String? ?? '';
    }
  }
}
