# RevenueCat & Subscription Architecture

## Entitlement Model
- Unique Entitlement Key: `premium`
- Default Offering ID: `default_monthly`

## Provider Abstraction
Flutter feature widgets interact exclusively with `SubscriptionProvider` or `SubscriptionRepository`. No widget directly invokes `Purchases` methods.

```dart
final subProvider = ref.watch(subscriptionProvider);
final status = await subProvider.getStatus();
if (status.isPremium) {
  // Unlock premium feature
}
```

## Mock & Live Backend Mode
In Mock mode, calling `purchasePremium()` or `restorePurchases()` instantly toggles premium status in memory, enabling full paywall UI testing.
In Production mode, `RevenueCatProvider` wraps `purchases_flutter` SDK and validates purchases via RevenueCat backend webhooks.
