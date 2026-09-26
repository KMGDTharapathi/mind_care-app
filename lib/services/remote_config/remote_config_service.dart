abstract class RemoteConfigService {
  Future<void> fetchAndActivate();
  bool getBool(String key);
  int getInt(String key);
  String getString(String key);
}
