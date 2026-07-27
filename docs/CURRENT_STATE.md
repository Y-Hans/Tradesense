# Current Project State

Managed by: `Yajat` (Integration Lead)

Integration Tag:
`integration-v1-001-scaffold`

Git Commit:
`initial-scaffold-commit`

Last Synchronized:
`2026-07-27`

---

## Build Health

- **Dependencies**: PASS (`pubspec.yaml` configured, `pubspec.lock` present)
- **Formatting**: NOT RUN
- **Flutter Analyze**: NOT RUN
- **Flutter Tests**: NOT RUN
- **Android Build**: NOT RUN
- **Physical Device**: NOT TESTED

---

## Working

- **Domain Models & Contracts**: Complete abstract model definitions for `Trade`, `Holding`, `Portfolio`, `VirtualWallet`, `RiskScore`, `DisciplineScore`, `CoachRequest`, `SubscriptionStatus`, `MarketTicker`, and core repository interfaces in `lib/shared/models/` and `lib/core/contracts/`.
- **Pure Utility Functions**:
  - `FinancialMath` (`lib/core/utils/financial_math.dart`): Fixed-precision INR paise calculations, average entry price, and P&L math.
  - `RiskCalculator` (`lib/core/utils/risk_calculator.dart`): Deterministic 0-100 Portfolio Risk Score math.
  - `DisciplineCalculator` (`lib/core/utils/discipline_calculator.dart`): Deterministic 0-100 Discipline Score math.

---

## Scaffolded / Partially Working

- **UI Presentation Screens (SCAFFOLDED / MOCKED)**:
  - `HomeScreen`, `MarketsScreen`, `AssetDetailScreen`, `TradeScreen`, `PortfolioScreen`, `TradeHistoryScreen`, `DisciplineMeterScreen`, `RiskMeterScreen`, `CoachResultScreen`, `PaywallScreen`, `LoginScreen`, `RegisterScreen`, `OnboardingScreen`, `ProfileScreen`, `MissionsScreen`.
  - All screens consume mock Riverpod state providers (`lib/core/providers/mocks/mock_repositories.dart`, `mock_market_repository.dart`).
- **Database Foundation (SCAFFOLDED)**:
  - Initial PostgreSQL schema (`supabase/migrations/20260726000000_initial_schema.sql`) with tables, RLS policies, and triggers.
- **AI Coach Function (SCAFFOLDED)**:
  - Supabase Deno Edge Function (`supabase/functions/ai-coach/index.ts`) for server-side OpenRouter API key isolation.
- **Platform Infrastructure (SCAFFOLDED)**:
  - Basic Android Gradle structure (`android/`) and GitHub Actions workflow (`.github/workflows/ci.yml`).

---

## Not Implemented

- Production Supabase auth signup/signin & session persistence with `flutter_secure_storage`.
- Real-time Binance WebSocket ticker stream & CoinGecko REST fallback client.
- Production Supabase trading repository (`SupabaseTradingRepository`) executing market orders via database transactions.
- Live RevenueCat SDK (`purchases_flutter`) initialization & Google Play Billing product configuration.
- Real OpenRouter API key deployment in Supabase Secrets Manager.
- Account deletion complete database purge cascade implementation.
- Educational learning missions, XP accumulation, and leveling progression logic.

---

## Known Issues

- None reported for the initial architectural baseline.

---

## Active Integration Requests

- **Active Requests Count**: 0
- See [`docs/integration-requests/open/`](file:///c:/Users/user/shpathon/docs/integration-requests/open/) for details.

---

## Current Development Baseline

- Five parallel feature branches are prepared for launch:
  - `feature/ui-presentation` (Somya)
  - `feature/trading-portfolio` (Laksh)
  - `feature/risk-discipline-coach` (Yajat)
  - `feature/auth-onboarding-learning` (Neel)
  - `feature/platform-market-supabase` (Divyanshu)
