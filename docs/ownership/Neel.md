# Neel — File Ownership

Role:
Authentication, Onboarding & Learning Lead

## Ownership Rules

This developer may modify files explicitly assigned here.

New files created inside clearly owned feature areas should be added to this document.

If a required change belongs to another developer, do not modify that developer's files. Use the cross-developer request process.

## Owned Files

### Feature Domain & Data Implementations
- `lib/features/auth/domain/` & `data/` — User authentication domain logic, AuthRepository client interfaces, secure token storage
- `lib/features/onboarding/domain/` & `data/` — User onboarding progression, initial profile setup state
- `lib/features/profile/domain/` & `data/` — Profile lifecycle management, account deletion domain orchestration
- `lib/features/learning/domain/` & `data/` — Beginner missions, XP rewards, leveling progression, educational content logic

## Owned Areas

- `lib/features/auth/` (domain & data layers)
- `lib/features/onboarding/` (domain & data layers)
- `lib/features/profile/` (domain & data layers)
- `lib/features/learning/` (domain & data layers)
- Future stretch modules: Missions, XP, Levels, News Detective / Real-or-Fake News Quiz domain logic

## Tests Owned

- `test/unit/auth/*` — User authentication and session unit tests
- `test/unit/onboarding/*` — Onboarding flow state unit tests
- `test/unit/profile/*` — User profile lifecycle and account deletion unit tests
- `test/unit/learning/*` — Educational missions and XP leveling unit tests

## Notes / Boundaries

### Explicit Exclusions (Must NOT Own or Directly Modify):
- Presentation UI screens, widgets, and themes (owned by Somya)
- Virtual wallet calculations, trading engine, portfolio P&L (owned by Laksh)
- Risk Score, Discipline Score, AI Coach logic (owned by Yajat)
- Supabase SQL schema migrations, Deno Edge Functions, Binance market streams, RevenueCat SDK, Android Gradle (owned by Divyanshu)
