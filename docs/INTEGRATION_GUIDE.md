# Integration Guide — Wiring Feature Modules Together

## Overview
Because shared contracts (`lib/core/contracts/`) and models (`lib/shared/models/`) are pre-built, each developer implements their concrete logic independently and registers it in `lib/core/providers/app_providers.dart`.

## Switching from Mock Mode to Live Production Mode
In `lib/core/providers/app_providers.dart`:
```dart
// Change from Mock to Production:
final mockModeProvider = StateProvider<bool>((ref) => false);
```

When `mockModeProvider` is false, `marketRepositoryProvider` resolves to `BinanceMarketProvider`, `authRepositoryProvider` resolves to `SupabaseAuthRepository`, and `subscriptionProvider` resolves to `RevenueCatSubscriptionProvider`.
