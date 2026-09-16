import 'package:mind_care_app/services/consent/consent_service.dart';
import 'package:mind_care_app/services/crashlytics/crashlytics_service.dart';

/// No-op implementation when running without Firebase.
class FirebaseCrashlyticsService implements CrashlyticsService {
  final ConsentService consentService;

  FirebaseCrashlyticsService({required this.consentService});

  @override
  Future<void> setUserId(String? uid) async {
    // No-op when Firebase is not configured
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    // No-op when Firebase is not configured
  }
}