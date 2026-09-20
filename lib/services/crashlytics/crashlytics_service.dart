abstract class CrashlyticsService {
  Future<void> setUserId(String? uid);
  Future<void> recordError(Object error, StackTrace? stack, {String? reason, bool fatal = false});
}
