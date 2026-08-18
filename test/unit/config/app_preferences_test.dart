import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptoedu/core/config/app_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.resetForTesting(clear: false);
    await AppPreferences.initialize();
  });

  test('fresh install has no disclaimer or onboarding state', () {
    expect(AppPreferences.isInstallationDisclaimerAccepted, isFalse);
    expect(AppPreferences.isUserOnboardingCompleted('user-a'), isFalse);
  });

  test('preferences are scoped per user and survive reinitialization',
      () async {
    await AppPreferences.setInstallationDisclaimerAccepted(true);
    await AppPreferences.setUserOnboardingCompleted('user-a', true);

    final preferences = await SharedPreferences.getInstance();
    await AppPreferences.resetForTesting(clear: false);
    await AppPreferences.initialize(preferences: preferences);

    expect(AppPreferences.isInstallationDisclaimerAccepted, isTrue);
    expect(AppPreferences.isUserOnboardingCompleted('user-a'), isTrue);
    expect(AppPreferences.isUserOnboardingCompleted('user-b'), isFalse);
  });

  test(
      'reading before initialization fails clearly instead of depending on order',
      () async {
    await AppPreferences.resetForTesting(clear: false);

    expect(
      () => AppPreferences.isInstallationDisclaimerAccepted,
      throwsA(isA<StateError>()),
    );
  });
}
