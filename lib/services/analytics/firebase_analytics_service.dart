import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';
import 'package:mind_care_app/services/consent/consent_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  final ConsentService consentService;
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService({
    required this.consentService,
    FirebaseAnalytics? analytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!await consentService.isAnalyticsEnabled()) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setUserId(String? uid) async {
    if (!await consentService.isAnalyticsEnabled()) return;
    await _analytics.setUserId(id: uid);
  }
}
