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
- `lib/features/profile/presentation/profile_screen.dart`: User profile, discipline tier badge, settings, and sign-out integration.
- `lib/features/learning/presentation/missions_screen.dart`: Educational missions and rewards.
- `lib/features/learning/presentation/news_detective_screen.dart`: News Detective quiz feature.

### 4. Unit & Widget Tests (`test/`)
- `test/unit/auth_state_test.dart`: Unit tests for `AuthState` immutability and getters.
- `test/unit/auth_notifier_test.dart`: Unit tests for session restoration, login, registration, duplicate checks, and logout.
- `test/unit/auth_repository_test.dart`: Unit tests for `MockAuthRepository` business validation.
- `test/unit/user_lifecycle_notifier_test.dart`: Unit tests for idempotent user lifecycle initialization and reset.
- `test/unit/onboarding_flow_test.dart`: Unit tests for `OnboardingNotifier` completion persistence, session restoration, logout reset, and multi-user isolation.
- `test/widget/auth_screens_test.dart`: Widget tests for `LoginScreen` and `RegisterScreen` form validation and UI feedback.
