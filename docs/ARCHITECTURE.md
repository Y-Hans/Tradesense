# ARCHITECTURE DOCUMENTATION

## 1. Feature-First Clean Architecture

The application is structured using **Feature-First Clean Architecture**:

```
lib/
├── app/                  # Application Shell & Navigation Setup
│   ├── app.dart
│   ├── routing/app_router.dart
│   └── theme/app_theme.dart
├── core/                 # Shared Utilities & Base Contracts
│   ├── constants/disclaimers.dart
│   ├── contracts/
│   ├── providers/
│   └── widgets/disclaimer_card.dart
├── features/             # Business Features
│   ├── auth/             # Authentication & User Lifecycle (Neel)
│   ├── coach/            # AI Coach (Yajat)
│   ├── home/             # Home Dashboard (Somya)
│   ├── intelligence/     # Risk & Discipline Score Engine (Yajat)
│   ├── learning/         # Missions & News Detective (Neel)
│   ├── market/           # Supported Assets & Prices (Divyanshu)
│   ├── onboarding/       # Educational Onboarding (Neel)
│   ├── portfolio/        # Portfolio & Holdings (Laksh)
│   ├── profile/          # User Profile & Settings (Neel)
│   ├── subscription/     # Paywall & Premium Status (Divyanshu)
│   └── trading/          # Order Execution Engine (Laksh)
└── shared/               # Immutable Shared Entities & Models
```

---

## 2. Layer Responsibilities

1. **Domain Layer (`domain/`)**: Pure Dart entities (`Mission`, `XpLevel`, `NewsQuestion`, `UserProfile`). No UI or Flutter dependencies.
2. **Infrastructure Layer (`infrastructure/`)**: Repository implementations (`CuratedNewsDetectiveRepository`, `MemoryProfileRepository`).
3. **Application Layer (`application/`)**: StateNotifiers (`AuthNotifier`, `ProfileNotifier`, `MissionNotifier`, `NewsDetectiveNotifier`) and Coordination Services (`AccountInitializationService`).
4. **Presentation Layer (`presentation/`)**: Flutter UI widgets, screens (`ProfileScreen`, `MissionsScreen`, `NewsDetectiveScreen`, `OnboardingScreen`), and view logic.

---

## 3. Integration & Platform Notes

- **Routing Expansion**: `GoRouter` in `lib/app/routing/app_router.dart` registers routes `/onboarding`, `/login`, `/register`, `/home`, `/markets`, `/portfolio`, `/risk-meter`, `/discipline-meter`, `/profile`, `/missions`, `/news-detective`, `/paywall`.
- **Android Platform Alignment**: `android/app/build.gradle.kts` uses NDK `28.2.13676358`, Java 17 compatibility, and Espresso `3.5.1` test resolution to satisfy Android AGP 9.0 requirements.
