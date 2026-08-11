import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/provider_contracts.dart';
import '../../shared/models/feature_flags.dart';

/// Exposes [FirebaseRemoteConfig] as a Riverpod provider.
///
/// Firebase must have been initialised in `main()` via [Firebase.initializeApp]
/// before this provider is accessed.
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instanceFor(app: Firebase.app());
});

/// Foundation [RemoteConfigProvider] implementation backed by Firebase Remote
/// Config.
///
/// This is the foundation stub — it fetches and activates remote values but
/// delegates feature-flag parsing to [FeatureFlags.fromRemoteConfig].  Feature
/// flag logic is intentionally out of scope for this task.
///
/// ## Note on mock providers
/// [app_providers.dart] still wires [remoteConfigProvider] to
/// [MockRemoteConfigRepository].  This class is available for explicit override
/// in live builds but does **not** replace the mock yet.
class FirebaseRemoteConfigProviderImpl implements RemoteConfigProvider {
  const FirebaseRemoteConfigProviderImpl(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> fetchAndActivate() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.fetchAndActivate();
  }

  @override
  Future<FeatureFlags> getFlags() async {
    // Feature-flag parsing is out of scope for this task.
    // Returns the current FeatureFlags defaults (const constructor); a
    // follow-up task will wire the real Remote Config values into each flag.
    return const FeatureFlags();
  }
}

/// Exposes the [RemoteConfigProvider] contract backed by Firebase Remote
/// Config.  Intended for use in live builds — [app_providers.dart] still
/// serves [MockRemoteConfigRepository] in mock mode.
final firebaseRemoteConfigServiceProvider =
    Provider<RemoteConfigProvider>((ref) {
  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  return FirebaseRemoteConfigProviderImpl(remoteConfig);
});
