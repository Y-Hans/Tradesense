import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static SharedPreferences? _prefs;

  /// Initializes preferences before any application read or write.
  ///
  /// The optional instance is intentionally injectable so tests can provide a
  /// deterministic in-memory SharedPreferences instance without relying on
  /// test ordering or hidden global initialization.
  static Future<void> initialize({SharedPreferences? preferences}) async {
    _prefs = preferences ?? await SharedPreferences.getInstance();
  }

  /// Clears the current binding. This is only for deterministic test setup.
  static Future<void> resetForTesting({bool clear = true}) async {
    final preferences = _prefs;
    if (clear && preferences != null) {
      await preferences.clear();
    }
    _prefs = null;
  }

  static SharedPreferences get _initializedPreferences {
    final preferences = _prefs;
    if (preferences == null) {
      throw StateError(
        'AppPreferences.initialize() must complete before preferences are read.',
      );
    }
    return preferences;
  }

  static const String _kInstallationDisclaimerAccepted =
      'installation_disclaimer_accepted';
  static const String _kUserOnboardingCompleted = 'user_onboarding_completed_';

  // Device-level installation disclaimer
  static bool get isInstallationDisclaimerAccepted =>
      _initializedPreferences.getBool(_kInstallationDisclaimerAccepted) ??
      false;

  static Future<void> setInstallationDisclaimerAccepted(bool value) async {
    await _initializedPreferences.setBool(
        _kInstallationDisclaimerAccepted, value);
  }

  // User-level onboarding (auth-dependent)
  static bool isUserOnboardingCompleted(String userId) {
    return _initializedPreferences
            .getBool('$_kUserOnboardingCompleted$userId') ??
        false;
  }

  static Future<void> setUserOnboardingCompleted(
      String userId, bool value) async {
    await _initializedPreferences.setBool(
        '$_kUserOnboardingCompleted$userId', value);
  }
}
