# TEAM OWNERSHIP & TEMPORARY INTEGRATION CHANGES

## 1. Developer Domain Allocation

| Developer | Assigned Areas & Features | Code Directory Boundaries |
| :--- | :--- | :--- |
| **Somya** | UI, UX, Widgets, Screens, Theme, Navigation, Presentation Layer | `lib/app/theme/`, `lib/features/**/presentation/` |
| **Laksh** | Trading Simulator, Portfolio Engine, Holdings, Wallet, Orders, Buy/Sell | `lib/features/trading/`, `lib/features/portfolio/` |
| **Yajat** | Risk Score, Discipline Score, AI Coach, Shared Contracts, Core Architecture | `lib/features/intelligence/`, `lib/features/coach/`, `lib/core/contracts/` |
| **Neel** | Auth, User Lifecycle, Onboarding, Learning, Missions, XP, Levels, News Quiz | `lib/features/auth/`, `lib/features/onboarding/`, `lib/features/profile/`, `lib/features/learning/` |
| **Divyanshu** | Supabase, Firebase, RevenueCat, Market APIs, Android Platform, Infrastructure | `lib/core/networking/`, `supabase/`, `android/`, `.github/` |

---

## 2. Temporary Integration Changes Notice

During the local merge of Neel's prototype into the generated project architecture, the following files received necessary integration modifications:

1. **`lib/app/routing/app_router.dart`**:
   - **Reason**: Registered `/news-detective` route and bound navigation endpoints for `/profile`, `/missions`, and `/onboarding`.
   - **Owner**: **Yajat** (Routing) & **Somya** (UI Navigation).
2. **`android/app/build.gradle.kts`**:
   - **Reason**: Updated `ndkVersion = "28.2.13676358"`, enforced `JVM_17` Kotlin compilation, and resolved Espresso test dependency collisions.
   - **Owner**: **Divyanshu** (Android Platform & Build System).

> **Note**: These changes were performed strictly to enable full local application execution. Future ownership of these files remains with their designated owners.
