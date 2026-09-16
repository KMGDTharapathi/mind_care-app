import 'package:mind_care_app/services/crashlytics/crashlytics_service.dart';
import 'package:mind_care_app/services/remote_config/remote_config_service.dart';

/// No-op implementation when running without Firebase.
class FirebaseRemoteConfigService implements RemoteConfigService {
  final CrashlyticsService crashlyticsService;

  FirebaseRemoteConfigService({required this.crashlyticsService});

  static const Map<String, dynamic> _defaults = {
    'enable_cloud_sync': true,
    'enable_analytics': true,
    'max_journal_entries': 500,
    'resource_library_version': '1.0.0',
  };

  @override
  Future<void> fetchAndActivate() async {
    // No-op when Firebase is not configured
  }

  @override
  bool getBool(String key) {
    return _defaults[key] as bool? ?? false;
  }

  @override
  int getInt(String key) {
    return _defaults[key] as int? ?? 0;
  }

  @override
  String getString(String key) {
    return _defaults[key] as String? ?? '';
  }

  @override
  double getDouble(String key) {
    return _defaults[key] as double? ?? 0.0;
  }
}