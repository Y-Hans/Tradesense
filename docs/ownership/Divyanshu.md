# Divyanshu — File Ownership

Role:
Platform, Market Data, Supabase, RevenueCat, Firebase & Android Lead

## Ownership Rules

This developer may modify files explicitly assigned here.

New files created inside clearly owned feature areas should be added to this document.

If a required change belongs to another developer, do not modify that developer's files. Use the cross-developer request process.

## Owned Files

### Platform, Network & Provider Implementations
- `lib/core/networking/` — Dio HTTP client setup, interceptors, error handling
- `lib/core/providers/app_providers.dart` — Central dependency injection and platform providers
- `lib/core/providers/mocks/mock_market_repository.dart` — Mock market repository provider
- `lib/core/providers/mocks/mock_repositories.dart` — Mock infrastructure repositories

### Backend Infrastructure & Supabase
- `supabase/functions/ai-coach/index.ts` — Deno/TypeScript Edge Function for OpenRouter proxying
- `supabase/migrations/20260726000000_initial_schema.sql` — PostgreSQL schema, RLS policies, indexes
- `supabase/*` — Database migration scripts and server functions

### Platform, Build & CI Setup
- `.github/workflows/ci.yml` — GitHub Actions build and test workflow
- `android/` — Android Gradle build files (`build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `AndroidManifest.xml`)

## Owned Areas

- `lib/core/networking/` — Network clients and raw API integrations
- `lib/core/providers/` — Concrete infrastructure provider implementations
- `lib/features/market/data/` — Binance WebSocket stream client, REST ticker polling, CoinGecko fallback client
- `lib/features/subscription/data/` — RevenueCat SDK wrapper (`purchases_flutter`), paywall entitlements, Google Play Billing integration
- `supabase/` — Supabase database migrations, Row Level Security (RLS) policies, Edge Functions
- `android/` — Android native code, Gradle build system, release signing, AAB package configuration
- `.github/` — Continuous Integration (CI) and build automation pipelines

## Tests Owned

- `test/unit/networking/*` — Network client and interceptor unit tests
- `test/unit/market/*` — Market data provider and fallback unit tests
- `test/unit/subscription/*` — RevenueCat subscription provider unit tests
- `integration_test/app_test.dart` — End-to-end platform integration tests

## Notes / Boundaries

### Explicit Exclusions (Must NOT Own or Directly Modify):
- Presentation UI screens and design system widgets (owned by Somya)
- Authoritative trading engine math, order matching, position P&L (owned by Laksh)
- Risk Score, Discipline Score, AI prompt engineering logic (owned by Yajat)
- Auth domain logic, onboarding flow, learning missions/XP (owned by Neel)
- Must NOT absorb feature business logic into infrastructure services.
