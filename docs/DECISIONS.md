# Architecture & Project Decisions Record (ADR)

Managed by: `Yajat` (Integration Lead)

This document records binding architectural and product decisions. Future AI coding agents and human developers must adhere to these decisions and **NOT** repeatedly reconsider or attempt to refactor them.

---

## 1. Mobile Technology Stack
- **Decision**: The mobile application is built exclusively using **Flutter & Dart**.
- **Target Platform**: Android / Google Play Store (`.aab` package release).
- **Rationale**: Single codebase cross-platform framework delivering 60fps responsive UI with native performance.

## 2. State Management & Routing Architecture
- **Decision**: **Riverpod** (`flutter_riverpod`) is the mandatory state-management framework. **GoRouter** (`go_router`) is the mandatory application router.
- **Rationale**: Feature-First Clean Architecture requires compile-time safe dependency injection, reactive state binding, and declarative URL-safe route management.

## 3. Product Rules & Simulation Boundaries
- **Decision**: All trading is **100% SIMULATED**. Every user starts with **₹100,000 VIRTUAL CASH**.
- **Strict Exclusions**:
  - NO real-money trading
  - NO cryptocurrency purchase
  - NO cash deposits or withdrawals
  - NO crypto wallet connection (e.g. MetaMask, WalletConnect)
  - NO exchange account API connection (e.g. Binance API keys)

## 4. V1 Asset Selection
- **Decision**: V1 supported trading assets are strictly limited to 5 cryptocurrencies:
  - **BTC** (Bitcoin)
  - **ETH** (Ethereum)
  - **SOL** (Solana)
  - **XRP** (Ripple)
  - **BNB** (Binance Coin)

## 5. Market Data Strategy
- **Decision**: **Binance public REST/WebSocket API** is the primary live market price source. **CoinGecko REST API** is the mandatory fallback source.
- **Rationale**: Public Binance WebSocket streams provide zero-latency price updates without requiring user authentication keys.

## 6. Backend & Database Foundation
- **Decision**: **Supabase** (PostgreSQL database, Supabase Auth, Row Level Security, Edge Functions) is the core backend provider.
- **Rationale**: Open-source PostgreSQL with built-in RLS policies and TypeScript Edge Functions provides secure user data persistence and server-side execution.

## 7. Subscription Infrastructure
- **Decision**: **RevenueCat** (`purchases_flutter`) is mandatory for subscription management and Google Play Billing product entitlement synchronization.
- **Rationale**: Decouples client presentation from raw platform billing APIs while managing cross-platform entitlement state.

## 8. AI Provider Architecture & Long-Term Roadmap
- **Decision**: AI access is strictly vendor-decoupled via an abstract `AIProvider` contract.
  - **V1 Backend Solution**: Supabase Edge Function (`ai-coach`) proxying to **OpenRouter API**. Server-side API key isolation.
  - **Long-Term Roadmap**: Transition from third-party OpenRouter models to **OUR OWN TRAINED MODEL** (`CustomModelProvider`).
  - **Calculation Non-Authoritative Rule**: AI models are **EXPLANATION-ONLY**. AI is **NEVER** authoritative for financial math, P&L, Risk Scores, or Discipline Scores.

## 9. Discipline & Risk Philosophy
- **Decision**:
  - **Discipline Score (0-100)**: Evaluates trade execution quality (stop-loss usage, position sizing, over-trading penalties). **STRICTLY INDEPENDENT OF P&L PROFIT/LOSS**.
  - **Risk Score (0-100)**: Evaluates portfolio concentration and asset volatility risk.

## 10. Shared Contract Governance
- **Decision**: All core contracts (`lib/core/contracts/`) and shared models (`lib/shared/models/`) are frozen and managed centrally by `Yajat` (Integration Lead). Individual developers cannot modify shared contracts on isolated feature branches without an approved integration request.
