import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mind_care_app/services/consent/consent_service.dart';
import 'package:mind_care_app/services/crashlytics/crashlytics_service.dart';

class FirebaseCrashlyticsService implements CrashlyticsService {
  final ConsentService consentService;
  final FirebaseCrashlytics? _crashlyticsOverride;

  FirebaseCrashlyticsService({
    required this.consentService,
    FirebaseCrashlytics? crashlytics,
  }) : _crashlyticsOverride = crashlytics;

  // Lazily access FirebaseCrashlytics.instance so it's only resolved
  // after Firebase.initializeApp() has been called.
  FirebaseCrashlytics get _crashlytics =>
      _crashlyticsOverride ?? FirebaseCrashlytics.instance;

  @override
  Future<void> setUserId(String? uid) async {
    if (kIsWeb) return;
    if (!await consentService.isAnalyticsEnabled()) return;
    await _crashlytics.setUserIdentifier(uid ?? '');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kIsWeb) return;
    if (!await consentService.isAnalyticsEnabled()) return;
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }
}
