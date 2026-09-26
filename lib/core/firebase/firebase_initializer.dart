import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mind_care_app/services/remote_config/remote_config_service.dart';

/// Result of a Firebase initialisation attempt.
class FirebaseInitResult {
  final bool success;
  final String? error;

  /// Whether cloud sync is enabled per Remote Config (defaults to true).
  final bool enableCloudSync;

  /// Whether analytics/crashlytics are enabled per Remote Config (defaults to true).
  final bool enableAnalytics;

  const FirebaseInitResult({
    required this.success,
    this.error,
    this.enableCloudSync = true,
    this.enableAnalytics = true,
  });
}

/// Handles Firebase initialisation and Remote Config bootstrapping.
class FirebaseInitializer {
  /// Initialises Firebase, optionally fetches Remote Config, and returns a
  /// [FirebaseInitResult] with feature-flag values.
  ///
  /// Pass [remoteConfigService] to have `fetchAndActivate()` called immediately
  /// after Firebase init so that the latest flags are available at startup.
  static Future<FirebaseInitResult> init({
    RemoteConfigService? remoteConfigService,
  }) async {
    try {
      // Use a timeout shorter than Android's 5s ANR threshold.
      // Firebase.initializeApp() can block on slow/first-launch devices.
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 4));

      // Re-enable collection now that Firebase is initialized on the Dart side.
      // These were disabled in AndroidManifest.xml to prevent auto-init from
      // blocking the main thread before Flutter starts.
      unawaited(FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true)
          .catchError((_) {}));
      unawaited(FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)
          .catchError((_) {}));
      unawaited(FirebaseMessaging.instance.setAutoInitEnabled(true)
          .catchError((_) {}));

      bool enableCloudSync = true;
      bool enableAnalytics = true;

      if (remoteConfigService != null) {
        // Fetch in the background — don't block startup on a network call.
        remoteConfigService.fetchAndActivate().then((_) {
          // Flags will be picked up on next read after the background fetch.
        }).catchError((_) {});
        // Read cached/default values immediately (no await).
        enableCloudSync = remoteConfigService.getBool('enable_cloud_sync');
        enableAnalytics = remoteConfigService.getBool('enable_analytics');
      }

      return FirebaseInitResult(
        success: true,
        enableCloudSync: enableCloudSync,
        enableAnalytics: enableAnalytics,
      );
    } catch (e) {
      // Timeout or other error — treat as non-fatal, app continues without Firebase
      return FirebaseInitResult(success: true, error: e.toString());
    }
  }
}
