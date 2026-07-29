# NEEL — FILE OWNERSHIP INVENTORY

**Owner**: Neel (Auth, User Lifecycle, Onboarding, Learning, Missions, XP & Profile)  
**Last Updated**: 2026-07-29  

---

## Owned Files & Directories

### 1. Authentication & User Lifecycle Domain (`lib/features/auth/`)
- `lib/features/auth/domain/auth_state.dart`: Authentication state model (`restoringSession`, `unauthenticated`, `authenticating`, `authenticated`, `error`).
- `lib/features/auth/domain/auth_exception.dart`: Domain authentication exceptions and user-friendly error translations.
- `lib/features/auth/data/supabase_auth_repository.dart`: Supabase backend implementation of `AuthRepository`.
- `lib/features/auth/application/auth_notifier.dart`: Riverpod `StateNotifier` managing authentication operations and session lifecycle restoration.
- `lib/features/auth/application/user_lifecycle_notifier.dart`: Riverpod `StateNotifier` managing idempotent user lifecycle initialization (contains `TODO(Laksh)` for future financial setup).
- `lib/features/auth/presentation/login_screen.dart`: Login form presentation with UI validation, loading indicators, and error feedback.
- `lib/features/auth/presentation/register_screen.dart`: Registration form presentation with UI validation, loading indicators, and error feedback.

### 2. Onboarding Feature & Application (`lib/features/onboarding/`)
- `lib/features/onboarding/application/onboarding_notifier.dart`: Riverpod `StateNotifier` managing user onboarding completion state per user ID.
- `lib/features/onboarding/presentation/onboarding_screen.dart`: Onboarding slide walkthrough presentation connected to `OnboardingNotifier.completeOnboarding(userId)`.

### 3. Profile & Learning Features (`lib/features/profile/`, `lib/features/learning/`)
- `lib/features/profile/domain/educational_disclosures.dart`: Educational disclosures and simulation notice compliance constants.
- `lib/features/profile/presentation/profile_screen.dart`: User profile, discipline tier badge, settings, disclosures, account deletion flow, and sign-out integration.
- `lib/features/learning/domain/learning_event.dart`: Domain model for application events (`onboardingCompleted`, `loginCompleted`, `viewedMarket`, `firstTradeCompleted`, `completedLesson`, `newsDetectiveCompleted`).
- `lib/features/learning/domain/mission.dart`: Domain entity for V1 educational missions.
- `lib/features/learning/domain/mission_progress.dart`: Value object tracking completion progress and earned XP.
- `lib/features/learning/domain/level.dart`: Level domain model and deterministic tier calculation (`Rookie`, `Explorer`, `Risk-Aware Trader`, `Disciplined Trader`).
- `lib/features/learning/domain/xp_state.dart`: Immutable state tracking total XP, processed event IDs, completed mission IDs, and reward logs.
- `lib/features/learning/domain/models/mission.dart`: Re-export for models path backward compatibility.
- `lib/features/learning/domain/models/xp_level.dart`: Legacy alias re-export for models path backward compatibility.
- `lib/features/learning/application/xp_engine.dart`: Pure engine for evaluating XP rewards with strict duplicate prevention and educational reward bounds.
- `lib/features/learning/application/level_engine.dart`: Pure engine for deterministic level evaluation and tier progress calculation.
- `lib/features/learning/application/mission_engine.dart`: Pure engine for event-driven mission processing and claim execution.
- `lib/features/learning/application/learning_progression_notifier.dart`: Riverpod `StateNotifier` for managing progression state, event dispatching, reset, and state restoration.
- `lib/features/learning/presentation/missions_screen.dart`: Educational missions presentation widget reactive to `learningProgressionNotifierProvider`.
- `lib/features/learning/presentation/news_detective_screen.dart`: News Detective quiz feature.

### 4. Unit & Widget Tests (`test/`)
- `test/unit/auth_state_test.dart`: Unit tests for `AuthState` immutability and getters.
- `test/unit/auth_notifier_test.dart`: Unit tests for session restoration, login, registration, duplicate checks, logout, and account deletion.
- `test/unit/auth_repository_test.dart`: Unit tests for `MockAuthRepository` business validation.
- `test/unit/user_lifecycle_notifier_test.dart`: Unit tests for idempotent user lifecycle initialization and reset.
- `test/unit/onboarding_flow_test.dart`: Unit tests for `OnboardingNotifier` completion persistence, session restoration, logout reset, and multi-user isolation.
- `test/unit/profile_lifecycle_test.dart`: Unit tests for profile data extraction, educational disclosures, logout session cleanup, and account deletion.
- `test/unit/learning_progression_test.dart`: Unit tests for XP calculation, Level engine thresholds, Mission engine processing, duplicate prevention, event idempotency, and state restoration.
- `test/widget/auth_screens_test.dart`: Widget tests for `LoginScreen` and `RegisterScreen` form validation and UI feedback.
- `test/widget/profile_screen_test.dart`: Widget tests for `ProfileScreen` user info, disclosures modal dialog, and account deletion 2-step confirmation flow.
