# DEVELOPMENT LOG — NEEL

**Developer**: Neel (Auth, User Lifecycle, Onboarding, Learning, Missions & Profile)  
**Date**: 2026-07-29  
**Feature Module**: Onboarding Business Flow & User Lifecycle Coordination  

---

## 1. Startup Decision Tree & Architecture

```text
App Launch
    ↓
Restore Session (AuthNotifier)
    ↓
Initialize User Lifecycle (UserLifecycleNotifier - Idempotent)
    ↓
Check Onboarding (OnboardingNotifier - Scoped per user ID)
    ↓
Navigate (GoRouter Redirect)
```

---

## 2. Functionality Implemented

- **Shared Contract Integrity Preserved**:
  - `UserProfile` (`lib/shared/models/user_profile.dart`) preserved untouched without modifying shared domain models.
  - `AuthNotifier` (`lib/features/auth/application/auth_notifier.dart`) kept exclusively focused on authentication operations without mixing onboarding logic.

- **Onboarding State & Business Logic**:
  - Created `OnboardingNotifier` (`lib/features/onboarding/application/onboarding_notifier.dart`) managing onboarding completion per user ID.
  - Reused Somya's `OnboardingScreen` presentation UI exactly as delivered, connecting `_finishOnboarding()` to `OnboardingNotifier.completeOnboarding(userId)`.

- **Idempotent User Lifecycle Coordination**:
  - Implemented `UserLifecycleNotifier` (`lib/features/auth/application/user_lifecycle_notifier.dart`) tracking user lifecycle initialization per user ID.
  - Preserved `TODO(Laksh)` for future financial initialization without creating premature placeholder requests.

- **Side-Effect-Free Startup Routing Guard**:
  - Configured GoRouter redirect guard in `lib/app/routing/app_router.dart` and `routerProvider` driven by `AuthState` and `OnboardingNotifier`.
  - Holds redirection while `authState.isRestoring` to eliminate login/onboarding screen flicker.
  - Redirects unauthenticated users to `/login`, first-time users to `/onboarding`, and returning users to `/home`.

---

## 3. Files Created & Modified

### Created Files
- `lib/features/onboarding/application/onboarding_notifier.dart`
- `lib/features/auth/application/user_lifecycle_notifier.dart`
- `test/unit/user_lifecycle_notifier_test.dart`
- `test/unit/onboarding_flow_test.dart`

### Modified Files
- `lib/features/auth/application/auth_notifier.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/core/providers/app_providers.dart`
- `lib/app/routing/app_router.dart`
- `lib/app/app.dart`
- `docs/ownership/Neel.md`
- `docs/development-log/Neel.md`

---

## 4. Tests Added & Validation Results

Added unit test suites covering:
1. **Session restored + onboarding complete**: Profile with completed onboarding status completes session restoration and routes to `/home`.
2. **Session restored + onboarding incomplete**: Profile with incomplete onboarding status routes to `/onboarding`.
3. **Onboarding completion persistence**: Calling `completeOnboarding(userId)` updates onboarding state per user ID.
4. **Logout state reset**: Signing out resets auth state and clears active session context.
5. **Multi-user isolation**: Multiple accounts maintain independent onboarding completion states.
6. **Idempotent lifecycle initialization**: `UserLifecycleNotifier.initializeUser()` executes exactly once per user ID and skips redundant calls.

---

## 5. Integration Impact & Boundary Preservation

- **Yajat (Contracts & Core Architecture)**: Preserved shared `AuthRepository` interface in `lib/core/contracts/repository_contracts.dart` and `UserProfile` shared model without modifications.
- **Somya (UI / Presentation)**: Preserved `OnboardingScreen` presentation design, slide structure, dots, disclaimers, and animations without redesigning presentation code.
- **Laksh (Trading Engine & Portfolio)**: Zero wallet creation, ₹100,000 balance assignment, or portfolio mutations. `TODO(Laksh)` marker preserved inside `UserLifecycleNotifier`.
- **Divyanshu (Infrastructure & Backend)**: Backend Supabase integration deferred to Divyanshu's platform initialization contract.

---

## 6. Onboarding Persistence Architecture & Backend Dependencies

- **Mock-Mode Behavior**:
  - `OnboardingNotifier` maintains application state in memory per active user session (`Map<String, bool>`).
  - Default mock user `usr_mock_123` defaults to `true` (enabling instant dashboard testing in mock mode).
  - New user registrations default to `false` (routing first-time users through onboarding once).

- **Production Behavior**:
  - The application layer (`OnboardingNotifier`) is integration-ready to read backend user metadata returned by `AuthRepository.getCurrentUser()`.

- **Outstanding Backend Dependency (Divyanshu)**:
  - Cross-app-restart persistence in production depends on Divyanshu including `is_onboarding_completed` in Supabase user metadata / PostgreSQL profile table migrations.
  - To prevent technical debt, **no temporary device-local storage** (`SharedPreferences` or `FlutterSecureStorage`) or parallel persistence mechanisms were added.

- **Graceful Degradation**:
  - Unrecorded user IDs default safely to `isCompleted(userId) == false` without throwing exceptions or pretending local disk persistence exists.
  - Virtual wallet creation and starting balance seeding will be hooked into `UserLifecycleNotifier` when Laksh provides the financial contract.
