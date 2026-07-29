# ARCHITECTURAL & INTEGRATION DECISIONS (ADR)

**Repository**: CryptoEdu Simulator  
**Scope**: Prototype Integration & Architecture Synchronization  

---

## ADR 001: Preservation of Feature-First Clean Architecture

- **Context**: Neel's prototype code needed to be merged into the newly generated project architecture.
- **Decision**: All features (Auth, Profile, Onboarding, Learning, Missions, News Detective) are organized strictly under `lib/features/<feature_name>/` using subfolders (`domain/`, `infrastructure/`, `application/`, `presentation/`).
- **Consequences**: Architecture boundaries remain 100% clean and match team specifications.

---

## ADR 002: Idempotent Wallet & Profile Initialization

- **Context**: Re-logging or re-opening the application must not generate multiple starting balances of ₹100,000.
- **Decision**: `AccountInitializationService` inspects existing profile and wallet initialization flags before seeding. If initialized, balance re-seeding is skipped.
- **Consequences**: Prevents virtual currency inflation and guarantees deterministic user balance states.

---

## ADR 003: Temporary Integration Modifications

- **Context**: Merging Neel's prototype required modifying central routing and platform build specs.
- **Decision**:
  1. `lib/app/routing/app_router.dart`: Added `/news-detective` and updated profile route bindings.
  2. `android/app/build.gradle.kts`: Configured `ndkVersion = "28.2.13676358"`, aligned `JVM_17` Kotlin compilation, and resolved Espresso test dependency collisions.
- **Consequences**: Future ownership of these shared/platform files remains strictly with **Yajat/Somya** (`app_router.dart`) and **Divyanshu** (`build.gradle.kts`).

---

## ADR 004: Duplicate Reward Prevention in Missions

- **Context**: Users could exploit mission claims to gain unlimited XP.
- **Decision**: `MemoryMissionRepository` tracks completed mission IDs per user and returns `false` on duplicate claim attempts, preventing secondary XP allocation.
- **Consequences**: Ensures XP levels accurately reflect unique learning achievements.
