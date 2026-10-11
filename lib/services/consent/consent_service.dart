import 'package:mind_care_app/data/local/preferences_service.dart';

class ConsentService {
  static const _keyAnalyticsConsent = 'analytics_consent_given';
  static const _keyConsentPromptShown = 'consent_prompt_shown';

  Future<bool> hasConsentBeenDecided() async {
    final prefs = await PreferencesService.getSharedPreferences();
    return prefs.getBool(_keyConsentPromptShown) ?? false;
  }

  Future<bool> isAnalyticsEnabled() async {
    final prefs = await PreferencesService.getSharedPreferences();
    return prefs.getBool(_keyAnalyticsConsent) ?? false;
  }

  Future<void> setAnalyticsConsent(bool value) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setBool(_keyAnalyticsConsent, value);
    await prefs.setBool(_keyConsentPromptShown, true);
  }
}
