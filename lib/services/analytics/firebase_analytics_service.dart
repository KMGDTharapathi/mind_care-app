import 'package:mind_care_app/services/analytics/analytics_service.dart';
import 'package:mind_care_app/services/consent/consent_service.dart';

/// No-op implementation when running without Firebase.
class FirebaseAnalyticsService implements AnalyticsService {
  final ConsentService consentService;

  FirebaseAnalyticsService({required this.consentService});

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // No-op when Firebase is not configured
  }

  @override
  Future<void> setUserId(String? uid) async {
    // No-op when Firebase is not configured
  }
}