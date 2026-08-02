import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/provider_contracts.dart';

/// Exposes [FirebaseAnalytics] as a Riverpod provider.
///
/// Firebase must have been initialised in `main()` via [Firebase.initializeApp]
/// before this provider is accessed.
///
/// ## Guard behaviour
/// If [AppConfig.isFirebaseConfigured] is `false` this provider throws a
/// [StateError] instead of returning a broken analytics instance — matching the
/// same contract as [supabaseClientProvider].
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instanceFor(app: Firebase.app());
});

/// Riverpod-integrated [AnalyticsProvider] implementation backed by Firebase.
///
/// Wraps [FirebaseAnalytics] and conforms to the [AnalyticsProvider] contract
/// defined in `provider_contracts.dart` so that consuming layers remain
/// decoupled from the Firebase SDK.
class FirebaseAnalyticsProviderImpl implements AnalyticsProvider {
  const FirebaseAnalyticsProviderImpl(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) {
    return _analytics.logEvent(
      name: name,
      parameters: parameters?.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
    );
  }

  @override
  Future<void> setUserProperty(String key, String value) {
    return _analytics.setUserProperty(name: key, value: value);
  }

  @override
  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }
}

/// Exposes the [AnalyticsProvider] contract implementation as a Riverpod
/// provider.  Depends on [firebaseAnalyticsProvider] and will propagate any
/// [StateError] it throws when Firebase is not configured.
final analyticsProvider = Provider<AnalyticsProvider>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsProviderImpl(analytics);
});
