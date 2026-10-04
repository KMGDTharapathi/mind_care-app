import '../services/auth/auth_service.dart';
import '../services/auth/firebase_auth_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/crashlytics/crashlytics_service.dart';
import '../services/sync/sync_service.dart';
import '../services/sync/write_queue.dart';
import '../services/remote_config/remote_config_service.dart';
import '../data/local/hive_service.dart';

/// Simple static service locator that holds singleton instances of
/// Firebase-backed services. Populated once in [main] after Firebase is
/// initialised; all fields are nullable so the app degrades gracefully when
/// Firebase is unavailable.
class ServiceLocator {
  ServiceLocator._();

  static AuthService? authService;
  static WriteQueue? writeQueue;
  static SyncService? syncService;
  static RemoteConfigService? remoteConfigService;
  static AnalyticsService? analyticsService;
  static CrashlyticsService? crashlyticsService;

  /// Initialises the core Firebase services and stores them as singletons.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops if the services
  /// are already set.
  static Future<void> init({
    AuthService? auth,
    WriteQueue? queue,
    SyncService? sync,
    RemoteConfigService? remoteConfig,
    AnalyticsService? analytics,
    CrashlyticsService? crashlytics,
  }) async {
    authService ??= auth ?? FirebaseAuthService();
    // Reuse the already-open Hive box from HiveService instead of opening it again.
    // Opening the same box twice can deadlock the main isolate and cause ANR.
    writeQueue ??= queue ?? WriteQueue.fromBox(HiveService.writeQueue);
    crashlyticsService ??= crashlytics;
    syncService ??= sync ??
        FirestoreSyncService(
          authService: authService!,
          writeQueue: writeQueue!,
          crashlyticsService: crashlyticsService,
        );
    remoteConfigService ??= remoteConfig;
    analyticsService ??= analytics;
  }

  /// Resets all singletons (useful in tests).
  static void reset() {
    authService = null;
    writeQueue = null;
    syncService = null;
    remoteConfigService = null;
    analyticsService = null;
    crashlyticsService = null;
  }
}
