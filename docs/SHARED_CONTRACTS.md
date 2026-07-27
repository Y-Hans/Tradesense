# Shared Contracts & Domain Models Reference

Managed by: `Yajat` (Integration Lead)

All five developers share access to these frozen domain interfaces and models.

> **CRITICAL RULE**:
> **Shared contracts must not be casually modified by a feature developer merely to make a local task easier.**
> Changes should be coordinated through the Integration Lead (`Yajat`) because several parallel branches depend on them.

---

## 1. Domain Models (`lib/shared/models/`)

### `UserProfile` (`lib/shared/models/user_profile.dart`)
- **Purpose**: Represents logged-in user profile, subscription status, and experience metrics.
- **Producer / Primary Owner**: Neel (Auth & Profile)
- **Consumers**: Somya (UI Header/Settings), Yajat (AI Coach Context)
- **Integration Coordination Required**: YES

### `VirtualWallet` (`lib/shared/models/virtual_wallet.dart`)
- **Purpose**: Represents user's virtual cash balance (starting at ₹100,000 INR) and currency metadata.
- **Producer / Primary Owner**: Laksh (Trading Engine)
- **Consumers**: Somya (UI Wallet Cards), Yajat (Risk Calculator)
- **Integration Coordination Required**: YES

### `CryptoAsset` (`lib/shared/models/crypto_asset.dart`)
- **Purpose**: Represents supported cryptocurrency asset metadata (BTC, ETH, SOL, XRP, BNB).
- **Producer / Primary Owner**: Divyanshu (Market Infrastructure)
- **Consumers**: Somya (Market UI), Laksh (Trading Engine)
- **Integration Coordination Required**: YES

### `MarketTicker` & `MarketCandle` (`lib/shared/models/market_ticker.dart`)
- **Purpose**: Real-time market price ticker, 24h volume, price change percentage, and candle chart data.
- **Producer / Primary Owner**: Divyanshu (Market Data Provider)
- **Consumers**: Somya (Price UI & Charts), Laksh (Stop-Loss Trigger Loop & Position Valuation)
- **Integration Coordination Required**: YES

### `Holding` (`lib/shared/models/holding.dart`)
- **Purpose**: Represents active asset holdings, total quantity, and weighted average entry price.
- **Producer / Primary Owner**: Laksh (Portfolio Engine)
- **Consumers**: Somya (Portfolio UI), Yajat (Risk Calculator)
- **Integration Coordination Required**: YES

### `Trade`, `TradeSide`, `OrderType` (`lib/shared/models/trade.dart`)
- **Purpose**: Represents completed virtual trades (BUY/SELL market orders) with execution timestamp and price.
- **Producer / Primary Owner**: Laksh (Trading Engine)
- **Consumers**: Somya (Trade History UI), Yajat (Discipline Score & AI Coach Context)
- **Integration Coordination Required**: YES

### `StopLossOrder` (`lib/shared/models/stop_loss_order.dart`)
- **Purpose**: Defines automated simple stop-loss orders linked to active asset holdings.
- **Producer / Primary Owner**: Laksh (Trading Engine)
- **Consumers**: Somya (Trade UI), Yajat (Discipline Calculator penalization check)
- **Integration Coordination Required**: YES

### `Portfolio` & `PortfolioSnapshot` (`lib/shared/models/portfolio.dart`)
- **Purpose**: Aggregates wallet cash, asset holdings, total valuation, realized P&L, and unrealized P&L.
- **Producer / Primary Owner**: Laksh (Portfolio Engine)
- **Consumers**: Somya (Home & Portfolio Screens), Yajat (Risk Calculator)
- **Integration Coordination Required**: YES

### `RiskScore` (`lib/shared/models/risk_score.dart`)
- **Purpose**: Represents 0-100 Portfolio Risk Score, risk category, and key risk breakdown metrics.
- **Producer / Primary Owner**: Yajat (Risk Engine)
- **Consumers**: Somya (Risk Gauge UI), Yajat (AI Coach Context)
- **Integration Coordination Required**: YES

### `DisciplineScore` (`lib/shared/models/discipline_score.dart`)
- **Purpose**: Represents 0-100 Trading Discipline Score, discipline tier, and penalty explanations.
- **Producer / Primary Owner**: Yajat (Discipline Engine)
- **Consumers**: Somya (Discipline Gauge UI), Yajat (AI Coach Context)
- **Integration Coordination Required**: YES

### `CoachRequest`, `CoachResponse`, `TradeAnalysis` (`lib/shared/models/coach_request.dart`)
- **Purpose**: Payload schemas for requesting AI Coach trade feedback and structured response cards.
- **Producer / Primary Owner**: Yajat (AI Coach Lead)
- **Consumers**: Somya (Coach Result UI), Divyanshu (Supabase Edge Function wrapper)
- **Integration Coordination Required**: YES

### `SubscriptionStatus` & `FeatureFlags` (`lib/shared/models/subscription_status.dart`, `feature_flags.dart`)
- **Purpose**: Represents user entitlement status (Free vs Premium Pro) and Remote Config feature toggles.
- **Producer / Primary Owner**: Divyanshu (RevenueCat & Remote Config Provider)
- **Consumers**: Somya (Paywall UI & Pro Badges), Yajat (AI Coach access gate)
- **Integration Coordination Required**: YES

---

## 2. Abstract Provider & Repository Interfaces (`lib/core/contracts/`)

- `MarketProvider` (`lib/core/contracts/market_provider.dart`) — Abstract ticker price stream provider. Owned by Divyanshu.
- `AIProvider`, `SubscriptionProvider`, `AnalyticsProvider`, `RemoteConfigProvider` (`lib/core/contracts/provider_contracts.dart`) — Core platform service abstractions. Managed by Divyanshu & Yajat.
- `AuthRepository`, `TradingRepository`, `PortfolioRepository`, `IntelligenceRepository` (`lib/core/contracts/repository_contracts.dart`) — Abstract feature repository interfaces. Managed jointly across domain owners.
