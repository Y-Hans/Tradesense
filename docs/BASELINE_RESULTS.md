# Baseline Execution Results
**Captured**: 2026-08-15
**Branch/Commit**: 5001d80 fix: stabilize responsive themes and UI

## 1. Package Resolution
- `flutter pub get`: **SUCCESS (Exit 0)**

## 2. Code Generation
- `dart run build_runner build --delete-conflicting-outputs`: **SUCCESS (Exit 0)** (127s)

## 3. Static Analysis
- `flutter analyze`: **0 Errors, 264 Info/Warning issues** (mostly linting/const constructors)

## 4. Test Suite Baseline
- `flutter test`: **375 Passed, 8 Failed, 1 Skipped**
- Pre-existing Failures (8):
  1. `test/unit/market/cached_market_repository_test.dart`: Cache Version Mismatch with API Failure
  2. `test/unit/market/cached_market_repository_test.dart`: Stale Cache Fallback
  3. `test/unit/market/market_cache_providers_test.dart`: app marketRepositoryProvider resolves to cachedMarketRepositoryProvider
  4. `test/unit/market/market_cache_providers_test.dart`: marketCachePolicyProvider returns default market policy
  5. `test/unit/onboarding_flow_test.dart`: Fresh app start requires onboarding completion
  6. `test/unit/onboarding_flow_test.dart`: Completing onboarding persists state for active user
  7. `test/unit/onboarding_flow_test.dart`: Multiple users maintain independent onboarding completion states
  8. `test/unit/onboarding_flow_test.dart`: Logout clears auth session while retaining user onboarding completion mapping

## 5. Pre-existing Deleted Tests from Git Status
- `test/unit/coach/coach_cache_providers_test.dart`
- `test/unit/coach/openrouter_ai_provider_test.dart`
- `test/unit/coach/openrouter_dtos_test.dart`
- `test/unit/coach/openrouter_prompt_builder_test.dart`
- `test/unit/coach/openrouter_providers_test.dart`
- `test/unit/learning_progression_test.dart`
