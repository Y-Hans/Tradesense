# Dev Guide — Account, Learning & User Lifecycle (Neel)

Primary Owner: **Neel**

- Authoritative Ownership Document: [`docs/ownership/Neel.md`](file:///c:/Users/user/shpathon/docs/ownership/Neel.md)
- Development Log: [`docs/development-log/Neel.md`](file:///c:/Users/user/shpathon/docs/development-log/Neel.md)

## Scope & Owned Directories
- `lib/features/auth/`
- `lib/features/onboarding/`
- `lib/features/profile/`
- `lib/features/learning/`

## Immediate Tasks
1. Connect `SupabaseAuthRepository` for production user signup, signin, session persistence (`flutter_secure_storage`), and account deletion.
2. Build account deletion domain flow purging user records from `profiles`, `virtual_wallets`, `holdings`, `trades`, and `ai_interactions`.
3. Expand beginner trading missions, XP rewards, and leveling system.
