# Shared & Controlled File Ownership

Managed by:
`Yajat` — Integration Lead

## Purpose & Governance Rules

This file documents core shared contracts, domain models, routing configuration, dependency configurations, and application bootstrap files that should **NOT** be casually changed by individual feature developers.

**Shared contracts must not be casually modified by a feature developer merely to make a local task easier.**

If a developer needs to extend or alter a shared model or contract:
1. Do NOT modify the shared file on your branch independently.
2. Submit an integration request via the cross-developer request process.
3. Coordinate the contract revision through `Yajat` (Integration Lead).
4. Ensure all active feature branches are accounted for before finalizing contract changes.

---

## Controlled Shared Files

### 1. Application Bootstrap & Routing
- `lib/main.dart` — Main application entry point
- `lib/app/app.dart` — Root MaterialApp / Riverpod scope setup
- `lib/app/routing/app_router.dart` — GoRouter navigation configuration and route definitions

### 2. Core Domain Contracts (`lib/core/contracts/`)
- `lib/core/contracts/market_provider.dart` — Abstract market ticker provider interface
- `lib/core/contracts/provider_contracts.dart` — Abstract AIProvider, SubscriptionProvider, AnalyticsProvider, RemoteConfigProvider contracts
- `lib/core/contracts/repository_contracts.dart` — Abstract AuthRepository, TradingRepository, PortfolioRepository, IntelligenceRepository contracts

### 3. Core Shared Domain Models (`lib/shared/models/`)
- `lib/shared/models/user_profile.dart` — User profile data model
- `lib/shared/models/virtual_wallet.dart` — Virtual wallet & cash balance model
- `lib/shared/models/crypto_asset.dart` — Cryptocurrency asset definition
- `lib/shared/models/market_ticker.dart` — Real-time price ticker & candle model
- `lib/shared/models/holding.dart` — Asset holding & position model
- `lib/shared/models/trade.dart` — Simulated trade execution & order model
- `lib/shared/models/stop_loss_order.dart` — Stop-loss order definition model
- `lib/shared/models/portfolio.dart` — Portfolio valuation & snapshot model
- `lib/shared/models/risk_score.dart` — Portfolio Risk Score model (0-100)
- `lib/shared/models/discipline_score.dart` — Trading Discipline Score model (0-100)
- `lib/shared/models/coach_request.dart` — AI Coach request/response & analysis model
- `lib/shared/models/subscription_status.dart` — Subscription entitlement model
- `lib/shared/models/feature_flags.dart` — Remote configuration feature flags model

### 4. Dependency & Project Configuration
- `pubspec.yaml` — Package dependencies and environment constraints
- `pubspec.lock` — Dependency lockfile
- `analysis_options.yaml` — Linter rules and compiler options
