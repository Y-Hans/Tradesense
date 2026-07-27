import '../../shared/models/coach_request.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/feature_flags.dart';

abstract class AIProvider {
  Future<CoachResponse> generateCoachFeedback(CoachRequest request);
}

abstract class SubscriptionProvider {
  Future<void> initialize();
  Future<SubscriptionStatus> getStatus();
  Future<bool> purchasePremium();
  Future<bool> restorePurchases();
}

abstract class AnalyticsProvider {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> setUserProperty(String key, String value);
  Future<void> logScreenView(String screenName);
}

abstract class RemoteConfigProvider {
  Future<void> fetchAndActivate();
  Future<FeatureFlags> getFlags();
}
