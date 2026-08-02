import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the [FirebaseCrashlytics] singleton as a Riverpod provider.
///
/// Firebase must have been initialised in `main()` via [Firebase.initializeApp]
/// before this provider is accessed.
///
/// ## Usage
/// ```dart
/// final crashlytics = ref.watch(firebaseCrashlyticsProvider);
/// await crashlytics.recordError(error, stack, fatal: false);
/// ```
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>((ref) {
  return FirebaseCrashlytics.instance;
});
